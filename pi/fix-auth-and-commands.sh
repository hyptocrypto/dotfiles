#!/usr/bin/env bash
# Quick fix for auth and missing commands
set -euo pipefail

echo "🔧 Fixing pi auth and commands..."
echo

# Check if pi is running
if pgrep -f "pi " > /dev/null 2>&1; then
    echo "⚠️  Pi is currently running. Please:"
    echo "   1. In pi, type: /quit"
    echo "   2. Then run this script again"
    echo
    exit 1
fi

# 1. Install auth extension first
echo "📦 Installing authentication extension..."
pi install npm:@gotgenes/pi-anthropic-auth
echo

# 2. Install all other packages
echo "📦 Installing all extensions..."
./install.sh
echo

# 3. Verify installation
echo "🔍 Verifying installation..."
./verify-install.sh
echo

echo "✅ Setup complete!"
echo
echo "Next steps:"
echo "  1. Start pi: pi"
echo "  2. Login if needed: /login"
echo "  3. Test commands:"
echo "     - /goal test goal"
echo "     - Show me available subagents"
echo "     - /todos"
echo
echo "If commands still don't work:"
echo "  - Make sure you did /quit (not just /reload)"
echo "  - Check startup output for errors"
echo "  - See TROUBLESHOOTING.md for more help"
