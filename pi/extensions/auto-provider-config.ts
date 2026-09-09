/**
 * Auto Provider Configuration
 * 
 * Automatically configures models based on the currently authenticated provider.
 * Runs on session start to ensure settings.json and agent models match the provider.
 * 
 * - GitHub Copilot → Uses gemini-3.8-flash (scout), claude-sonnet-5, claude-opus-5
 * - Anthropic → Uses claude-haiku-4-5 (scout), claude-sonnet-4-5
 * 
 * This eliminates the need to manually run switch-agents.sh after authentication.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const AGENT_DIR = join(homedir(), ".pi", "agent");
const AUTH_FILE = join(AGENT_DIR, "auth.json");
const SETTINGS_FILE = join(AGENT_DIR, "settings.json");

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		try {
			// Detect current provider from auth.json
			const provider = detectProvider();
			if (!provider) {
				return; // No auth yet, skip
			}

			// Check if settings.json needs updating
			const currentSettings = readSettings();
			if (!currentSettings) {
				return; // Can't read settings
			}

			// If provider matches current settings, no action needed
			if (currentSettings.defaultProvider === provider) {
				return;
			}

			// Provider mismatch - update settings
			ctx.ui.notify(`Detected ${provider} provider, updating configuration...`, "info");
			
			updateSettings(provider);
			updateAgents(provider);

			ctx.ui.notify(`✓ Configured for ${provider}. Run /reload to apply changes.`, "success");
			
		} catch (error) {
			// Silently fail - don't break session startup
			console.error("auto-provider-config error:", error);
		}
	});
}

function detectProvider(): string | null {
	if (!existsSync(AUTH_FILE)) {
		return null;
	}

	try {
		const authContent = readFileSync(AUTH_FILE, "utf-8");
		if (authContent.includes('"github-copilot"')) {
			return "github-copilot";
		} else if (authContent.includes('"anthropic"')) {
			return "anthropic";
		}
	} catch {
		return null;
	}

	return null;
}

function readSettings(): any | null {
	if (!existsSync(SETTINGS_FILE)) {
		return null;
	}

	try {
		return JSON.parse(readFileSync(SETTINGS_FILE, "utf-8"));
	} catch {
		return null;
	}
}

function updateSettings(provider: string) {
	const settingsPath = SETTINGS_FILE;

	let settings: any;
	try {
		settings = JSON.parse(readFileSync(settingsPath, "utf-8"));
	} catch {
		settings = {};
	}

	if (provider === "github-copilot") {
		settings.defaultProvider = "github-copilot";
		settings.defaultModel = "claude-sonnet-5";
		settings.modelThinkingLevels = {
			"github-copilot/claude-opus-5": "high",
			"github-copilot/claude-sonnet-5": "medium",
			"github-copilot/gemini-3.8-flash": "minimal",
		};
		settings.enabledModels = [
			"github-copilot/claude-sonnet-5",
			"github-copilot/claude-opus-5",
			"github-copilot/gemini-3.8-flash",
		];
	} else if (provider === "anthropic") {
		settings.defaultProvider = "anthropic";
		settings.defaultModel = "claude-sonnet-4-5";
		settings.modelThinkingLevels = {
			"anthropic/claude-opus-4-8": "high",
			"anthropic/claude-sonnet-4-5": "medium",
			"anthropic/claude-haiku-4-5": "minimal",
		};
		settings.enabledModels = [
			"anthropic/claude-sonnet-4-5",
			"anthropic/claude-opus-4-8",
			"anthropic/claude-haiku-4-5",
		];
	}

	writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
}

function updateAgents(provider: string) {
	const agentsDir = join(AGENT_DIR, "agents");

	const agentConfigs = {
		"github-copilot": {
			scout: "gemini-3.8-flash",
			planner: "claude-sonnet-5",
			worker: "claude-sonnet-5",
			reviewer: "claude-opus-5",
		},
		anthropic: {
			scout: "claude-haiku-4-5",
			planner: "claude-sonnet-4-5",
			worker: "claude-sonnet-4-5",
			reviewer: "claude-sonnet-4-5",
		},
	};

	const models = agentConfigs[provider as keyof typeof agentConfigs];
	if (!models) return;

	for (const [agent, model] of Object.entries(models)) {
		const agentFile = join(agentsDir, `${agent}.md`);
		if (!existsSync(agentFile)) continue;

		try {
			let content = readFileSync(agentFile, "utf-8");
			// Replace model: line in frontmatter
			content = content.replace(/^model: .+$/m, `model: ${model}`);
			writeFileSync(agentFile, content);
		} catch {
			// Skip if can't update
		}
	}
}
