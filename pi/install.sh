#!/usr/bin/env bash
# Install/update pi (coding agent) config from this repo into ~/.pi/agent.
# Idempotent: produces the same ~/.pi/agent state whether run against an
# empty directory or an existing one, and safe to re-run at any time.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

if [ "${1:-}" = "--clean" ]; then
    echo "Removing $PI_DIR"
    rm -rf "$PI_DIR"
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install it and re-run." >&2
    exit 1
fi

mkdir -p "$PI_DIR"

copy_file() {
    local src="$1" dst="$2"
    [ -L "$dst" ] && rm "$dst"
    if [ -f "$dst" ] && [ ! -f "$dst.bak" ]; then
        cp "$dst" "$dst.bak"
    fi
    cp "$src" "$dst"
}

copy_dir() {
    local src="$1" dst="$2"
    rm -rf "$dst"
    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/
}

set_agent_model() {
    # Replace the `model:` frontmatter line in a copied agents/*.md file.
    sed -i.tmp "s/^model: .*/model: $2/" "$PI_DIR/agents/$1.md"
    rm -f "$PI_DIR/agents/$1.md.tmp"
}

echo "Copying config to $PI_DIR..."
copy_file "$REPO_DIR/settings.json" "$PI_DIR/settings.json"
copy_file "$REPO_DIR/keybindings.json" "$PI_DIR/keybindings.json"
copy_file "$REPO_DIR/AGENTS.md" "$PI_DIR/AGENTS.md"
copy_dir "$REPO_DIR/themes" "$PI_DIR/themes"
copy_dir "$REPO_DIR/extensions" "$PI_DIR/extensions"
copy_dir "$REPO_DIR/prompts" "$PI_DIR/prompts"
copy_dir "$REPO_DIR/agents" "$PI_DIR/agents"

echo "Setting up LeanCTX..."
if ! command -v lean-ctx &>/dev/null; then
    curl -fsSL https://leanctx.com/install.sh | sh
fi
lean-ctx init --agent pi --global >/dev/null
LEANCTX_CONFIG="$PI_DIR/extensions/pi-lean-ctx/config.json"
mkdir -p "$(dirname "$LEANCTX_CONFIG")"
copy_file "$REPO_DIR/leanctx-config-template.json" "$LEANCTX_CONFIG"

PERM_CONFIG="$PI_DIR/extensions/pi-permission-system/config.json"
mkdir -p "$(dirname "$PERM_CONFIG")"
copy_file "$REPO_DIR/permission-system-config-template.json" "$PERM_CONFIG"

PACKAGES=(
    "@gotgenes/pi-anthropic-auth"
    "@zigai/pi-prompt-history"
    "pi-web-access"
    "@juicesharp/rpiv-ask-user-question"
    "pi-goal-x"
    "@narumitw/pi-usage"
    "pi-git-status-line"
    "pi-background-tasks"
    "@gotgenes/pi-permission-system"
    "@juicesharp/rpiv-todo"
    "@narumitw/pi-btw"
)
if command -v pi &>/dev/null; then
    echo "Installing packages..."
    for pkg in "${PACKAGES[@]}"; do
        pi install "npm:$pkg" >/dev/null && echo "  ✓ $pkg"
    done
else
    echo "pi not found on PATH - install it, then run:"
    for pkg in "${PACKAGES[@]}"; do
        echo "  pi install npm:$pkg"
    done
fi

echo "Configuring agent models for your provider..."
AUTH_FILE="$PI_DIR/auth.json"
if [ ! -f "$AUTH_FILE" ]; then
    echo "  No auth.json yet - run 'pi', then /login, then re-run ./install.sh."
elif grep -q '"github-copilot"' "$AUTH_FILE" 2>/dev/null; then
    jq '.defaultProvider = "github-copilot"
      | .defaultModel = "claude-sonnet-5"
      | .modelThinkingLevels = {
          "github-copilot/claude-opus-5": "high",
          "github-copilot/claude-sonnet-5": "medium",
          "github-copilot/gemini-3.8-flash": "minimal"
        }
      | .enabledModels = [
          "github-copilot/claude-sonnet-5",
          "github-copilot/claude-opus-5",
          "github-copilot/gemini-3.8-flash"
        ]' "$PI_DIR/settings.json" >"$PI_DIR/settings.json.tmp" && mv "$PI_DIR/settings.json.tmp" "$PI_DIR/settings.json"
    set_agent_model scout gemini-3.8-flash
    set_agent_model planner claude-sonnet-5
    set_agent_model worker claude-sonnet-5
    set_agent_model reviewer claude-opus-5
    echo "  ✓ GitHub Copilot: scout=gemini-3.8-flash, planner/worker=claude-sonnet-5, reviewer=claude-opus-5"
elif grep -q '"anthropic"' "$AUTH_FILE" 2>/dev/null; then
    echo "  ✓ Anthropic: repo defaults already match (scout=claude-haiku-4-5, planner/worker/reviewer=claude-sonnet-4-5)"
else
    echo "  Could not detect provider from auth.json - keeping repo defaults (Anthropic models)."
fi

echo
echo "Done. Restart pi: /quit then pi"
