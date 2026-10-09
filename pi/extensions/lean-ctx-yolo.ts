/**
 * Lean-CTX Yolo Mode (Session-Scoped)
 *
 * /lean-ctx-yolo - Temporarily disable lean-ctx shell gating for this Pi session
 * /lean-ctx-secure - Re-enable shell gating for this session
 *
 * Changes are session-only and automatically revert when Pi exits.
 * Sets LEAN_CTX_SHELL_SECURITY=off and LEAN_CTX_SHELL_ALLOWLIST=* at runtime.
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

export default function (pi: ExtensionAPI) {
	const configPath = path.join(
		os.homedir(),
		".pi",
		"agent",
		"extensions",
		"pi-lean-ctx",
		"config.json",
	);
	let originalAllowlist: string | undefined;
	let originalSecurity: string | undefined;
	let yoloActive = false;

	async function readConfig(): Promise<any> {
		const content = await fs.promises.readFile(configPath, "utf-8");
		return JSON.parse(content);
	}

	async function writeConfig(config: any): Promise<void> {
		await fs.promises.writeFile(configPath, JSON.stringify(config, null, 2), "utf-8");
	}

	async function enableYolo(ctx: ExtensionCommandContext): Promise<void> {
		if (yoloActive) {
			ctx.ui.notify("Yolo mode already active", "info");
			return;
		}

		try {
			// Store original env vars
			originalAllowlist = process.env.LEAN_CTX_SHELL_ALLOWLIST;
			originalSecurity = process.env.LEAN_CTX_SHELL_SECURITY;

			// Set runtime env vars (checked by lean-ctx at execution time)
			process.env.LEAN_CTX_SHELL_SECURITY = "off";
			process.env.LEAN_CTX_SHELL_ALLOWLIST = "*";

			// Also update config file for persistence across tool calls
			const config = await readConfig();
			if (!config.env) config.env = {};
			config.env.LEAN_CTX_SHELL_ALLOWLIST = "*";
			await writeConfig(config);

			yoloActive = true;

			ctx.ui.notify(
				"🔓 Shell gating disabled for this session (reverts on exit)",
				"success",
			);
		} catch (error) {
			ctx.ui.notify(`Failed to enable yolo mode: ${error}`, "error");
		}
	}

	async function disableYolo(ctx: ExtensionCommandContext): Promise<void> {
		if (!yoloActive) {
			ctx.ui.notify("Yolo mode not active in this session", "warning");
			return;
		}

		try {
			// Restore env vars
			if (originalAllowlist !== undefined) {
				process.env.LEAN_CTX_SHELL_ALLOWLIST = originalAllowlist;
			} else {
				delete process.env.LEAN_CTX_SHELL_ALLOWLIST;
			}

			if (originalSecurity !== undefined) {
				process.env.LEAN_CTX_SHELL_SECURITY = originalSecurity;
			} else {
				delete process.env.LEAN_CTX_SHELL_SECURITY;
			}

			// Restore config file
			const config = await readConfig();
			if (originalAllowlist !== undefined) {
				config.env.LEAN_CTX_SHELL_ALLOWLIST = originalAllowlist;
			} else if (config.env) {
				delete config.env.LEAN_CTX_SHELL_ALLOWLIST;
			}
			await writeConfig(config);

			yoloActive = false;

			ctx.ui.notify("🔒 Shell gating re-enabled", "success");
		} catch (error) {
			ctx.ui.notify(`Failed to restore secure mode: ${error}`, "error");
		}
	}

	async function restoreOnExit(): Promise<void> {
		if (!yoloActive) return;

		try {
			// Restore env vars
			if (originalAllowlist !== undefined) {
				process.env.LEAN_CTX_SHELL_ALLOWLIST = originalAllowlist;
			} else {
				delete process.env.LEAN_CTX_SHELL_ALLOWLIST;
			}

			if (originalSecurity !== undefined) {
				process.env.LEAN_CTX_SHELL_SECURITY = originalSecurity;
			} else {
				delete process.env.LEAN_CTX_SHELL_SECURITY;
			}

			// Restore config file
			const config = await readConfig();
			if (originalAllowlist !== undefined) {
				config.env.LEAN_CTX_SHELL_ALLOWLIST = originalAllowlist;
			} else if (config.env) {
				delete config.env.LEAN_CTX_SHELL_ALLOWLIST;
			}
			await writeConfig(config);

			yoloActive = false;
		} catch (error) {
			console.error("Failed to restore lean-ctx config on exit:", error);
		}
	}

	// Register commands
	pi.registerCommand("lean-ctx-yolo", {
		description: "Disable lean-ctx shell gating for this session (reverts on exit)",
		handler: async (_args, ctx) => {
			await enableYolo(ctx);
		},
	});

	pi.registerCommand("lean-ctx-secure", {
		description: "Re-enable lean-ctx shell gating for this session",
		handler: async (_args, ctx) => {
			await disableYolo(ctx);
		},
	});

	// Restore original allowlist when agent exits
	pi.on("agent_exit", async () => {
		await restoreOnExit();
	});

	// Also restore on session end (belt and suspenders)
	pi.on("session_end", async () => {
		await restoreOnExit();
	});

	// Handle SIGTERM/SIGINT for non-graceful shutdowns
	const signalHandler = () => {
		if (!yoloActive) return;

		try {
			// Restore env vars (sync)
			if (originalAllowlist !== undefined) {
				process.env.LEAN_CTX_SHELL_ALLOWLIST = originalAllowlist;
			} else {
				delete process.env.LEAN_CTX_SHELL_ALLOWLIST;
			}

			if (originalSecurity !== undefined) {
				process.env.LEAN_CTX_SHELL_SECURITY = originalSecurity;
			} else {
				delete process.env.LEAN_CTX_SHELL_SECURITY;
			}

			// Restore config file (sync)
			const config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
			if (originalAllowlist !== undefined) {
				config.env.LEAN_CTX_SHELL_ALLOWLIST = originalAllowlist;
			} else if (config.env) {
				delete config.env.LEAN_CTX_SHELL_ALLOWLIST;
			}
			fs.writeFileSync(configPath, JSON.stringify(config, null, 2), "utf-8");

			yoloActive = false;
		} catch (error) {
			console.error("Failed to restore lean-ctx config on signal:", error);
		}
	};

	process.on("SIGTERM", signalHandler);
	process.on("SIGINT", signalHandler);
}
