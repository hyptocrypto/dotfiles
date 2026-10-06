#!/usr/bin/env bash
# Verify pi extension installation
set -euo pipefail

echo "🔍 Verifying pi extension installation..."
echo

# Check if pi is installed
if ! command -v pi &>/dev/null; then
    echo "❌ pi command not found - install pi first"
    exit 1
fi

echo "✓ pi command found: $(which pi)"
echo

# Expected packages
EXPECTED_PACKAGES=(
    "@gotgenes/pi-anthropic-auth"
    "pi-vimmode"
    "@zigai/pi-prompt-history"
    "pi-web-access"
    "@juicesharp/rpiv-ask-user-question"
    "pi-subagents"
    "pi-lens"
    "pi-goal-x"
    "@narumitw/pi-usage"
    "pi-background-tasks"
    "@gotgenes/pi-permission-system"
    "@juicesharp/rpiv-todo"
    "@narumitw/pi-btw"
)

# Note: Load order matters! pi-vimmode MUST be before pi-powerline-footer

echo "📦 Checking installed packages..."
echo

MISSING=0
for pkg in "${EXPECTED_PACKAGES[@]}"; do
    if pi list 2>/dev/null | grep -q "$pkg"; then
        echo "  ✓ $pkg"
    else
        echo "  ❌ $pkg (missing)"
        MISSING=$((MISSING + 1))
    fi
done

echo

# Check for deleted custom extensions
echo "🗑️  Verifying deleted custom extensions..."
echo

DELETED_EXTENSIONS=(
    "~/.pi/agent/extensions/web"
    "~/.pi/agent/extensions/question.ts"
    "~/.pi/agent/extensions/subagent"
    "~/.pi/agent/extensions/modal-editor"
)

for ext in "${DELETED_EXTENSIONS[@]}"; do
    ext_expanded="${ext/#\~/$HOME}"
    if [ -e "$ext_expanded" ]; then
        echo "  ⚠️  $ext still exists (should be deleted)"
    else
        echo "  ✓ $ext deleted"
    fi
done

echo

# Check custom extensions that should remain
echo "📁 Verifying custom extensions (should exist)..."
echo

CUSTOM_EXTENSIONS=(
    "~/.pi/agent/extensions/branch-context.ts"
    "~/.pi/agent/extensions/review.ts"
    "~/.pi/agent/extensions/model-enhanced.ts"
    "~/.pi/agent/extensions/confirm-destructive.ts"
    "~/.pi/agent/extensions/git-checkpoint.ts"
    "~/.pi/agent/extensions/protected-paths.ts"
    "~/.pi/agent/extensions/plan-mode"
    "~/.pi/agent/extensions/modal-editor"
)

for ext in "${CUSTOM_EXTENSIONS[@]}"; do
    ext_expanded="${ext/#\~/$HOME}"
    if [ -e "$ext_expanded" ]; then
        echo "  ✓ $ext"
    else
        echo "  ❌ $ext (missing)"
    fi
done

echo

# Summary
if [ $MISSING -eq 0 ]; then
    echo "✅ All 14 packages installed correctly!"
    echo
    echo "Next steps:"
    echo "  1. Restart pi: /reload or /quit then pi"
    echo "  2. Test new features:"
    echo "     - Try /goal <description>"
    echo "     - Web search has more capabilities"
    echo "     - Questions have richer UI"
    echo "     - Real-time linting with pi-lens"
    echo "     - Background tasks: run long jobs in background"
    echo "     - Powerline footer shows git status"
    echo
    echo "  3. Configure pi-permission-system:"
    echo "     - Create ~/.pi/agent/extensions/pi-permission-system/config.json"
    echo "     - Migrate rules from protected-paths.ts"
    echo "     - See: https://pi.dev/packages/@gotgenes/pi-permission-system"
else
    echo "⚠️  $MISSING package(s) missing"
    echo
    echo "Run: ./install.sh to install missing packages"
fi

echo
echo "To see what changed: cat CHANGES-SUMMARY.md"
echo "For package details: cat PACKAGE-REVIEW.md"
