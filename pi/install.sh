#!/usr/bin/env bash
# Copy pi (coding agent) config from this dotfiles repo into ~/.pi/agent.
# Safe to re-run: overwrites files to update from repo templates.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

# Option to force clean install
if [ "${1:-}" = "--clean" ]; then
    echo "🗑️  Clean install requested - removing $PI_DIR"
    rm -rf "$PI_DIR"
    echo "  ✓ Removed"
    echo
fi

echo "🧹 Preparing pi directory..."
echo

# Create directory
mkdir -p "$PI_DIR"

# Clean up old conflicting extensions BEFORE copying
if [ -d "$PI_DIR/extensions" ]; then
    echo "Removing old conflicting extensions..."
    rm -rf "$PI_DIR/extensions/web" 2>/dev/null || true
    rm -rf "$PI_DIR/extensions/subagent" 2>/dev/null || true
    rm -f "$PI_DIR/extensions/question.ts" 2>/dev/null || true
    echo "  ✓ Conflicts cleaned (replaced with npm packages)"
    echo
fi

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

# Clean and copy directories (remove old contents first)
rm -rf "$PI_DIR/themes" && copy_dir "$REPO_DIR/themes" "$PI_DIR/themes"
rm -rf "$PI_DIR/extensions" && copy_dir "$REPO_DIR/extensions" "$PI_DIR/extensions"
rm -rf "$PI_DIR/prompts" && copy_dir "$REPO_DIR/prompts" "$PI_DIR/prompts"
rm -rf "$PI_DIR/agents" && copy_dir "$REPO_DIR/agents" "$PI_DIR/agents"

# Clean up conflicting extensions AGAIN after copy (in case repo still has them)
echo
echo "Ensuring no conflicts with npm packages..."
rm -rf "$PI_DIR/extensions/web" 2>/dev/null || true
rm -rf "$PI_DIR/extensions/subagent" 2>/dev/null || true
rm -f "$PI_DIR/extensions/question.ts" 2>/dev/null || true
echo "  ✓ Conflict check complete"
echo

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
    CONFIG_FILE="$PI_DIR/npm/node_modules/pi-lean-ctx/config.json"
    TEMPLATE_FILE="$REPO_DIR/leanctx-config-template.json"
    if [ ! -f "$CONFIG_FILE" ] && [ -f "$TEMPLATE_FILE" ]; then
        echo "  Creating LeanCTX config (aggressive compression + replace mode)..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cp "$TEMPLATE_FILE" "$CONFIG_FILE"
        echo "  ✓ Config created"
    elif [ -f "$CONFIG_FILE" ]; then
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
    pi install npm:@gotgenes/pi-anthropic-auth && echo "  ✓ anthropic auth extension installed"
    pi install npm:@zigai/pi-prompt-history && echo "  ✓ prompt history extension installed"
    pi install npm:pi-web-access && echo "  ✓ web access extension installed"
    pi install npm:@juicesharp/rpiv-ask-user-question && echo "  ✓ question extension installed"
    pi install npm:pi-subagents && echo "  ✓ subagents extension installed"
    pi install npm:pi-goal-x && echo "  ✓ goal extension installed"
    pi install npm:@narumitw/pi-usage && echo "  ✓ usage extension installed"
    pi install npm:pi-git-status-line && echo "  ✓ git status line extension installed"
    pi install npm:pi-background-tasks && echo "  ✓ background tasks extension installed"
    pi install npm:@gotgenes/pi-permission-system && echo "  ✓ permission system extension installed"
    pi install npm:@juicesharp/rpiv-todo && echo "  ✓ todo extension installed"
    pi install npm:@narumitw/pi-btw && echo "  ✓ btw extension installed"
