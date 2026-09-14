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

# Set aggressive compression
echo ""
echo "🔧 Setting aggressive compression..."
CONFIG_FILE="$HOME/.pi/agent/extensions/pi-lean-ctx/config.json"

if [ -f "$CONFIG_FILE" ]; then
    # Update compression level to aggressive
    if command -v jq &>/dev/null; then
        # Use jq for safe JSON editing
        TMP=$(mktemp)
        jq '.env.LEAN_CTX_COMPRESSION_LEVEL = "aggressive"' "$CONFIG_FILE" > "$TMP"
        mv "$TMP" "$CONFIG_FILE"
    else
        # Fallback: sed replacement
        sed -i.bak 's/"LEAN_CTX_COMPRESSION_LEVEL": "lite"/"LEAN_CTX_COMPRESSION_LEVEL": "aggressive"/g' "$CONFIG_FILE"
        rm -f "${CONFIG_FILE}.bak"
    fi
    echo "✓ Compression set to aggressive"
else
    echo "⚠️  Config file not found, will be created on first pi run"
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
echo "  2. Use pi normally - compression is automatic"
echo "  3. After session, check savings: lean-ctx gain"
echo ""
echo "Configuration:"
echo "  - Compression level: aggressive (maximum savings)"
echo "  - Auto-compression: enabled for all reads/shell commands"
echo "  - Expected savings: 40-50% typical, more with cached re-reads"
echo ""
echo "Documentation: $HOME/dev/dotfiles/pi/LEANCTX.md"
