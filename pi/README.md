# Pi Configuration

This directory contains pi (coding agent) configuration that syncs across devices via dotfiles.

## Setup on a New Device

```bash
cd ~/dev/dotfiles/pi
./install.sh
```

This copies all pi config from the repo to `~/.pi/agent/`. Safe to re-run to update from repo.

## Auto-Configuration

Models auto-configure based on your authenticated provider:

1. Run `pi` and `/login` (choose Claude or Copilot)
2. Restart: `/quit` then `pi`
3. The `auto-provider-config` extension detects your provider and updates models

**Manual override:** Run `./switch-agents.sh` to force re-detection.

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

- **`switch-agents.sh`** - Manual provider detection and configuration
- **`extensions/auto-provider-config.ts`** - Auto-configures on session start
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

## Custom Commands

**New custom commands added:**
- `/btw <question>` - Quick questions to cheap model (non-blocking)
- `/m` or `/pick` - Enhanced model picker with cost info and thinking levels

See **[COMMANDS.md](COMMANDS.md)** for full documentation.

## Extensions

Extensions in `extensions/` are auto-loaded by pi:
- `btw.ts` - Quick questions (`/btw`)
- `model-enhanced.ts` - Enhanced model picker (`/m`, `/pick`)
- `confirm-destructive.ts` - Confirm dangerous operations
- `git-checkpoint.ts` - Auto-checkpoint on changes
- `protected-paths.ts` - Block writes to sensitive files
- `question.ts` - Enhanced question tool
- `subagent/` - Task delegation
- `todo.ts` - Todo list management
- And more...

See each `.ts` file for details.

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
