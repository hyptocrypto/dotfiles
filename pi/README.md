# Pi Configuration

This directory contains pi (coding agent) configuration that syncs across devices via dotfiles.

## Setup on a New Device

```bash
cd ~/dev/dotfiles/pi
./install.sh
```

This creates symlinks from `~/.pi/agent/` to this repo directory.

## Configure Agents for Your Provider

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

- **`switch-agents.sh`** - Auto-configures agents based on provider
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

- **install.sh** creates symlinks: `~/.pi/agent/agents` → repo `agents/`
- **switch-agents.sh** detects provider from `~/.pi/agent/auth.json`
- Agent configs are updated in the repo (via symlinks)
- Changes can be committed and pulled on other devices
- Each device runs `switch-agents.sh` after pull to configure for its provider

## Extensions

Extensions in `extensions/` are auto-loaded by pi:
- `confirm-destructive.ts` - Confirm dangerous operations
- `git-checkpoint.ts` - Auto-checkpoint on changes
- `protected-paths.ts` - Block writes to sensitive files
- `question.ts` - Enhanced question tool
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