else
    echo "  ⚠️  pi not found - install extensions manually:"
    echo "      pi install npm:@gotgenes/pi-anthropic-auth"
    echo "      pi install npm:@zigai/pi-prompt-history"
    echo "      pi install npm:pi-web-access"
    echo "      pi install npm:@juicesharp/rpiv-ask-user-question"
    echo "      pi install npm:pi-subagents"
    echo "      pi install npm:pi-goal-x"
    echo "      pi install npm:@narumitw/pi-usage"
    echo "      pi install npm:pi-git-status-line"
    echo "      pi install npm:pi-background-tasks"
    echo "      pi install npm:@gotgenes/pi-permission-system"
    echo "      pi install npm:@juicesharp/rpiv-todo"
    echo "      pi install npm:@narumitw/pi-btw"
fi

# Final verification
echo
echo "🔍 Verifying installation..."
echo

# Check that conflicting extensions are gone
if [ -d "$PI_DIR/extensions/web" ] || [ -d "$PI_DIR/extensions/subagent" ] || [ -f "$PI_DIR/extensions/question.ts" ]; then
    echo "⚠️  WARNING: Conflicting extensions still present!"
    echo "  This may cause pi to fail on startup."
    echo "  Please report this issue."
    echo
else
    echo "  ✓ No conflicting extensions"
fi

# Check that packages are in settings.json
if grep -q '"packages"' "$PI_DIR/settings.json"; then
    echo "  ✓ Package list found in settings.json"
else
    echo "⚠️  WARNING: No packages list in settings.json!"
fi

echo
echo "✅ Installation complete!"
echo
echo "=" "=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""="
echo "IMPORTANT: How to Start Pi"
echo "=" "=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""="
echo
echo "1. If pi is running, quit it first:"
echo "     /quit"
echo
echo "2. Start pi:"
echo "     pi"
echo
echo "3. If this is your first time, login:"
echo "     /login"
echo
echo "4. (Optional) Configure agent models for your provider:"
echo "     cd $REPO_DIR && ./switch-agents.sh"
echo "     Then: /quit and restart pi"
echo
echo "=" "=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""="
echo "Installed Packages (12)"
echo "=" "=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""="
echo
echo "Core:"
echo "  • @gotgenes/pi-anthropic-auth - Anthropic authentication"
echo "  • @zigai/pi-prompt-history - Up/down arrow history (persisted)"
echo "  • pi-web-access - Web search, GitHub, PDF, YouTube"
echo "  • @juicesharp/rpiv-ask-user-question - Multi-question dialogs"
echo "  • pi-subagents - Official subagent orchestration"
echo "  • pi-goal-x - Goal tracking (/goal)"
echo "  • @narumitw/pi-usage - Usage/cost tracking"
echo "  • pi-git-status-line - Git status in the footer"
echo "  • pi-background-tasks - Background jobs"
echo "  • @gotgenes/pi-permission-system - Permissions"
echo
echo "Utilities:"
echo "  • @juicesharp/rpiv-todo - Todo list (/todos)"
echo "  • @narumitw/pi-btw - Quick questions (/btw)"
echo
echo "Custom Extensions (8):"
echo "  • modal-editor - Vim-style modal prompt editor (jk -> NORMAL)"
echo "  • branch-context - Auto-compressed branch context"
echo "  • review - Local PR review (/review)"
echo "  • model-enhanced - Enhanced model picker (/m)"
echo "  • plan-mode - Read-only exploration (/plan)"
echo "  • confirm-destructive - Session confirmations"
echo "  • git-checkpoint - Auto-checkpoint"
echo "  • protected-paths - Path blocking"
echo
echo "=" "=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""="
echo "Troubleshooting"
echo "=" "=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""=""="
echo
echo "If pi fails to start:"
echo "  1. Check for errors in startup output"
echo "  2. Try: pi -ne (start without extensions)"
echo "  3. See: cat $REPO_DIR/README.md"
echo
echo "If modal editing not working:"
echo "  - Press Escape or type 'jk' quickly in insert mode to switch to NORMAL"
echo "  - Press 'i' (or a/A/o/O) to go back to insert mode"
echo
echo "To update later: re-run ./install.sh"
