/**
 * Local PR Review Extension
 *
 * /review [baseBranch] - Reviews current branch's diff against a base branch
 * (default branch if omitted) using a lightweight model, looking for bugs,
 * logical gaps, edge cases, and other issues a PR reviewer would flag.
 * Runs entirely locally - no GitHub/Copilot/CodeRabbit round-trip.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Cap diff size sent to the review model (chars, not tokens)
const MAX_DIFF_CHARS = 60000;

// Cheap/fast models per provider - good enough to catch obvious issues
const REVIEW_MODELS: Record<string, string> = {
	anthropic: "claude-haiku-4-5",
	"github-copilot": "gemini-3.8-flash",
};

export default function (pi: ExtensionAPI) {
	async function getCurrentBranch(): Promise<string | null> {
		try {
			const { stdout } = await pi.exec("git", ["rev-parse", "--abbrev-ref", "HEAD"]);
			return stdout.trim() || null;
		} catch {
			return null;
		}
	}

	async function getDefaultBranch(): Promise<string | null> {
		try {
			const { stdout } = await pi.exec("git", [
				"symbolic-ref",
				"refs/remotes/origin/HEAD",
			]);
			const ref = stdout.trim().replace(/^refs\/remotes\/origin\//, "");
			if (ref) return ref;
		} catch {
			// fall through
		}
		for (const name of ["main", "master", "development", "develop", "dev"]) {
			try {
				await pi.exec("git", ["rev-parse", "--verify", name]);
				return name;
			} catch {
				// try next
			}
		}
		return "main";
	}

	/**
	 * Run `pi --print` as a subprocess, feeding the task via stdin.
	 *
	 * Task must go over stdin, not argv: on machines running endpoint
	 * security agents (e.g. SentinelOne), a long command-line argument
	 * (~1KB+) gets the freshly-exec'd process SIGKILLed before it runs.
	 */
	function runReviewModel(task: string, provider: string): Promise<string> {
		const model = REVIEW_MODELS[provider] || REVIEW_MODELS.anthropic;

		return new Promise<string>((resolve) => {
			const child = spawn("pi", ["--provider", provider, "--model", model, "--print"], {
				stdio: ["pipe", "pipe", "pipe"],
				timeout: 120000,
			});

			let stdout = "";
			let stderr = "";

			child.stdin?.write(task);
			child.stdin?.end();

			child.stdout?.on("data", (data) => (stdout += data.toString()));
			child.stderr?.on("data", (data) => (stderr += data.toString()));

			child.on("error", (error) => resolve(`(Failed to spawn pi: ${error.message})`));

			child.on("close", (code) => {
				if (code === 0 && stdout.trim()) {
					resolve(stdout.trim());
				} else {
					resolve(`(Review failed: ${stderr || `process exited with code ${code}`})`);
				}
			});

			setTimeout(() => {
				if (!child.killed) {
					child.kill();
					resolve("(Review timed out after 120 seconds)");
				}
			}, 120000);
		});
	}

	pi.registerCommand("review", {
		description: "Run a local PR-style review of current branch vs base branch",
		handler: async (args, ctx) => {
			const branch = await getCurrentBranch();
			if (!branch) {
				ctx.ui.notify("Not in a git repository", "warning");
				return;
			}

			const baseBranch = args?.trim() || (await getDefaultBranch());
			if (!baseBranch) {
				ctx.ui.notify("Could not determine base branch", "warning");
				return;
			}
			if (branch === baseBranch) {
				ctx.ui.notify(`Already on ${baseBranch}, nothing to compare`, "warning");
				return;
			}

			ctx.ui.notify(`Reviewing ${branch} vs ${baseBranch}...`, "info");

			let diff = "";
			let truncated = false;
			try {
				const { stdout } = await pi.exec("git", [
					"diff",
					`${baseBranch}...${branch}`,
				]);
				diff = stdout;
				if (diff.length > MAX_DIFF_CHARS) {
					diff = diff.slice(0, MAX_DIFF_CHARS);
					truncated = true;
				}
			} catch (error) {
				ctx.ui.notify(`Failed to compute diff: ${error}`, "error");
				return;
			}

			if (!diff.trim()) {
				ctx.ui.notify(`No diff between ${branch} and ${baseBranch}`, "info");
				return;
			}

			let commitLog = "";
			try {
				const { stdout } = await pi.exec("git", [
					"log",
					"--oneline",
					`${baseBranch}..${branch}`,
					"--max-count=30",
				]);
				commitLog = stdout;
			} catch {
				commitLog = "(no commits)";
			}

			const task = `OUTPUT ONLY THE REVIEW BELOW. NO CONVERSATIONAL TEXT, NO PREAMBLE.

You are doing a PR code review, like a senior engineer reviewing a pull request
before merge. Review the diff below of branch "${branch}" against base "${baseBranch}".

Focus on:
- Actual bugs (logic errors, off-by-one, wrong conditionals, incorrect state handling)
- Logical gaps (missing error handling, unhandled edge cases, incomplete conditions)
- Concurrency/resource issues (races, leaks, unclosed handles, missing timeouts/cancellation)
- Security issues (injection, unvalidated input, secrets, unsafe deserialization)
- API/contract breaks (signature changes without updating callers, migration gaps)
- Dead code, obvious duplication, or contradicts existing patterns in the diff
- SQL inefficiencies and IDOR

Do NOT comment on style/formatting nitpicks unless they cause a real bug.
Do NOT restate the diff. Be specific: cite file and line/hunk for every finding.
If you find nothing of concern in a file, don't mention that file.

**Recent commits:**
\`\`\`
${commitLog}
\`\`\`

**Diff:**
\`\`\`diff
${diff}
\`\`\`
${truncated ? "\n(Diff truncated - review covers only the first part of the changes.)\n" : ""}

OUTPUT FORMAT (start immediately, no preamble):

## Summary
1-2 sentences on overall change quality/risk.

## Findings
For each issue: \`file:line\` - severity (blocker/major/minor) - description and suggested fix.
If none, write "No significant issues found."

## Questions for the author
Anything ambiguous that needs clarification before merge (omit section if none).
`.trim();

			const provider = ctx.model?.provider || "github-copilot";
			const review = await runReviewModel(task, provider);

			ctx.ui.notify("✓ Review complete", "success");
			return `**Review:** ${branch} vs ${baseBranch}${truncated ? " _(diff truncated)_" : ""}\n\n${review}`;
		},
	});
}
