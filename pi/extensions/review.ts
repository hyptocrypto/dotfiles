/**
 * Local PR Review Extension
 *
 * /review [baseBranch] - Reviews current branch's diff against a base branch
 * (default branch if omitted) using a lightweight model, looking for bugs,
 * logical gaps, edge cases, and other issues a PR reviewer would flag.
 * Runs entirely locally - no GitHub/Copilot/CodeRabbit round-trip.
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { BorderedLoader, getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Text } from "@earendil-works/pi-tui";

interface ReviewEntryData {
	branch: string;
	baseBranch: string;
	focus?: string;
	modelId: string;
	filesChanged: number;
	diffChars: number;
	truncated: boolean;
	tokens: number;
	cost: number;
	durationMs: number;
	review: string;
	timestamp: number;
}

// Cap diff size sent to the review model (chars, not tokens)
const MAX_DIFF_CHARS = 60000;

// Cheap/fast models per provider - good enough to catch obvious issues
const REVIEW_MODELS: Record<string, string> = {
	anthropic: "claude-haiku-4-5",
	"github-copilot": "gemini-3.8-flash",
};

export default function (pi: ExtensionAPI) {
	pi.registerEntryRenderer<ReviewEntryData>("review-result", (entry, _options, theme) => {
		const d = entry.data;
		const box = new Box(1, 1, (text) => theme.bg("customMessageBg", text));
		if (!d) {
			box.addChild(new Text(theme.fg("dim", "(no review data)"), 0, 0));
			return box;
		}

		const header = [
			`${theme.fg("accent", theme.bold("Local PR Review"))} ${theme.fg("dim", `${d.branch} vs ${d.baseBranch}`)}`,
			theme.fg(
				"dim",
				`model=${d.modelId}  files=${d.filesChanged}  diff=${d.diffChars} chars${d.truncated ? " (truncated)" : ""}  ` +
					`tokens=${d.tokens}  cost=$${d.cost.toFixed(4)}  time=${(d.durationMs / 1000).toFixed(1)}s`,
			),
		];
		if (d.focus) {
			header.push(theme.fg("dim", `focus: ${d.focus}`));
		}
		box.addChild(new Text(header.join("\n"), 0, 0));
		box.addChild(new Markdown(d.review, 0, 1, getMarkdownTheme()));

		return box;
	});

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
	 * Run the review directly in-process via the model registry (no
	 * subprocess). Shows a live bordered spinner in interactive mode; falls
	 * back to a plain notify in non-interactive/print/RPC mode.
	 */
	async function runReviewModel(
		task: string,
		provider: string,
		ctx: ExtensionCommandContext,
	): Promise<{ text: string; tokens: number; cost: number }> {
		const modelId = REVIEW_MODELS[provider] || REVIEW_MODELS.anthropic;
		const model = ctx.modelRegistry.find(provider, modelId);
		if (!model) {
			return { text: `(Model ${provider}/${modelId} not found)`, tokens: 0, cost: 0 };
		}
		if (!ctx.modelRegistry.hasConfiguredAuth(model)) {
			return { text: `(No authentication configured for ${provider}/${modelId})`, tokens: 0, cost: 0 };
		}

		const context = {
			systemPrompt: "You are a senior engineer performing a local PR review.",
			messages: [
				{
					role: "user" as const,
					content: [{ type: "text" as const, text: task }],
					timestamp: Date.now(),
				},
			],
		};

		const runComplete = async (signal?: AbortSignal) => {
			try {
				const response = await ctx.modelRegistry.complete(model, context, { signal });
				if (response.stopReason === "aborted") {
					return { text: "(Review cancelled)", tokens: 0, cost: 0 };
				}
				const text = response.content
					.filter((c): c is { type: "text"; text: string } => c.type === "text")
					.map((c) => c.text)
					.join("\n")
					.trim();
				return {
					text: text || "(Empty response from model)",
					tokens: response.usage?.totalTokens ?? 0,
					cost: response.usage?.cost?.total ?? 0,
				};
			} catch (error) {
				return { text: `(Review failed: ${error})`, tokens: 0, cost: 0 };
			}
		};

		// Interactive mode: show a live cancellable spinner.
		if (ctx.mode === "tui") {
			return ctx.ui.custom((tui, theme, _kb, done) => {
				const loader = new BorderedLoader(tui, theme, `Reviewing with ${model.id}...`, {
					cancellable: true,
				});
				loader.onAbort = () => done({ text: "(Review cancelled)", tokens: 0, cost: 0 });
				runComplete(loader.signal).then(done);
				return loader;
			});
		}

		// Non-interactive (print/RPC): no spinner widget available, just run it.
		ctx.ui.notify(`Reviewing with ${model.id}...`, "info");
		return runComplete();
	}

	pi.registerCommand("review", {
		description: "Run a local PR-style review of current branch vs base branch",
		handler: async (args, ctx) => {
			const branch = await getCurrentBranch();
			if (!branch) {
				ctx.ui.notify("Not in a git repository", "warning");
				return;
			}

			// args is free-form review focus/instructions, e.g.
			// "/review pay close attention to auth checks". It is never a
			// branch name - base branch is always auto-detected. Use
			// "--base <branch>" to override the base branch explicitly.
			let focus = args?.trim() || "";
			let baseOverride: string | undefined;
			const baseMatch = focus.match(/(?:^|\s)--base[= ](\S+)/);
			if (baseMatch) {
				baseOverride = baseMatch[1];
				focus = focus.replace(baseMatch[0], "").trim();
			}

			const baseBranch = baseOverride || (await getDefaultBranch());
			if (!baseBranch) {
				ctx.ui.notify("Could not determine base branch", "warning");
				return;
			}
			if (branch === baseBranch) {
				ctx.ui.notify(`Already on ${baseBranch}, nothing to compare`, "warning");
				return;
			}

			ctx.ui.notify(`Computing diff for ${branch} vs ${baseBranch}...`, "info");

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

			let filesChanged = 0;
			try {
				const { stdout } = await pi.exec("git", [
					"diff",
					"--name-only",
					`${baseBranch}...${branch}`,
				]);
				filesChanged = stdout.split("\n").filter((l) => l.trim()).length;
			} catch {
				filesChanged = 0;
			}

			ctx.ui.notify(
				`Diff: ${filesChanged} file(s), ${diff.length} chars${truncated ? ` (truncated from larger diff, capped at ${MAX_DIFF_CHARS})` : ""}`,
				"info",
			);

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
${focus ? `\n**Additional reviewer focus (from user):** ${focus}\n` : ""}

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
			const modelId = REVIEW_MODELS[provider] || REVIEW_MODELS.anthropic;
			ctx.ui.notify(
				`Sending diff to ${provider}/${modelId} for review (this can take 10-60s for large diffs)...`,
				"info",
			);

			const startedAt = Date.now();
			const { text: review, tokens, cost } = await runReviewModel(task, provider, ctx);
			const durationMs = Date.now() - startedAt;

			pi.appendEntry<ReviewEntryData>("review-result", {
				branch,
				baseBranch,
				focus: focus || undefined,
				modelId,
				filesChanged,
				diffChars: diff.length,
				truncated,
				tokens,
				cost,
				durationMs,
				review,
				timestamp: Date.now(),
			});

			const usageLine = tokens ? ` (${tokens} tokens, $${cost.toFixed(4)}, ${(durationMs / 1000).toFixed(1)}s)` : "";
			ctx.ui.notify(`✓ Review complete${usageLine}`, "success");
		},
	});
}
