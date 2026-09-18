# Pi Configuration

This directory contains pi (coding agent) configuration that syncs across devices via dotfiles.

## Setup on a New Device

```bash
cd ~/dev/dotfiles/pi
./install.sh
```

This copies all pi config from the repo to `~/.pi/agent/`. Safe to re-run to update from repo.

## Configure for Your Provider

After logging into pi (`/login`), run:

```bash
cd ~/dev/dotfiles/pi
./switch-agents.sh
```

This detects which provider you're authenticated with and configures agents accordingly.

### Agent Model Mappings

**Claude Device:**
- scout → `claude-haiku-4-5` (fast, cheap)
- planner → `claude-sonnet-4-5` (planning)
- worker → `claude-sonnet-4-5` (implementation)
- reviewer → `claude-sonnet-4-5` (review)

**Copilot Device:**
- scout → `gemini-3.8-flash` (fast, cheap)
- planner → `claude-sonnet-5` (planning)
- worker → `claude-sonnet-5` (implementation)
- reviewer → `claude-opus-5` (deep analysis)

## Files

- **`switch-agents.sh`** - Provider detection and configuration
- **`agents/`** - Agent definitions (scout, planner, worker, reviewer)
- **`extensions/`** - Pi extensions
- **`prompts/`** - Custom prompt templates
- **`themes/`** - Custom themes
- **`settings.json`** - Pi settings
- **`keybindings.json`** - Custom keybindings
- **`AGENTS.md`** - Global agent rules

## Workflow

1. **On first device:**
   ```bash
   cd ~/dev/dotfiles/pi
   ./install.sh
   pi
   /login  # Choose your provider
   /quit
   ./switch-agents.sh
   git add .
   git commit -m "Update agent configs"
   git push
   ```

2. **On second device:**
   ```bash
   cd ~/dev/dotfiles
   git pull
   cd pi
   ./install.sh
   pi
   /login  # Choose your provider (different one is fine!)
   /quit
   ./switch-agents.sh
   ```

## How It Works

- **install.sh** copies all config from repo to `~/.pi/agent/`
- **switch-agents.sh** detects provider and configures agents
- All files in `~/.pi/agent/` are local copies (not in git)
- Repo contains templates
- Re-run `install.sh` to update from repo
- Run `switch-agents.sh` after install to configure for your provider

## Extensions & Tools

### LeanCTX (Context Compression)

**Automatically reduces token usage by 40-95%** via MCP integration.

**Installation:**
```bash
cd ~/dev/dotfiles/pi
./setup-leanctx.sh
```

Uses `lean-ctx wrap pi` for automatic setup with aggressive compression.

### Custom Commands

**Custom commands available:**
- `/m` or `/pick` - Enhanced model picker with cost info and thinking levels
- Plus npm extensions: `/btw`, `/todos` (see Extensions below)

See **[COMMANDS.md](COMMANDS.md)** for full documentation.

## Extensions

### NPM Extensions (Installed via install.sh)

- **`@juicesharp/rpiv-todo`** - Todo list with live overlay (`/todos`)
- **`@narumitw/pi-btw`** - Quick questions to cheap model (`/btw <question>`)

### Custom Extensions (in `extensions/`)

- `model-enhanced.ts` - Enhanced model picker (`/m`, `/pick`) with cost info
- `branch-context.ts` - Auto-inject feature branch context
- `review.ts` - Local PR-style code review (`/review`)
- `auto-provider-config.ts` - Auto-sync settings when switching providers
- `protected-paths.ts` - Block writes to sensitive files
- `confirm-destructive.ts` - Confirm dangerous operations
- `git-checkpoint.ts` - Auto-checkpoint on changes
- `question.ts` - Enhanced question tool
- `subagent/` - Task delegation
- And more...

See **[MIGRATION.md](MIGRATION.md)** for details on replaced extensions.

### Branch Context Extension

Opt-in compressed branch context that injects automatically once enabled. Saves time and tokens on long-running feature branches.

**Features:**
- Opt-in: only injects if you've enabled it via `/refresh-branch-context`
- Generates ~2000 token compressed summary using scout agent
- Caches with diff-based invalidation
- Works with any base branch naming (main/master/development/etc)
- Commands: `/branch-context`, `/refresh-branch-context`, `/set-branch-purpose`

**Workflow:** Run `/refresh-branch-context` once to enable. Future chats auto-inject cached context.

**Use case:** Working on a 16k+ line feature branch? Enable context once, get instant injection every chat.

See [README-branch-context.md](extensions/README-branch-context.md) for full documentation.

## Updating

After making changes in the repo:

```bash
cd ~/dev/dotfiles/pi
git add .
git commit -m "Update pi config"
git push
```

On other devices:
```bash
cd ~/dev/dotfiles
git pull
cd pi
./switch-agents.sh  # Reconfigure if needed
```

Pi will pick up changes automatically (or run `/reload` in pi).
