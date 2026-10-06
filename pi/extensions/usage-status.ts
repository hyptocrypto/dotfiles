/**
 * Usage Status - Shows Claude subscription usage (5h, weekly, per-model)
 * Based on pi-claude-subscription-connector
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const USAGE_URL = "https://api.anthropic.com/api/oauth/usage";
const POLL_INTERVAL_MS = 30_000; // 30 seconds
const FETCH_TIMEOUT_MS = 10_000;

interface UsageWindow {
	label: string;
	percent: number;
}

function parseUsage(json: any): UsageWindow[] {
	const windows: UsageWindow[] = [];
	
	// Try limits[] array first (new format)
	if (Array.isArray(json.limits)) {
		const labelMap: Record<string, string> = {
			session: "5h",
			weekly_all: "wk",
		};
		
		for (const entry of json.limits) {
			if (typeof entry.percent !== "number") continue;
			
			let label = labelMap[entry.kind];
			if (!label && entry.kind === "weekly_scoped") {
				const displayName = entry.scope?.model?.display_name || "";
				label = displayName.toLowerCase() || "model";
			}
			
			windows.push({
				label: label || entry.kind || "limit",
				percent: Math.round(entry.percent),
			});
		}
		
		if (windows.length > 0) return windows;
	}
	
	// Fallback to old format
	const fallbacks = [
		["five_hour", "5h"],
		["seven_day", "wk"],
		["seven_day_opus", "opus"],
		["seven_day_sonnet", "sonnet"],
	];
	
	for (const [key, label] of fallbacks) {
		const util = json[key]?.utilization;
		if (typeof util === "number") {
			windows.push({ label, percent: Math.round(util) });
		}
	}
	
	return windows;
}

function formatUsage(windows: UsageWindow[]): string {
	if (windows.length === 0) return "🧠 usage n/a";
	return `🧠 ${windows.map(w => `${w.label} ${w.percent}%`).join(" · ")}`;
}

function getColor(windows: UsageWindow[]): string {
	const max = Math.max(...windows.map(w => w.percent), 0);
	if (max >= 90) return "error";
	if (max >= 70) return "warning";
	return "success";
}

export default function (pi: ExtensionAPI) {
	let windows: UsageWindow[] = [];
	let lastPollMs: number | undefined;
	let pollInterval: NodeJS.Timeout | null = null;

	async function refresh(ctx: any): Promise<void> {
		// Only for Anthropic OAuth
		if (ctx.model?.provider !== "anthropic") {
			ctx.ui.setStatus("usage", undefined);
			return;
		}
		
		if (!ctx.modelRegistry?.isUsingOAuth?.(ctx.model)) {
			ctx.ui.setStatus("usage", undefined);
			return;
		}
		
		const now = Date.now();
		if (lastPollMs && now - lastPollMs < POLL_INTERVAL_MS) {
			// Just render with existing data
			const text = formatUsage(windows);
			const color = getColor(windows);
			ctx.ui.setStatus("usage", ctx.ui.theme?.fg(color, text) || text);
			return;
		}
		
		lastPollMs = now;
		
		try {
			const token = await ctx.modelRegistry.getApiKeyForProvider("anthropic");
			if (!token) {
				ctx.ui.setStatus("usage", ctx.ui.theme?.fg("warning", "🧠 login needed"));
				return;
			}
			
			const response = await fetch(USAGE_URL, {
				headers: {
					authorization: `Bearer ${token}`,
					"anthropic-beta": "oauth-2025-04-20",
				},
				signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
			});
			
			if (!response.ok) {
				ctx.ui.setStatus("usage", ctx.ui.theme?.fg("warning", "🧠 fetch failed"));
				return;
			}
			
			const data = await response.json();
			const parsed = parseUsage(data);
			
			if (parsed.length > 0) {
				windows = parsed;
			}
			
			const text = formatUsage(windows);
			const color = getColor(windows);
			ctx.ui.setStatus("usage", ctx.ui.theme?.fg(color, text));
		} catch (err) {
			// Keep last known data on network errors
			const text = windows.length > 0 ? formatUsage(windows) + " (stale)" : "🧠 fetch error";
			ctx.ui.setStatus("usage", ctx.ui.theme?.fg("warning", text));
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		
		await refresh(ctx);
		
		// Poll every 30s
		if (pollInterval) clearInterval(pollInterval);
		pollInterval = setInterval(() => {
			void refresh(ctx);
		}, POLL_INTERVAL_MS);
	});

	pi.on("model_select", async (event, ctx) => {
		await refresh(ctx);
	});

	pi.on("session_shutdown", () => {
		if (pollInterval) {
			clearInterval(pollInterval);
			pollInterval = null;
		}
	});
}
