#!/usr/bin/env bash
# Copy pi (coding agent) config from this dotfiles repo into ~/.pi/agent.
# Safe to re-run: overwrites files to update from repo templates.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

mkdir -p "$PI_DIR"

copy_file() {
	local src="$1" dst="$2"
	# Remove old symlink if it exists
	[ -L "$dst" ] && rm "$dst"
	# Backup existing file on first install
	if [ -f "$dst" ] && [ ! -f "$dst.bak" ]; then
		cp "$dst" "$dst.bak"
		echo "backed up $dst -> $dst.bak"
	fi
	cp "$src" "$dst"
	echo "copied $dst"
}

copy_dir() {
	local src="$1" dst="$2"
	# Remove old symlink if it exists
	[ -L "$dst" ] && rm "$dst"
	# Create directory if it doesn't exist
	mkdir -p "$dst"
	# Copy all files from source to destination
	cp -r "$src"/* "$dst"/
	echo "copied $dst/"
}

echo "Copying pi config from repo to ~/.pi/agent..."
echo

# Copy individual files
copy_file "$REPO_DIR/settings.json"    "$PI_DIR/settings.json"
copy_file "$REPO_DIR/keybindings.json" "$PI_DIR/keybindings.json"
copy_file "$REPO_DIR/AGENTS.md"        "$PI_DIR/AGENTS.md"

# Copy directories
copy_dir "$REPO_DIR/themes"     "$PI_DIR/themes"
copy_dir "$REPO_DIR/extensions" "$PI_DIR/extensions"
copy_dir "$REPO_DIR/prompts"    "$PI_DIR/prompts"
copy_dir "$REPO_DIR/agents"     "$PI_DIR/agents"

echo
echo "Done! Config copied to ~/.pi/agent/"
echo
echo "Next steps:"
echo "  1. Run: pi"
echo "  2. Login: /login (choose your provider)"
echo "  3. Run: cd $REPO_DIR && ./switch-agents.sh"
echo "  4. Reload: /reload (in pi, if already running)"
echo
echo "To update from repo later: re-run this script (./install.sh)"
