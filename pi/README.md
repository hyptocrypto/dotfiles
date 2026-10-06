# Pi Configuration

Dotfiles config for [Pi coding agent](https://pi.dev).

## Installation

```bash
cd ~/dev/dotfiles/pi
./install.sh
```

Copies config to `~/.pi/agent/` and installs packages.

**Clean install** (deletes `~/.pi/agent/` first):
```bash
./install.sh --clean
```

## After Install

```bash
pi
/login  # If first time
```

Vim mode auto-enables. Press `jk` in insert mode to escape to normal mode.

## Packages (14)

- @gotgenes/pi-anthropic-auth - Auth
- pi-web-access - Web search, GitHub, PDF, YouTube
- @juicesharp/rpiv-ask-user-question - Multi-question dialogs
- pi-subagents - Subagent orchestration (scout, researcher, worker, reviewer)
- pi-lens - Real-time LSP/linting
- pi-goal-x - Goal tracking (`/goal`)
- @narumitw/pi-usage - Usage tracking
- pi-powerline-footer - Status bar
- pi-vimmode - Vim mode
- @zigai/pi-prompt-history - Up/down history (persisted)
- pi-background-tasks - Background jobs
- @gotgenes/pi-permission-system - Permissions
- @juicesharp/rpiv-todo - Todos (`/todos`)
- @narumitw/pi-btw - Quick questions (`/btw`)

## Custom Extensions

- branch-context - Auto branch context
- review - Local PR review (`/review`)
- model-enhanced - Model picker (`/m`)
- plan-mode - Read-only mode (`/plan`)
- confirm-destructive - Confirmations
- git-checkpoint - Auto checkpoint
- protected-paths - Path blocking

## Vim Mode

Auto-enabled on startup. `jk` in insert mode escapes to normal mode.

**Key bindings:**
- INSERT: `jk` → Normal mode (via custom extension)
- NORMAL: `hjkl` (move), `w/b/e` (word motions), `dd` (delete line), `i/a/o` (insert), `v/V` (visual)

Customize: `~/.pi/agent/pi-vimmode.config.js`
Reload: `/vimmode reload`

## Config

- `settings.json` - Pi settings & packages
- `keybindings.json` - Keybindings
- `AGENTS.md` - Global agent rules
- `agents/` - Agent definitions (scout, planner, worker, reviewer)
- `extensions/` - Custom extensions
- `prompts/` - Prompt templates
- `themes/` - Themes
- `pi-vimmode.config.js` - Vim config

## Update

```bash
cd ~/dev/dotfiles/pi
./install.sh
/reload  # In pi
```

## Agent Models

Run `./switch-agents.sh` to configure models per provider:
- Anthropic: claude-haiku-4-5 (scout), claude-sonnet-4-5
- GitHub Copilot: gemini-3.8-flash (scout), claude-sonnet-5, claude-opus-5
