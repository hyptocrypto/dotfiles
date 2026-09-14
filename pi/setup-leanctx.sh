#!/usr/bin/env bash
# Install and configure LeanCTX for pi with aggressive compression
set -euo pipefail

echo "🚀 Setting up LeanCTX for Pi..."
echo ""

# Check if lean-ctx is already installed
if command -v lean-ctx &>/dev/null; then
    echo "✓ LeanCTX already installed"
    LEAN_CTX_VERSION=$(lean-ctx --version 2>/dev/null || echo "unknown")
    echo "  Version: $LEAN_CTX_VERSION"
else
    echo "📦 Installing LeanCTX..."
    if curl -fsSL https://leanctx.com/install.sh | sh; then
        echo "✓ LeanCTX installed"
    else
        echo "❌ Installation failed"
        exit 1
    fi
fi

# Configure for pi
echo ""
echo "⚙️  Configuring for pi..."
if lean-ctx init --agent pi; then
    echo "✓ Pi integration configured"
else
    echo "❌ Configuration failed"
    exit 1
fi

# Apply recommended configuration
echo ""
echo "🔧 Applying recommended configuration..."
CONFIG_FILE="$HOME/.pi/agent/extensions/pi-lean-ctx/config.json"
TEMPLATE_FILE="$(cd "$(dirname "$0")" && pwd)/leanctx-config-template.json"

if [ -f "$TEMPLATE_FILE" ]; then
    # Use our template configuration
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    echo "✓ Configuration applied from template"
    echo "  - Compression: aggressive"
    echo "  - Mode: replace (forces ctx_* tool usage)"
elif [ -f "$CONFIG_FILE" ]; then
    # Template not found, patch existing config
    echo "⚠️  Template not found, patching existing config..."
    if command -v jq &>/dev/null; then
        TMP=$(mktemp)
        jq '.env.LEAN_CTX_COMPRESSION_LEVEL = "aggressive" | .env.LEAN_CTX_PI_MODE = "replace"' "$CONFIG_FILE" > "$TMP"
        mv "$TMP" "$CONFIG_FILE"
    else
        sed -i.bak 's/"LEAN_CTX_COMPRESSION_LEVEL": "[^"]*"/"LEAN_CTX_COMPRESSION_LEVEL": "aggressive"/g' "$CONFIG_FILE"
        if ! grep -q 'LEAN_CTX_PI_MODE' "$CONFIG_FILE"; then
            # Add PI_MODE after COMPRESSION_LEVEL
            sed -i.bak 's/"LEAN_CTX_COMPRESSION_LEVEL": "aggressive",/"LEAN_CTX_COMPRESSION_LEVEL": "aggressive",\n    "LEAN_CTX_PI_MODE": "replace",/' "$CONFIG_FILE"
        fi
        rm -f "${CONFIG_FILE}.bak"
    fi
    echo "✓ Configuration patched"
else
    echo "⚠️  Config file will be created on first pi run"
    echo "    Run this script again after starting pi once"
fi

# Verify installation
echo ""
echo "🔍 Verifying installation..."
if lean-ctx doctor integrations 2>&1 | grep -q "Pi\|pi-lean-ctx" || [ -d "$HOME/.pi/agent/npm/node_modules/pi-lean-ctx" ]; then
    echo "✓ Installation verified"
else
    echo "⚠️  Verification incomplete - check lean-ctx doctor"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart pi (to load new configuration)"
echo "  2. Use pi normally - ctx_* tools used automatically"
echo "  3. After session, check savings: lean-ctx gain"
echo ""
echo "Configuration:"
echo "  - Compression level: aggressive (maximum savings)"
echo "  - Mode: replace (forces ctx_* tools, disables native read/bash)"
echo "  - Expected savings: 40-50% typical, more with cached re-reads"
echo ""
echo "IMPORTANT: Replace mode ensures compression actually happens."
echo "Pi MUST use ctx_* tools - no native tools available."
echo ""
echo "Documentation: $HOME/dev/dotfiles/pi/LEANCTX.md"
