#!/usr/bin/env node
/**
 * Update settings.json with provider-specific model configuration
 * Preserves all other settings (packages, compaction, retry, etc.)
 * 
 * Usage: node update-settings.js <provider>
 * Where provider is: github-copilot | anthropic
 */

const fs = require('fs');
const path = require('path');

const SETTINGS_FILE = path.join(process.env.HOME || process.env.USERPROFILE, '.pi', 'agent', 'settings.json');

const PROVIDER_CONFIGS = {
	'github-copilot': {
		defaultProvider: 'github-copilot',
		defaultModel: 'claude-sonnet-5',
		modelThinkingLevels: {
			'github-copilot/claude-opus-5': 'high',
			'github-copilot/claude-sonnet-5': 'medium',
			'github-copilot/gemini-3.8-flash': 'minimal',
		},
		enabledModels: [
			'github-copilot/claude-sonnet-5',
			'github-copilot/claude-opus-5',
			'github-copilot/gemini-3.8-flash',
		],
	},
	'anthropic': {
		defaultProvider: 'anthropic',
		defaultModel: 'claude-sonnet-4-5',
		modelThinkingLevels: {
			'anthropic/claude-opus-4-8': 'high',
			'anthropic/claude-sonnet-4-5': 'medium',
			'anthropic/claude-haiku-4-5': 'minimal',
		},
		enabledModels: [
			'anthropic/claude-sonnet-4-5',
			'anthropic/claude-opus-4-8',
			'anthropic/claude-haiku-4-5',
		],
	},
};

function main() {
	const provider = process.argv[2];
	
	if (!provider || !PROVIDER_CONFIGS[provider]) {
		console.error(`Usage: node update-settings.js <provider>`);
		console.error(`Where provider is: ${Object.keys(PROVIDER_CONFIGS).join(' | ')}`);
		process.exit(1);
	}

	// Read existing settings
	let settings = {};
	if (fs.existsSync(SETTINGS_FILE)) {
		try {
			settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf-8'));
		} catch (error) {
			console.error(`Warning: Could not parse existing settings.json, creating new one`);
			settings = {};
		}
	}

	// Merge provider config (only update model-related fields)
	const providerConfig = PROVIDER_CONFIGS[provider];
	settings.defaultProvider = providerConfig.defaultProvider;
	settings.defaultModel = providerConfig.defaultModel;
	settings.modelThinkingLevels = providerConfig.modelThinkingLevels;
	settings.enabledModels = providerConfig.enabledModels;

	// Write back
	fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2));
	console.log(`✓ Updated settings.json for ${provider}`);
}

main();
