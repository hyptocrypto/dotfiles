#!/usr/bin/env bash
# Install and configure LeanCTX for pi
set -euo pipefail

echo "🚀 Setting up LeanCTX for Pi..."
echo ""

# Check if lean-ctx is already installed
if ! command -v lean-ctx &>/dev/null; then
    echo "📦 Installing LeanCTX..."
    if curl -fsSL https://leanctx.com/install.sh | sh; then
        echo "✓ LeanCTX installed"
    else
        echo "❌ Installation failed"
        exit 1
    fi
else
    echo "✓ LeanCTX already installed ($(lean-ctx --version 2>/dev/null || echo 'version unknown'))"
fi

# Auto-configure for pi
echo ""
echo "⚙️  Auto-configuring for pi..."
if lean-ctx init --agent pi; then
    echo "✓ Pi integration configured"
else
    echo "❌ Configuration failed"
    exit 1
fi

# Apply aggressive compression and replace mode
echo ""
echo "🔧 Applying recommended settings..."
CONFIG_FILE="$HOME/.pi/agent/npm/node_modules/pi-lean-ctx/config.json"

if [ -f "$CONFIG_FILE" ]; then
    if command -v jq &>/dev/null; then
        TMP=$(mktemp)
        jq '.env.LEAN_CTX_COMPRESSION_LEVEL = "aggressive" | .env.LEAN_CTX_PI_MODE = "replace"' "$CONFIG_FILE" >"$TMP" && mv "$TMP" "$CONFIG_FILE"
        echo "✓ Configuration updated (aggressive compression + replace mode)"
    else
        echo "⚠️  jq not found - manually edit $CONFIG_FILE to set:"
        echo "    LEAN_CTX_COMPRESSION_LEVEL: aggressive"
        echo "    LEAN_CTX_PI_MODE: replace"
    fi
else
    echo "⚠️  Config file not found - settings will apply on first pi run"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart pi to load configuration"
echo "  2. Check savings: lean-ctx gain"
echo ""
echo "Configuration: aggressive compression + replace mode (40-95% token savings)"
