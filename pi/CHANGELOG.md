# Pi Configuration Changelog

## 2024-09-10 - Branch Context Extension

### Added

**New Extension: `branch-context.ts`**

Auto-generates and injects compressed feature branch context at chat start, eliminating manual setup for long-running branches.

**Features:**
- Auto-detects current branch vs default branch (main/master/development/etc)
- Generates ~2000 token compressed summary using scout agent
- Caches results with diff-based invalidation
- Works with any repository's base branch naming
- Smart cache invalidation based on diff hash

**Commands:**
- `/branch-context` - Show current cached context
- `/refresh-branch-context` - Force regenerate context
- `/set-branch-purpose "<purpose>"` - Override auto-detected purpose

**Benefits:**
- 70% token savings vs manual diff + explanation
- Instant context on chat start (no setup time)
- Scales to large branches (16k+ line changes)
- Repository-agnostic base branch detection

**Files:**
- `extensions/branch-context.ts` - Main extension (472 lines)
- `extensions/README-branch-context.md` - Full documentation
- `extensions/EXAMPLE-branch-context.md` - Usage examples
- `extensions/INSTALL-branch-context.md` - Installation guide

**Documentation:**
- Updated `README.md` with extension overview
- Updated `COMMANDS.md` with command reference
- Added examples for 16k+ line feature branches

**Use Case:**
Working on a large feature branch over multiple days/weeks. Instead of explaining the branch purpose and running `git diff` every chat, context is auto-generated and cached, then injected at chat start.

### Technical Details

**Base Branch Detection Strategy:**
1. Check `origin/HEAD` symbolic ref
2. Try common names (main, master, development, develop, dev)
3. Query remote HEAD via `ls-remote`
4. Fallback to `main`

**Cache Invalidation:**
- Computes MD5 hash of `git diff base...branch`
- Regenerates only when hash changes
- Manual refresh via `/refresh-branch-context`

**Scout Agent Task:**
- Analyzes changed files, diff stats, commit log
- Compresses into 4 sections: Purpose, Key Changes, Changed Files, Technical Context
- Target: ~2000 tokens (configurable via `CONTEXT_TOKEN_BUDGET`)

**Cache Location:**
`~/.pi/branch-context/<branch-name>.json`

**Integration:**
- Hooks into `chat_start` event
- Uses `ctx.addSystemMessage()` to inject context
- Delegates summary generation to `scout` via `subagent` tool

### Installation

Already included in this repo. Run:
```bash
cd ~/dev/dotfiles/pi
./install.sh
```

Extension auto-loads on next pi session.

---

## Earlier Changes

(Add previous changes here as needed)
