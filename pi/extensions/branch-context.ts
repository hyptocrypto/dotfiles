/**
 * Branch Context Extension
 *
 * Auto-generates compressed feature branch context and injects it into new chats.
 * Saves time and tokens on long-running branches.
 *
 * Features:
 * - Auto-detects current branch vs default branch (main/master/development/etc)
 * - Generates compressed summary using scout agent
 * - Caches results with diff-based invalidation
 * - Provides commands to view/refresh context
 *
 * Commands:
 * - /branch-context - Show current cached context
 * - /refresh-branch-context - Regenerate context summary
 * - /set-branch-purpose <purpose> - Override auto-detected purpose
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { createHash } from "node:crypto";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface BranchCache {
	branch: string;
	baseBranch: string;
	diffHash: string;
	context: string;
	customPurpose?: string;
	timestamp: number;
}

// Token budget for context - adjust based on branch size
// 16k additions = large branch, allocate 1500-2000 tokens
const CONTEXT_TOKEN_BUDGET = 2000;

const CACHE_DIR = path.join(os.homedir(), ".pi", "branch-context");

export default function (pi: ExtensionAPI) {
	// Ensure cache directory exists
	if (!fs.existsSync(CACHE_DIR)) {
		fs.mkdirSync(CACHE_DIR, { recursive: true });
	}

	/**
	 * Get current git branch
	 */
	async function getCurrentBranch(): Promise<string | null> {
		try {
			const { stdout } = await pi.exec("git", ["rev-parse", "--abbrev-ref", "HEAD"]);
			return stdout.trim() || null;
		} catch {
			return null;
		}
	}

	/**
	 * Detect the repository's default/base branch
	 * Tries multiple strategies:
	 * 1. origin/HEAD symbolic ref
	 * 2. Common names (main, master, development, develop)
	 * 3. Fallback to first remote branch
	 */
	async function getDefaultBranch(): Promise<string | null> {
		// Strategy 1: Check origin/HEAD
		try {
			const { stdout } = await pi.exec("git", [
				"symbolic-ref",
				"refs/remotes/origin/HEAD",
			]);
			const ref = stdout.trim();
			if (ref) {
				const branch = ref.replace(/^refs\/remotes\/origin\//, "");
				if (branch) return branch;
			}
		} catch {
			// origin/HEAD not set, try other methods
		}

		// Strategy 2: Try common default branch names
		const commonNames = ["main", "master", "development", "develop", "dev"];
		for (const name of commonNames) {
			try {
				await pi.exec("git", ["rev-parse", "--verify", name]);
				return name;
			} catch {
				// Branch doesn't exist, try next
			}
		}

		// Strategy 3: Get first remote branch from origin
		try {
			const { stdout } = await pi.exec("git", [
				"ls-remote",
				"--symref",
				"origin",
				"HEAD",
			]);
			const match = stdout.match(/ref: refs\/heads\/(\S+)/);
			if (match) return match[1];
		} catch {
			// No remote
		}

		// Fallback: just use 'main' and hope for the best
		return "main";
	}

	/**
	 * Compute hash of the diff for cache invalidation
	 */
	async function getDiffHash(
		branch: string,
		baseBranch: string,
	): Promise<string | null> {
		try {
			const { stdout } = await pi.exec("git", ["diff", `${baseBranch}...${branch}`]);
			return createHash("md5").update(stdout).digest("hex");
		} catch {
			return null;
		}
	}

	/**
	 * Load cached context for a branch
	 */
	function loadCache(branch: string): BranchCache | null {
		const cachePath = path.join(
			CACHE_DIR,
			`${branch.replace(/[^a-zA-Z0-9-_]/g, "_")}.json`,
		);
		if (!fs.existsSync(cachePath)) return null;

		try {
			const content = fs.readFileSync(cachePath, "utf8");
			return JSON.parse(content) as BranchCache;
		} catch {
			return null;
		}
	}

	/**
	 * Save context cache for a branch
	 */
	function saveCache(data: BranchCache): void {
		const cachePath = path.join(
			CACHE_DIR,
			`${data.branch.replace(/[^a-zA-Z0-9-_]/g, "_")}.json`,
		);
		fs.writeFileSync(cachePath, JSON.stringify(data, null, 2));
	}

	/**
	 * Generate compressed branch context using scout agent
	 */
	async function generateContext(
		branch: string,
		baseBranch: string,
		customPurpose?: string,
	): Promise<string> {
		// Get diff stats
		let diffStats = "";
		try {
			const { stdout } = await pi.exec("git", [
				"diff",
				"--stat",
				`${baseBranch}...${branch}`,
			]);
			diffStats = stdout;
		} catch {
			diffStats = "(unable to get diff stats)";
		}

		// Get recent commits
		let commitLog = "";
		try {
			const { stdout } = await pi.exec("git", [
				"log",
				"--oneline",
				`${baseBranch}..${branch}`,
				"--max-count=15",
			]);
			commitLog = stdout;
		} catch {
			commitLog = "(no commits)";
		}

		// Get list of changed files with brief context
		let changedFiles = "";
		try {
			const { stdout } = await pi.exec("git", [
				"diff",
				"--name-status",
				`${baseBranch}...${branch}`,
			]);
			changedFiles = stdout;
		} catch {
			changedFiles = "(unable to list changed files)";
		}

		// Build task for scout agent
		const task = `
Analyze this git branch and create a compressed context summary.

**Branch:** ${branch}
**Base:** ${baseBranch}
**Token budget:** ${CONTEXT_TOKEN_BUDGET} tokens max

**Changed Files:**
\`\`\`
${changedFiles.slice(0, 5000)}
\`\`\`

**Diff Stats:**
\`\`\`
${diffStats.slice(0, 3000)}
\`\`\`

**Recent Commits:**
\`\`\`
${commitLog}
\`\`\`

${customPurpose ? `**Custom Purpose Note:** ${customPurpose}\n` : ""}

Generate a markdown summary with these sections:

## Purpose
Brief 2-3 sentence description of what this branch does. ${customPurpose ? "Use the custom purpose note above." : "Infer from commits and changed files."}

## Key Changes
List 5-10 most significant changes/additions. Focus on:
- New features/modules
- Major refactors
- Breaking changes
- Important bug fixes

## Changed Files (Grouped)
Group files by area/purpose (e.g., "Auth System", "UI Components", "Tests").
For each group: brief description of what changed and why.
Don't list every file - group related changes.

## Technical Context
Any important technical details needed to understand the work:
- Dependencies added/changed
- Architecture shifts
- Migration steps
- Breaking API changes

Keep total output under ${CONTEXT_TOKEN_BUDGET} tokens. Be concise but informative.
Focus on what an engineer joining this work needs to know.
`.trim();

		try {
			// Use subagent tool to invoke scout
			const result = await pi.invokeTool("subagent", {
				agent: "scout",
				task,
			});

			if (result && typeof result === "object" && "output" in result) {
				return String(result.output);
			}

			return "(Failed to generate context - subagent returned unexpected result)";
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			return `(Failed to generate context: ${message})`;
		}
	}

	/**
	 * Get or generate branch context
	 */
	async function getBranchContext(
		branch: string,
		baseBranch: string,
		forceRefresh = false,
	): Promise<{ context: string; cached: boolean }> {
		const diffHash = await getDiffHash(branch, baseBranch);
		if (!diffHash) {
			return {
				context: "(Unable to compute diff - are you in a git repository?)",
				cached: false,
			};
		}

		const cache = loadCache(branch);

		// Check if cache is valid
		if (!forceRefresh && cache && cache.diffHash === diffHash) {
			return { context: cache.context, cached: true };
		}

		// Generate fresh context
		const context = await generateContext(
			branch,
			baseBranch,
			cache?.customPurpose,
		);

		// Save to cache
		saveCache({
			branch,
			baseBranch,
			diffHash,
			context,
			customPurpose: cache?.customPurpose,
			timestamp: Date.now(),
		});

		return { context, cached: false };
	}

	/**
	 * Hook: Inject context at chat start (opt-in only)
	 * Only injects if cache exists - user must run /refresh-branch-context first
	 */
	pi.on("chat_start", async (_event, ctx) => {
		const branch = await getCurrentBranch();
		if (!branch) return; // Not in a git repo

		const baseBranch = await getDefaultBranch();
		if (!baseBranch || branch === baseBranch) {
			return; // On default branch, no context needed
		}

		// OPT-IN: Only inject if cache exists
		// User must explicitly run /refresh-branch-context to enable
		const cache = loadCache(branch);
		if (!cache) {
			// No cache - don't auto-generate, just skip
			return;
		}

		try {
			// Check if cache is still valid
			const diffHash = await getDiffHash(branch, baseBranch);
			if (diffHash && cache.diffHash !== diffHash) {
				// Cache invalid - notify but don't auto-regenerate
				if (ctx.hasUI) {
					ctx.ui.notify(
						`Branch context outdated for ${branch}. Run /refresh-branch-context to update.`,
						"warning",
					);
				}
				return;
			}

			// Cache valid - inject it
			if (ctx.hasUI) {
				ctx.ui.notify(
					`Branch context loaded for ${branch} (vs ${baseBranch})`,
					"info",
				);
			}

			// Inject into system prompt
			const branchContext = `
# Feature Branch Context

You are working on branch: **${branch}** (vs **${baseBranch}**)

${cache.context}

---

Use \`/refresh-branch-context\` if branch changes significantly.
Use \`/set-branch-purpose "<purpose>"\` to override inferred purpose.
`.trim();

			// Add to system messages
			ctx.addSystemMessage(branchContext);
		} catch (error) {
			if (ctx.hasUI) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Failed to load branch context: ${message}`, "warning");
			}
		}
	});

	/**
	 * Command: View current branch context
	 */
	pi.registerCommand("branch-context", {
		description: "Show current branch context",
		handler: async (_args, ctx) => {
			const branch = await getCurrentBranch();
			if (!branch) {
				ctx.ui.notify("Not in a git repository", "warning");
				return;
			}

			const baseBranch = await getDefaultBranch();
			if (!baseBranch || branch === baseBranch) {
				ctx.ui.notify(`On default branch (${branch}), no context needed`, "info");
				return;
			}

			const cache = loadCache(branch);
			if (!cache) {
				ctx.ui.notify(
					`No context cached for ${branch}. Run /refresh-branch-context to enable.`,
					"info",
				);
				return;
			}

			const timestamp = new Date(cache.timestamp).toLocaleString();
			ctx.ui.print(
				`**Branch:** ${cache.branch}\n**Base:** ${cache.baseBranch}\n**Cached:** ${timestamp}\n\n${cache.context}`,
			);
		},
	});

	/**
	 * Command: Regenerate branch context
	 */
	pi.registerCommand("refresh-branch-context", {
		description: "Regenerate branch context summary",
		handler: async (_args, ctx) => {
			const branch = await getCurrentBranch();
			if (!branch) {
				ctx.ui.notify("Not in a git repository", "warning");
				return;
			}

			const baseBranch = await getDefaultBranch();
			if (!baseBranch || branch === baseBranch) {
				ctx.ui.notify(
					`On default branch (${branch}), no context needed`,
					"info",
				);
				return;
			}

			ctx.ui.notify(`Regenerating context for ${branch}...`, "info");

			const { context } = await getBranchContext(branch, baseBranch, true);

			ctx.ui.notify("✓ Context refreshed", "success");
			ctx.ui.print(`**Branch:** ${branch}\n**Base:** ${baseBranch}\n\n${context}`);
		},
	});

	/**
	 * Command: Set custom branch purpose
	 */
	pi.registerCommand("set-branch-purpose", {
		description: "Set custom branch purpose note",
		handler: async (args, ctx) => {
			const branch = await getCurrentBranch();
			if (!branch) {
				ctx.ui.notify("Not in a git repository", "warning");
				return;
			}

			const purpose = args?.trim();
			if (!purpose) {
				ctx.ui.notify("Usage: /set-branch-purpose <purpose>", "warning");
				return;
			}

			// Update cache
			const cache = loadCache(branch);
			if (cache) {
				cache.customPurpose = purpose;
				saveCache(cache);
				ctx.ui.notify(`✓ Updated purpose for ${branch}`, "success");
			} else {
				// Create minimal cache entry
				const baseBranch = (await getDefaultBranch()) || "main";
				const diffHash = (await getDiffHash(branch, baseBranch)) || "";
				saveCache({
					branch,
					baseBranch,
					diffHash,
					context: "",
					customPurpose: purpose,
					timestamp: Date.now(),
				});
				ctx.ui.notify(
					`✓ Set purpose for ${branch}. Run /refresh-branch-context to regenerate.`,
					"success",
				);
			}
		},
	});
}
