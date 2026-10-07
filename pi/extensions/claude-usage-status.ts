// 🧠 Claude subscription usage in pi's footer status line.
//
// Shows live utilization of the Claude Pro/Max rate-limit windows
// (session 5h · weekly all-models · weekly model-scoped) fetched from
// Anthropic's OAuth usage endpoint, colored green/yellow/red, and raises
// a loud alarm if a response ever reports billing to "extra usage"
// (anthropic-ratelimit-unified-overage-in-use) instead of the subscription.
//
// Connector failures are never silent: rejected requests (HTTP 400) and
// auth loss turn the line red/yellow, and a failing usage fetch is marked
// "(stale)" — or "usage n/a" when nothing was ever read.
//
// The status key "0-claude-max" is chosen deliberately: pi's footer sorts
// extension statuses alphabetically by key (localeCompare), and "0" sorts
// before every letter, so this line renders first.

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export const STATUS_KEY = "0-claude-max";
export const USAGE_URL = "https://api.anthropic.com/api/oauth/usage";
export const POLL_MIN_INTERVAL_MS = 30_000;
export const IDLE_REFRESH_MS = 5 * 60_000;
export const OVERAGE_HEADER = "anthropic-ratelimit-unified-overage-in-use";
const CONFLICT_PACKAGE = "@benvargas/pi-claude-code-use";
const FETCH_TIMEOUT_MS = 10_000;

// ============================================================================
// Pure logic (exported for tests — no pi imports at runtime)
// ============================================================================

export interface UsageWindow {
	label: string;
	percent: number;
}

export type Severity = "ok" | "warn" | "critical";

