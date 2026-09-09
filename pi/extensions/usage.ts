/**
 * Usage Command - Account-wide usage information
 *
 * Shows total account usage and costs:
 * - Claude: Uses Admin API for organization usage data
 * - Copilot: Uses GitHub REST API for usage metrics
 * 
 * This is ACCOUNT-WIDE usage, not session-scoped.
 * Use /session for session-specific info.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CLAUDE_USAGE_API = "https://api.anthropic.com/v1/organizations/usage_report/messages";
const GITHUB_COPILOT_API = "https://api.github.com/user/copilot/usage";
const FETCH_TIMEOUT_MS = 15_000;

interface UsageData {
	success: boolean;
	data?: any;
	error?: string;
	needsAuth?: boolean;
	needsAdminKey?: boolean;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("usage", {
		description: "Show account-wide usage and cost information",
		handler: async (_args, ctx) => {
			const provider = ctx.model?.provider || "unknown";

			const lines: string[] = [];
			lines.push("📊 Account Usage");
			lines.push("");

			if (provider === "anthropic") {
				await handleClaudeUsage(ctx, lines);
			} else if (provider === "github-copilot") {
				await handleCopilotUsage(ctx, lines);
			} else {
				handleOtherProvider(provider, lines);
			}

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}

async function handleClaudeUsage(ctx: any, lines: string[]) {
	lines.push("Claude Account:");
	lines.push("");

	// Check if using OAuth (subscription) vs API key
	const isOAuth = ctx.modelRegistry.isUsingOAuth(ctx.model);
	
	if (isOAuth) {
		// OAuth subscription - reference footer
		lines.push("Claude Subscription:");
		lines.push("");
		lines.push("✅ Live usage limits shown in footer (🧠)");
		lines.push("");
		lines.push("The footer shows:");
		lines.push("  • 5h    = 5-hour rolling window");
		lines.push("  • wk    = Weekly all-models limit");
		lines.push("  • opus/sonnet = Per-model weekly limits");
		lines.push("");
		lines.push("⚠️  If you see extra usage warning, you've exceeded subscription limits");
		lines.push("");
		lines.push("For detailed breakdown:");
		lines.push("  https://console.anthropic.com/");
		return;
	}

	// API key - try to fetch usage data
	const usageData = await fetchClaudeUsage(ctx);

	if (usageData.needsAdminKey) {
		lines.push("⚠️  Admin API Key Required");
		lines.push("");
		lines.push("Account-wide usage requires an Admin API key.");
		lines.push("");
		lines.push("To create one:");
		lines.push("1. Go to: https://console.anthropic.com/settings/keys");
		lines.push("2. Create an Admin API key (starts with sk-ant-admin01-...)");
		lines.push("3. Set it with: pi --set-api-key anthropic");
		lines.push("");
		lines.push("Or check usage in Console:");
		lines.push("  https://console.anthropic.com/settings/cost");

	} else if (usageData.success && usageData.data) {
		// Display usage data
		const data = usageData.data;
		lines.push("Recent Usage (last 7 days):");
		lines.push("");
		
		if (data.total_tokens) {
			lines.push(`Total Tokens:     ${formatNumber(data.total_tokens)}`);
		}
		if (data.total_cost !== undefined) {
			lines.push(`Total Cost:       $${data.total_cost.toFixed(2)}`);
		}
		lines.push("");
		lines.push("For detailed breakdown:");
		lines.push("  https://console.anthropic.com/settings/cost");

	} else {
		lines.push("Could not fetch usage data");
		lines.push("");
		if (usageData.error) {
			lines.push(`Error: ${usageData.error}`);
			lines.push("");
		}
		lines.push("Check usage in Console:");
		lines.push("  https://console.anthropic.com/settings/cost");
	}
}

async function handleCopilotUsage(ctx: any, lines: string[]) {
	lines.push("GitHub Copilot Account:");
	lines.push("");

	const usageData = await fetchCopilotUsage(ctx);

	if (usageData.needsAuth) {
		lines.push("⚠️  Not authenticated");
		lines.push("");
		lines.push("Run /login to authenticate with GitHub");

	} else if (usageData.success && usageData.data) {
		// Display Copilot usage
		const data = usageData.data;
		
		if (data.ai_credits_used !== undefined) {
			lines.push(`AI Credits Used:  ${formatNumber(data.ai_credits_used)}`);
		}
		if (data.ai_credits_remaining !== undefined) {
			lines.push(`Credits Remaining: ${formatNumber(data.ai_credits_remaining)}`);
		}
		if (data.period) {
			lines.push(`Period: ${data.period}`);
		}
		lines.push("");
		lines.push("For detailed breakdown:");
		lines.push("  https://github.com/settings/copilot");

	} else {
		lines.push("ℹ️  Usage data not available");
		lines.push("");
		lines.push("Copilot usage API requires:");
		lines.push("  • Enterprise or Organization account");
		lines.push("  • 'Copilot usage metrics' policy enabled");
		lines.push("  • Appropriate permissions");
		lines.push("");
		lines.push("Check your account at:");
		lines.push("  https://github.com/settings/copilot");
		
		if (usageData.error) {
			lines.push("");
			lines.push(`Error: ${usageData.error}`);
		}
	}
}

function handleOtherProvider(provider: string, lines: string[]) {
	lines.push(`Provider: ${provider}`);
	lines.push("");
	lines.push("ℹ️  Account usage not available for this provider");
	lines.push("");
	lines.push("Check your provider dashboard:");
	lines.push("  • OpenAI: https://platform.openai.com/usage");
	lines.push("  • Google: https://console.cloud.google.com/");
	lines.push("");
	lines.push("Session-specific usage available via /session");
}

/**
 * Fetch Claude usage data using Admin API
 */
