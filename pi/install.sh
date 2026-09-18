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
copy_file "$REPO_DIR/settings.json" "$PI_DIR/settings.json"
copy_file "$REPO_DIR/keybindings.json" "$PI_DIR/keybindings.json"
copy_file "$REPO_DIR/AGENTS.md" "$PI_DIR/AGENTS.md"

# Copy directories
copy_dir "$REPO_DIR/themes" "$PI_DIR/themes"
copy_dir "$REPO_DIR/extensions" "$PI_DIR/extensions"
copy_dir "$REPO_DIR/prompts" "$PI_DIR/prompts"
copy_dir "$REPO_DIR/agents" "$PI_DIR/agents"

# Optional: Install LeanCTX
if ! command -v lean-ctx &>/dev/null; then
    echo
    read -p "Install LeanCTX for automatic token compression? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$REPO_DIR/setup-leanctx.sh"
    fi
else
    echo
    echo "LeanCTX already installed (lean-ctx $(lean-ctx --version 2>/dev/null || echo 'version unknown'))"
    # Ensure aggressive compression and replace mode are set
    CONFIG_FILE="$PI_DIR/extensions/pi-lean-ctx/config.json"
    TEMPLATE_FILE="$REPO_DIR/leanctx-config-template.json"
    if [ -f "$CONFIG_FILE" ]; then
        NEEDS_UPDATE=false
        if ! grep -q '"LEAN_CTX_COMPRESSION_LEVEL": "aggressive"' "$CONFIG_FILE"; then
            NEEDS_UPDATE=true
        fi
        if ! grep -q '"LEAN_CTX_PI_MODE": "replace"' "$CONFIG_FILE"; then
            NEEDS_UPDATE=true
        fi
        
        if [ "$NEEDS_UPDATE" = true ] && [ -f "$TEMPLATE_FILE" ]; then
            echo "  Updating LeanCTX config to recommended settings..."
            cp "$TEMPLATE_FILE" "$CONFIG_FILE"
            echo "  ✓ Config updated (aggressive compression + replace mode)"
        fi
    fi
fi

# Install recommended extensions from npm
echo
echo "📦 Installing recommended extensions..."
if command -v pi &>/dev/null; then
    pi install npm:@juicesharp/rpiv-todo && echo "  ✓ todo extension installed"
    pi install npm:@narumitw/pi-btw && echo "  ✓ btw extension installed"
else
    echo "  ⚠️  pi not found - install extensions manually:"
    echo "      pi install npm:@juicesharp/rpiv-todo"
    echo "      pi install npm:@narumitw/pi-btw"
fi

echo
echo "Done! Config copied to ~/.pi/agent/"
echo
echo "Next steps:"
echo "  1. Run: pi"
echo "  2. Login: /login (choose your provider)"
echo "  3. Run: cd $REPO_DIR && ./switch-agents.sh"
echo "  4. Restart: /quit then pi"
echo
echo "The switch-agents.sh script configures models for your provider:"
echo "  - GitHub Copilot → gemini-3.8-flash (scout), claude-sonnet-5, claude-opus-5"
echo "  - Anthropic → claude-haiku-4-5 (scout), claude-sonnet-4-5"
echo
echo "Installed extensions: @juicesharp/rpiv-todo, @narumitw/pi-btw"
echo "Custom extensions: branch-context, review, model-enhanced, protected-paths, auto-provider-config"
echo
echo "To update from repo later: re-run this script (./install.sh)"