function asPercent(value: unknown): number | undefined {
	return typeof value === "number" && Number.isFinite(value) ? Math.round(value) : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

const LIMIT_KIND_LABELS: Record<string, string> = {
	session: "5h",
	weekly_all: "wk",
};

/**
 * Parse the /api/oauth/usage response into display windows.
 *
 * Primary source is `limits[]` (kind: session | weekly_all | weekly_scoped,
 * percent, scope.model.display_name). Falls back to the top-level
 * `five_hour` / `seven_day` / `seven_day_opus` / `seven_day_sonnet`
 * utilization fields when `limits[]` is missing or empty.
 */
export function parseUsage(json: unknown): UsageWindow[] {
	if (!isRecord(json)) return [];

	const limits = json.limits;
	if (Array.isArray(limits)) {
		const windows: UsageWindow[] = [];
		for (const entry of limits) {
			if (!isRecord(entry)) continue;
			const percent = asPercent(entry.percent);
			if (percent === undefined) continue;
			const kind = typeof entry.kind === "string" ? entry.kind : "";
			let label = LIMIT_KIND_LABELS[kind];
			if (!label && kind === "weekly_scoped") {
				const scope = isRecord(entry.scope) ? entry.scope : undefined;
				const model = scope && isRecord(scope.model) ? scope.model : undefined;
				const displayName = model && typeof model.display_name === "string" ? model.display_name : "";
				label = displayName ? displayName.toLowerCase() : "model wk";
			}
			windows.push({ label: label || kind || "limit", percent });
		}
		if (windows.length > 0) return windows;
	}

	const windows: UsageWindow[] = [];
	const fallbacks: Array<[key: string, label: string]> = [
		["five_hour", "5h"],
		["seven_day", "wk"],
		["seven_day_opus", "opus"],
		["seven_day_sonnet", "sonnet"],
	];
	for (const [key, label] of fallbacks) {
		const block = json[key];
		if (!isRecord(block)) continue;
		const percent = asPercent(block.utilization);
		if (percent !== undefined) windows.push({ label, percent });
	}
	return windows;
}

/** "🧠 5h 19% · wk 24% · fable 46%" (+ " ⚠ extra usage" when the alarm is on). */
export function formatStatusLine(windows: UsageWindow[], alarm = false): string {
	const body =
		windows.length > 0 ? windows.map((w) => `${w.label} ${w.percent}%`).join(" · ") : "usage n/a";
	return `🧠 ${body}${alarm ? " ⚠ extra usage" : ""}`;
}

/** Green below 70%, yellow at 70–89%, red at 90%+ or whenever the alarm is on. */
export function severityOf(windows: UsageWindow[], alarm = false): Severity {
	if (alarm) return "critical";
	const max = windows.reduce((acc, w) => Math.max(acc, w.percent), 0);
	if (max >= 90) return "critical";
	if (max >= 70) return "warn";
	return "ok";
}

export const SEVERITY_COLOR: Record<Severity, string> = {
	ok: "success",
	warn: "warning",
	critical: "error",
};

/** Everything the status line needs to render one frame. */
export interface StatusSnapshot {
	windows: UsageWindow[];
	/** A response reported billing to extra usage (overage) instead of the plan. */
	alarm: boolean;
	/** OAuth token missing or rejected (usage endpoint or provider 401/403). */
	loginNeeded: boolean;
	/** The last usage-endpoint read failed (network, HTTP error, or bad shape). */
	fetchFailed: boolean;
	/** Set while the last provider request was rejected outright (HTTP 400). */
	providerErrorStatus: number | undefined;
}

/**
 * Compose the footer line for a snapshot. Priority: login problems, then
 * connector failures (overage billing / rejected requests, both red), then
 * usage-severity coloring. A failing usage fetch keeps the last known numbers
 * on screen with a "(stale)" marker instead of hiding the problem.
 */
export function composeStatus(s: StatusSnapshot): { text: string; color: string } {
	if (s.loginNeeded) return { text: "🧠 login needed", color: "warning" };

	const connectorFailure = s.alarm || s.providerErrorStatus !== undefined;
	if (s.windows.length === 0 && !connectorFailure && !s.fetchFailed) {
		return { text: "🧠 …", color: "dim" }; // first fetch still in flight
	}

	let text = formatStatusLine(s.windows, s.alarm);
	if (!s.alarm && s.providerErrorStatus !== undefined) text += ` ⚠ HTTP ${s.providerErrorStatus}`;
	if (s.fetchFailed && s.windows.length > 0) text += " (stale)";

	const color = connectorFailure
		? "error"
		: s.fetchFailed && s.windows.length === 0
			? "warning"
			: SEVERITY_COLOR[severityOf(s.windows)];
	return { text, color };
}

export function shouldPoll(lastPollMs: number | undefined, nowMs: number, minIntervalMs = POLL_MIN_INTERVAL_MS): boolean {
	return lastPollMs === undefined || nowMs - lastPollMs >= minIntervalMs;
}

/** True when a settings `packages` array references the conflicting upstream package. */
export function hasConflictingPackage(settings: unknown): boolean {
	if (!isRecord(settings) || !Array.isArray(settings.packages)) return false;
	return settings.packages.some((entry) => {
		if (typeof entry === "string") return entry.includes(CONFLICT_PACKAGE);
		return isRecord(entry) && typeof entry.source === "string" && entry.source.includes(CONFLICT_PACKAGE);
	});
}

// ============================================================================
// Extension wiring
// ============================================================================

interface StatusUi {
	setStatus(key: string, text: string | undefined): void;
	notify(message: string, type?: string): void;
	theme?: { fg(color: string, text: string): string };
}

interface StatusCtx {
	ui: StatusUi;
	model?: { provider: string } | undefined;
	modelRegistry: {
		isUsingOAuth(model: { provider: string }): boolean;
		getApiKeyForProvider(provider: string): Promise<string | undefined>;
	};
	hasUI?: boolean;
	cwd?: string;
}

export default function usageStatus(pi: ExtensionAPI) {
	let windows: UsageWindow[] = [];
	let alarm = false;
	let loginNeeded = false;
	let fetchFailed = false;
	let providerErrorStatus: number | undefined;
	let lastPollMs: number | undefined;
	let inFlight = false;
	let idleTimer: ReturnType<typeof setInterval> | undefined;

	const paint = (ui: StatusUi, color: string, text: string): string =>
		ui.theme ? ui.theme.fg(color, text) : text;

	const isOAuthAnthropic = (ctx: StatusCtx, model = ctx.model): boolean =>
		model?.provider === "anthropic" && ctx.modelRegistry.isUsingOAuth(model);

	function render(ctx: StatusCtx): void {
		if (!isOAuthAnthropic(ctx)) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			return;
		}
		const { text, color } = composeStatus({ windows, alarm, loginNeeded, fetchFailed, providerErrorStatus });
		ctx.ui.setStatus(STATUS_KEY, paint(ctx.ui, color, text));
	}

	async function refresh(ctx: StatusCtx, force = false): Promise<void> {
		if (!isOAuthAnthropic(ctx)) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			return;
		}
		if (inFlight || (!force && !shouldPoll(lastPollMs, Date.now()))) {
			render(ctx);
			return;
		}
		inFlight = true;
		lastPollMs = Date.now();
		try {
			const token = await ctx.modelRegistry.getApiKeyForProvider("anthropic");
			if (!token) {
				loginNeeded = true;
				return;
			}
			const response = await fetch(USAGE_URL, {
				headers: {
					authorization: `Bearer ${token}`,
					"anthropic-beta": "oauth-2025-04-20",
				},
				signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
			});
			if (response.status === 401 || response.status === 403) {
				loginNeeded = true;
				fetchFailed = false;
				return;
			}
			if (!response.ok) {
				fetchFailed = true; // shown as "(stale)" / "usage n/a"
				return;
			}
			const parsed = parseUsage(await response.json());
			if (parsed.length > 0 || windows.length === 0) windows = parsed;
			loginNeeded = false;
			// An unrecognized/empty payload counts as a failed read too.
			fetchFailed = parsed.length === 0;
		} catch {
			// Network problems must never break the session; keep last known
			// data, but surface the failure in the status line.
			fetchFailed = true;
		} finally {
			inFlight = false;
			render(ctx);
		}
	}

	function warnOnConflict(ctx: StatusCtx): void {
		const settingsPaths: string[] = [];
		try {
			// Lazy import: only resolvable (and only needed) when running inside pi.
			// Keeping it out of module scope lets `node --test` import this file.
			void import("@earendil-works/pi-coding-agent").then(({ getAgentDir, CONFIG_DIR_NAME }) => {
				settingsPaths.push(join(getAgentDir(), "settings.json"));
				if (ctx.cwd) settingsPaths.push(join(ctx.cwd, CONFIG_DIR_NAME, "settings.json"));
				for (const path of settingsPaths) {
					try {
						if (!existsSync(path)) continue;
						if (hasConflictingPackage(JSON.parse(readFileSync(path, "utf-8")))) {
							ctx.ui.notify(
								`pi-claude-subscription-connector: remove ${CONFLICT_PACKAGE} from ${path} — both packages sanitize Anthropic OAuth payloads and must not run together.`,
								"warning",
							);
							return;
						}
					} catch {
						// Unreadable settings file — nothing to warn about.
					}
				}
			});
		} catch {
			// Conflict detection is best-effort; never break startup.
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		warnOnConflict(ctx as unknown as StatusCtx);
		if (!ctx.hasUI) return;
		await refresh(ctx as unknown as StatusCtx, true);
		if (idleTimer) clearInterval(idleTimer);
		idleTimer = setInterval(() => {
			void refresh(ctx as unknown as StatusCtx, true);
		}, IDLE_REFRESH_MS);
		idleTimer.unref?.();
	});

	pi.on("model_select", async (event, ctx) => {
		const statusCtx = ctx as unknown as StatusCtx;
		if (!isOAuthAnthropic(statusCtx, event.model)) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			return;
		}
		await refresh(statusCtx, true);
	});

	pi.on("after_provider_response", async (event, ctx) => {
		const statusCtx = ctx as unknown as StatusCtx;
		if (!isOAuthAnthropic(statusCtx)) return;
		if (event.status === 401 || event.status === 403) {
			loginNeeded = true;
			render(statusCtx);
			return;
		}
		const nowBilling = event.headers[OVERAGE_HEADER] === "true";
		if (nowBilling && !alarm) {
			ctx.ui.notify(
				"Claude request was billed to EXTRA USAGE, not your subscription — the Claude Code spoof may be broken.",
				"warning",
			);
		}
		alarm = nowBilling;
		if (event.status === 400) {
			// The connector's failure signature: Anthropic rejected the request
			// outright (e.g. "out of extra usage" after misclassification).
			if (providerErrorStatus === undefined) {
				ctx.ui.notify(
					"Claude request failed (HTTP 400). If this repeats, subscription billing may be broken — see the 🧠 status.",
					"error",
				);
			}
			providerErrorStatus = 400;
		} else if (event.status < 400) {
			providerErrorStatus = undefined; // healthy again
			loginNeeded = false;
		}
		await refresh(statusCtx);
	});

	pi.on("session_shutdown", async () => {
		if (idleTimer) clearInterval(idleTimer);
		idleTimer = undefined;
	});
}