async function fetchClaudeUsage(ctx: any): Promise<UsageData> {
	try {
		const apiKey = await ctx.modelRegistry.getApiKeyForProvider("anthropic");
		
		if (!apiKey) {
			return { success: false, needsAuth: true };
		}

		// Check if it's an admin key
		if (!apiKey.startsWith("sk-ant-admin")) {
			return { success: false, needsAdminKey: true };
		}

		// Get last 7 days of data
		const now = new Date();
		const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
		
		const url = new URL(CLAUDE_USAGE_API);
		url.searchParams.append("starting_at", sevenDaysAgo.toISOString());
		url.searchParams.append("ending_at", now.toISOString());
		url.searchParams.append("bucket_width", "1d");

		const response = await fetch(url.toString(), {
			headers: {
				"anthropic-version": "2023-06-01",
				"x-api-key": apiKey,
			},
			signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
		});

		if (response.status === 401 || response.status === 403) {
			return { success: false, needsAdminKey: true };
		}

		if (!response.ok) {
			return { success: false, error: `HTTP ${response.status}` };
		}

		const data = await response.json();
		
		// Aggregate totals
		let totalTokens = 0;
		let totalCost = 0;
		
		if (data.results && Array.isArray(data.results)) {
			for (const bucket of data.results) {
				if (bucket.total_tokens) totalTokens += bucket.total_tokens;
				if (bucket.total_cost) totalCost += bucket.total_cost;
			}
		}

		return {
			success: true,
			data: {
				total_tokens: totalTokens,
				total_cost: totalCost,
				raw: data,
			},
		};

	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		return { success: false, error: message };
	}
}

/**
 * Fetch Copilot usage data using GitHub REST API
 */
async function fetchCopilotUsage(ctx: any): Promise<UsageData> {
	try {
		const token = await ctx.modelRegistry.getApiKeyForProvider("github-copilot");
		
		if (!token) {
			return { success: false, needsAuth: true };
		}

		const response = await fetch(GITHUB_COPILOT_API, {
			headers: {
				"Authorization": `Bearer ${token}`,
				"Accept": "application/vnd.github+json",
				"X-GitHub-Api-Version": "2022-11-28",
			},
			signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
		});

		if (response.status === 401 || response.status === 403) {
			return { success: false, needsAuth: true };
		}

		if (response.status === 404) {
			// Endpoint not available for this account
			return { success: false, error: "Usage API not available for your account type" };
		}

		if (!response.ok) {
			return { success: false, error: `HTTP ${response.status}` };
		}

		const data = await response.json();
		return { success: true, data };

	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		return { success: false, error: message };
	}
}

function formatNumber(num: number): string {
	if (num >= 1_000_000) {
		return `${(num / 1_000_000).toFixed(2)}M`;
	}
	if (num >= 1_000) {
		return `${(num / 1_000).toFixed(1)}k`;
	}
	return num.toLocaleString();
}
