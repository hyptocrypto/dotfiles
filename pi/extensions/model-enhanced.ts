/**
 * Enhanced Model Picker
 *
 * Provides /m command as an enhanced model picker with:
 * - Available models from the registry
 * - Cost information per million tokens
 * - Interactive thinking level selection
 * - Proper model switching
 * 
 * Use /m instead of /model for the enhanced experience.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const THINKING_LEVELS = [
	{ value: "off", label: "Off - No extended reasoning" },
	{ value: "minimal", label: "Minimal - Quick tasks" },
	{ value: "low", label: "Low - Simple problems" },
	{ value: "medium", label: "Medium - Balanced (recommended)" },
	{ value: "high", label: "High - Complex reasoning" },
	{ value: "xhigh", label: "Extra High - Very difficult" },
	{ value: "max", label: "Max - Hardest problems" },
];

export default function (pi: ExtensionAPI) {
	// Primary enhanced model picker
	pi.registerCommand("m", {
		description: "Enhanced model picker (shows cost info, enables thinking level selection)",
		handler: async (_args, ctx) => {
			const allModels = ctx.modelRegistry.getAll();
			const currentModel = ctx.model;

			// Try to get enabled models from settings, otherwise show all
			let enabledModelIds: string[] = [];
			try {
				enabledModelIds = ctx.settings?.enabledModels || [];
			} catch (e) {
				// If settings not accessible, show all models
			}

			// Filter to enabled models if configured, otherwise show all from current provider
			let availableModels = allModels;
			
			if (enabledModelIds.length > 0) {
				availableModels = allModels.filter((model) => {
					const modelId = `${model.provider}/${model.id}`;
					return enabledModelIds.includes(modelId);
				});
			} else if (currentModel) {
				// If no enabled models, show all from current provider
				availableModels = allModels.filter((model) => model.provider === currentModel.provider);
			}

			if (availableModels.length === 0) {
				ctx.ui.notify("No models available. Try /model (built-in) instead.", "warning");
				return;
			}

			// Sort: current first, then by name
			const sortedModels = availableModels.sort((a, b) => {
				const aId = `${a.provider}/${a.id}`;
				const bId = `${b.provider}/${b.id}`;
				const aCurrent = currentModel && a.id === currentModel.id && a.provider === currentModel.provider;
				const bCurrent = currentModel && b.id === currentModel.id && b.provider === currentModel.provider;
				if (aCurrent && !bCurrent) return -1;
				if (!aCurrent && bCurrent) return 1;
				return aId.localeCompare(bId);
			});

			// Step 1: Select model with cost info
			const modelOptions = sortedModels.map((model) => {
				const modelId = `${model.provider}/${model.id}`;
				const isActive = currentModel && model.id === currentModel.id && model.provider === currentModel.provider;
				const marker = isActive ? "→ " : "  ";
				
				// Format cost info (compact)
				const costInfo = formatModelCostCompact(model);
				const costStr = costInfo ? ` ${costInfo}` : "";
				
				return `${marker}${modelId}${costStr}`;
			});

			const selectedModelStr = await ctx.ui.select(
				"Select model:",
				modelOptions
			);

			if (!selectedModelStr) {
				return; // User cancelled
			}

			// Extract selected model
			const selectedIndex = modelOptions.indexOf(selectedModelStr);
			const selectedModel = sortedModels[selectedIndex];

			// Step 2: Select thinking level (if model supports reasoning)
			let thinkingLevel: string | undefined;
			if (selectedModel.reasoning) {
				const currentThinkingLevel = pi.getThinkingLevel() || "medium";
				
				const thinkingOptions = THINKING_LEVELS.map((level) => {
					const isCurrent = level.value === currentThinkingLevel;
					const marker = isCurrent ? "→ " : "  ";
					return `${marker}${level.label}`;
				});

				const selectedThinkingStr = await ctx.ui.select(
					`Thinking level for ${selectedModel.id}:`,
					thinkingOptions
				);

				if (!selectedThinkingStr) {
					// User cancelled - don't change anything
					return;
				}

				// Extract thinking level value
				const thinkingIndex = thinkingOptions.indexOf(selectedThinkingStr);
				thinkingLevel = THINKING_LEVELS[thinkingIndex].value;
			}

			// Step 3: Switch to selected model
			try {
				const success = await pi.setModel(selectedModel);
				
				if (!success) {
					ctx.ui.notify(`Failed to switch to ${selectedModel.provider}/${selectedModel.id}. Check authentication.`, "error");
					return;
				}

				// Set thinking level if changed and model supports it
				if (thinkingLevel && selectedModel.reasoning) {
					pi.setThinkingLevel(thinkingLevel);
				}

				const modelId = `${selectedModel.provider}/${selectedModel.id}`;
				const thinkingStr = thinkingLevel ? ` (${thinkingLevel})` : "";
				ctx.ui.notify(`✓ Switched to ${modelId}${thinkingStr}`, "success");

			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Failed to switch model: ${message}`, "error");
			}
		},
	});

	// Alias: /pick for discoverability
	pi.registerCommand("pick", {
		description: "Pick a model (alias for /m)",
		handler: async (args, ctx) => {
			const mCommand = ctx.commands.get("m");
			if (mCommand) {
				await mCommand.handler(args, ctx);
			}
		},
	});
}

/**
 * Compact cost format for picker display
 * Examples: 
 * - "in:$3 out:$15/1M"
 * - "$0 (sub)"
 */
function formatModelCostCompact(model: any): string | null {
	if (!model.cost) return null;

	const { input, output } = model.cost;

	if (input === 0 && output === 0) {
		return "[$0 sub]";
	}

	// Clear format: in:$X out:$Y/1M
	const inStr = input >= 1 ? `$${Math.round(input)}` : `$${input.toFixed(2)}`;
	const outStr = output >= 1 ? `$${Math.round(output)}` : `$${output.toFixed(2)}`;
	
	return `[in:${inStr} out:${outStr}/1M]`;
}
