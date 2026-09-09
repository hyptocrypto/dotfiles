/**
 * BTW (By The Way) Command - Quick one-off questions
 *
 * Ask a cheap model a quick question without interrupting your current session.
 * Auto-selects cheapest model based on provider:
 * - Claude: haiku-4-5
 * - Copilot: gemini-3.8-flash
 * - Other: falls back to haiku or current model
 *
 * Usage: /btw <question>
 * Example: /btw what is the capital of France?
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TIMEOUT_MS = 30000; // 30 seconds
const MAX_RESPONSE_LENGTH = 500; // Truncate long responses in notification

// Model selection by provider
const CHEAP_MODELS: Record<string, string> = {
	anthropic: "claude-haiku-4-5",
	"github-copilot": "gemini-3.8-flash",
};

export default function (pi: ExtensionAPI) {
	pi.registerCommand("btw", {
		description: "Ask a quick question to a cheap model (non-blocking)",
		handler: async (args, ctx) => {
			if (!args || args.trim() === "") {
				ctx.ui.notify("Usage: /btw <question>", "warning");
				return;
			}

			const question = args.trim();

			// Detect provider and select cheapest model
			const provider = ctx.model?.provider || "anthropic";
			const cheapModel = CHEAP_MODELS[provider] || "claude-haiku-4-5";

			// Show thinking notification
			ctx.ui.notify(`🤔 Asking ${cheapModel.split("-")[0]}...`, "info");

			try {
				const answer = await askQuestion(question, cheapModel);
				const truncated = answer.length > MAX_RESPONSE_LENGTH 
					? answer.substring(0, MAX_RESPONSE_LENGTH) + "..." 
					: answer;
				
				ctx.ui.notify(`💡 ${truncated}`, "success");
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`❌ BTW failed: ${message}`, "error");
			}
		},
	});
}

/**
 * Ask a question to a model using a subprocess
 */
async function askQuestion(question: string, model: string): Promise<string> {
	return new Promise((resolve, reject) => {
		const args = ["--model", model, "--print", "--", question];
		
		const child = spawn("pi", args, {
			stdio: ["ignore", "pipe", "pipe"],
			timeout: TIMEOUT_MS,
		});

		let stdout = "";
		let stderr = "";

		child.stdout?.on("data", (data) => {
			stdout += data.toString();
		});

		child.stderr?.on("data", (data) => {
			stderr += data.toString();
		});

		child.on("error", (error) => {
			reject(new Error(`Failed to spawn pi: ${error.message}`));
		});

		child.on("close", (code) => {
			if (code === 0) {
				const answer = stdout.trim();
				if (answer) {
					resolve(answer);
				} else {
					reject(new Error("No response from model"));
				}
			} else {
				reject(new Error(stderr || `Process exited with code ${code}`));
			}
		});

		// Timeout handling
		setTimeout(() => {
			if (!child.killed) {
				child.kill();
				reject(new Error("Request timed out"));
			}
		}, TIMEOUT_MS);
	});
}
