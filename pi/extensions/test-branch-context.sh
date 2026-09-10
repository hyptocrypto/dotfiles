#!/usr/bin/env bash
# Quick test for branch-context extension
set -euo pipefail

echo "=== Branch Context Extension - Quick Test ==="
echo

# Check if in git repo
if ! git rev-parse --git-dir &>/dev/null; then
    echo "❌ Not in a git repository"
    exit 1
fi
echo "✓ In git repository"

# Check current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "✓ Current branch: $BRANCH"

# Check default branch detection
if git symbolic-ref refs/remotes/origin/HEAD &>/dev/null; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
    echo "✓ Default branch detected: $DEFAULT_BRANCH"
else
    echo "⚠ origin/HEAD not set, will try common names"
    for name in main master development develop dev; do
        if git rev-parse --verify "$name" &>/dev/null 2>&1; then
            DEFAULT_BRANCH="$name"
            echo "✓ Found default branch: $DEFAULT_BRANCH"
            break
        fi
    done
fi

if [ -z "${DEFAULT_BRANCH:-}" ]; then
    echo "⚠ Could not detect default branch, will use 'main'"
    DEFAULT_BRANCH="main"
fi

# Check if on feature branch
if [ "$BRANCH" = "$DEFAULT_BRANCH" ]; then
    echo "ℹ️  On default branch - extension won't activate"
    echo "   Create a feature branch to test:"
    echo "   git checkout -b test-branch"
    exit 0
fi

echo "✓ On feature branch - extension will activate"

# Check diff
if git diff "$DEFAULT_BRANCH...$BRANCH" &>/dev/null; then
    DIFF_LINES=$(git diff --stat "$DEFAULT_BRANCH...$BRANCH" | tail -1 | awk '{print $1}')
    echo "✓ Diff available: $DIFF_LINES files changed"
else
    echo "⚠ No diff found (branch might be up to date with $DEFAULT_BRANCH)"
fi

# Check cache directory
CACHE_DIR="$HOME/.pi/branch-context"
if [ -d "$CACHE_DIR" ]; then
    echo "✓ Cache directory exists: $CACHE_DIR"
    CACHE_COUNT=$(ls -1 "$CACHE_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    echo "  Cached branches: $CACHE_COUNT"
else
    echo "ℹ️  Cache directory doesn't exist yet (will be created on first use)"
fi

# Check extension file
EXT_FILE="$HOME/.pi/agent/extensions/branch-context.ts"
if [ -f "$EXT_FILE" ]; then
    echo "✓ Extension installed: $EXT_FILE"
    SIZE=$(ls -lh "$EXT_FILE" | awk '{print $5}')
    echo "  File size: $SIZE"
else
    echo "❌ Extension not installed at $EXT_FILE"
    echo "   Run: cd ~/dev/dotfiles/pi && ./install.sh"
    exit 1
fi

# Check subagent extension
SUBAGENT_DIR="$HOME/.pi/agent/extensions/subagent"
if [ -d "$SUBAGENT_DIR" ]; then
    echo "✓ Subagent extension found"
else
    echo "❌ Subagent extension missing (required for context generation)"
    echo "   Run: cd ~/dev/dotfiles/pi && ./install.sh"
    exit 1
fi

# Check scout agent
SCOUT_DIR="$HOME/.pi/agent/agents/scout"
if [ -d "$SCOUT_DIR" ]; then
    echo "✓ Scout agent found"
else
    echo "❌ Scout agent missing (required for context generation)"
    echo "   Run: cd ~/dev/dotfiles/pi && ./install.sh"
    exit 1
fi

echo
echo "=== Test Summary ==="
echo "✓ All checks passed!"
echo
echo "Extension is ready. Start pi and it should:"
echo "1. Detect branch: $BRANCH (vs $DEFAULT_BRANCH)"
echo "2. Generate/load cached context"
echo "3. Show notification: 'Branch context loaded for $BRANCH'"
echo
echo "Commands to try:"
echo "  /branch-context           - View current context"
echo "  /refresh-branch-context   - Regenerate context"
echo "  /set-branch-purpose \"...\" - Set custom purpose"
echo
echo "To test: pi"
