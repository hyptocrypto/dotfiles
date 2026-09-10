# Branch Context Extension

Auto-generates and injects compressed feature branch context at the start of each chat, eliminating the need to manually explain branch purpose and changes every time.

## Problem

When working on long-running feature branches:
- Each new chat requires re-explaining the branch purpose
- Manually running `git diff main` eats 5k+ tokens
- Context rots in long-running conversations
- Large context windows become expensive over time

## Solution

This extension:
1. **Auto-detects** current branch vs repository default branch
2. **Generates** compressed context summary (~1500-2000 tokens)
3. **Caches** results with diff-based invalidation
4. **Injects** context automatically at chat start
5. **Refreshes** only when branch changes significantly

## Features

### Automatic Context Injection

When you start a chat on a feature branch, the extension:
- Detects you're not on the default branch
- Loads cached context or generates fresh summary
- Injects into system prompt before first message
- Shows notification: "Branch context loaded for feature-xyz"

### Smart Base Branch Detection

No hardcoded `main` or `master` assumptions. Detects base branch via:
1. `origin/HEAD` symbolic ref
2. Common names (main, master, development, develop, dev)
3. Remote HEAD query
4. Fallback to `main`

Works with any repository naming convention.

### Efficient Caching

- Hashes the branch diff to detect changes
- Regenerates only when diff changes significantly
- Stores per-branch in `~/.pi/branch-context/`
- Preserves custom purpose notes across refreshes

### Delegated Generation

Uses **scout agent** to compress diff into digestible summary:
- Analyzes changed files, commits, diff stats
- Groups related changes by area
- Identifies key features, refactors, breaking changes
- Outputs structured markdown summary
- Stays within ~2000 token budget

## Commands

### `/branch-context`

Show current cached context for the branch.

```
$ /branch-context
```

Output:
```
Branch: feature-auth-refactor
Base: development
Cached: 2024-01-15 14:32:11

## Purpose
Refactor authentication system from JWT to session-based...
[full context]
```

### `/refresh-branch-context`

Force regenerate the context summary (useful after merging main or adding major changes).

```
$ /refresh-branch-context
```

### `/set-branch-purpose "<purpose>"`

Override the auto-detected branch purpose with a custom note.

```
$ /set-branch-purpose "Rewrite auth system to use Redis sessions"
```

Custom purpose persists across cache refreshes and is injected into the scout's analysis.

## Token Savings

**Before extension:**
```
User: "Working on auth refactor branch. Compare against development."
Agent: <reads 5000+ tokens of diff>
User: "This branch rewrites auth to use sessions instead of JWT..."
Agent: <500 tokens of explanation>

Total: ~6000 tokens before real work starts
```

**With extension:**
```
[Auto-injected at chat start]
## Purpose: Auth refactor - JWT to session-based
## Key Changes: [compressed summary]
## Changed Files: [grouped by area]

Total: ~1500-2000 tokens, zero manual setup
```

**Savings:** 70% fewer tokens, instant context, no manual work.

## Large Branch Support

For branches with 10k+ line changes (like the example 16k additions):
- Token budget set to 2000 tokens
- Scout agent compresses intelligently:
  - Groups files by functional area
  - Highlights only significant changes
  - Omits boilerplate/mechanical changes
  - Focuses on architectural decisions

The extension scales to large refactors without overwhelming the context window.

## Installation

### Option 1: Global (all projects)

```bash
# Extension already in this repo's pi/extensions/
# Copy to global location
cp pi/extensions/branch-context.ts ~/.pi/extensions/

# Enable globally
echo "branch-context" >> ~/.pi/extensions/enabled.txt
```

### Option 2: Per-project

```bash
# Already included in this repo
# Just enable in project settings
# (Edit .pi/settings.json to include in extensions array)
```

### Option 3: One-time use

```bash
pi --extension branch-context
```

## How It Works

### On Chat Start (`chat_start` hook)

1. Check `git rev-parse --abbrev-ref HEAD` → current branch
2. Detect default branch (origin/HEAD or common names)
3. If on feature branch:
   - Compute diff hash: `md5(git diff base...feature)`
   - Check cache: `~/.pi/branch-context/<branch>.json`
   - If cache valid (hash matches): use cached context
   - If cache invalid/missing: invoke scout agent
4. Inject context into system prompt via `ctx.addSystemMessage()`

### Scout Agent Task

Given:
- Branch name & base branch
- Changed files list
- Diff stats
- Recent commit log
- Optional custom purpose

Produces:
```markdown
## Purpose
[2-3 sentence description]

## Key Changes
[5-10 most significant changes]

## Changed Files (Grouped)
[Files organized by functional area with brief descriptions]

## Technical Context
[Dependencies, migrations, breaking changes]
```

### Cache Format

`~/.pi/branch-context/feature-auth-refactor.json`:
```json
{
  "branch": "feature-auth-refactor",
  "baseBranch": "development",
  "diffHash": "a3f7c8e9...",
  "context": "## Purpose\n...",
  "customPurpose": "Rewrite auth to use Redis sessions",
  "timestamp": 1705329131000
}
```

## Configuration

No configuration needed - works out of the box.

If you need to adjust token budget, edit the extension:

```typescript
const CONTEXT_TOKEN_BUDGET = 2000; // Increase for very large branches
```

## Troubleshooting

### "Not in a git repository"

Extension only works in git repositories. Ensure you're in a project with `.git/`.

### "On default branch, no context needed"

Working as intended - extension only activates on feature branches.

### Context not refreshing

Branch diff hasn't changed enough to invalidate cache. Use `/refresh-branch-context` to force regeneration.

### Scout agent fails

Ensure `scout` agent is available:
```bash
pi list-agents | grep scout
```

If missing, create `~/.pi/agent/agents/scout/` with appropriate config.

## Examples

### Starting work on a feature branch

```bash
$ git checkout feature-api-v2
$ pi

[Extension auto-loads context]
Branch context generated for feature-api-v2 (vs main)

You: "Add rate limiting to the user endpoint"
Agent: [has full context of API v2 refactor, knows which files changed, what the branch does]
```

### After merging main

```bash
$ git merge main
$ pi

You: "/refresh-branch-context"
Agent: "Regenerating context for feature-api-v2..."
Agent: "✓ Context refreshed"
[Updated context includes new changes from main]
```

### Reviewing cached context

```bash
You: "/branch-context"
Agent: 
**Branch:** feature-api-v2
**Base:** main
**Cached:** 2024-01-15 14:32:11

## Purpose
Complete rewrite of REST API to v2 with GraphQL support...
```

## Why TypeScript?

Follows existing extension pattern in this repository. All extensions in `pi/extensions/` use TypeScript for:
- Type safety with Pi's ExtensionAPI
- Consistency with other extensions
- Better IDE support

## Credits

Built for managing large, long-running feature branches in the dotfiles repository.
Designed to work with any repository's branch naming conventions.
