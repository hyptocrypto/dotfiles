#!/usr/bin/env bash
# Symlink the pi (coding agent) config from this dotfiles repo into ~/.pi/agent.
# Safe to re-run: it backs up any existing non-symlink target once, then relinks.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

mkdir -p "$PI_DIR"

link() {
	local src="$1" dst="$2"
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		mv "$dst" "$dst.bak.$(date +%s)"
		echo "backed up existing $dst"
	fi
	ln -sfn "$src" "$dst"
	echo "linked $dst -> $src"
}

# Files
link "$REPO_DIR/settings.json"    "$PI_DIR/settings.json"
link "$REPO_DIR/keybindings.json" "$PI_DIR/keybindings.json"
link "$REPO_DIR/AGENTS.md"        "$PI_DIR/AGENTS.md"

# Resource directories (auto-discovered by pi)
link "$REPO_DIR/themes"     "$PI_DIR/themes"
link "$REPO_DIR/extensions" "$PI_DIR/extensions"
link "$REPO_DIR/agents"     "$PI_DIR/agents"
link "$REPO_DIR/prompts"    "$PI_DIR/prompts"

echo
echo "Done. Start pi and run /reload (or restart) to apply."
echo "Note: install language tooling as needed on this device:"
echo "  go: gopls  |  py: ruff  |  ts/vue: typescript-language-server @vue/language-server vue-tsc  |  bash: shellcheck"
