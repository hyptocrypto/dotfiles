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

Modal editing (custom `modal-editor` extension) starts in INSERT. Press `Esc`
or type `jk` quickly to switch to NORMAL mode.

## Packages (12)

- @gotgenes/pi-anthropic-auth - Auth
- pi-web-access - Web search, GitHub, PDF, YouTube
- @juicesharp/rpiv-ask-user-question - Multi-question dialogs
- pi-subagents - Subagent orchestration (scout, researcher, worker, reviewer)
- pi-goal-x - Goal tracking (`/goal`)
- @narumitw/pi-usage - Usage tracking
- pi-git-status-line - Git status in the footer
- @zigai/pi-prompt-history - Up/down history (persisted)
- pi-background-tasks - Background jobs
- @gotgenes/pi-permission-system - Permissions
- @juicesharp/rpiv-todo - Todos (`/todos`)
- @narumitw/pi-btw - Quick questions (`/btw`)

## Custom Extensions

- modal-editor - Vim-style modal prompt editor (`jk` -> NORMAL)
- branch-context - Auto branch context
- review - Local PR review (`/review`)
- model-enhanced - Model picker (`/m`)
- plan-mode - Read-only mode (`/plan`)
- confirm-destructive - Confirmations
- git-checkpoint - Auto checkpoint
- protected-paths - Path blocking

## Modal Editing

`modal-editor` is a local extension (not an npm package) so the `jk` escape
chord works. Starts in INSERT. `Esc` or `jk` -> NORMAL.

**Key bindings:**
- INSERT: `jk` -> NORMAL mode
- NORMAL: `hjkl` (move), `w/b/e` (word motions), `dd` (delete line), `i/a/o` (insert), `v/V` (visual)

## Config

- `settings.json` - Pi settings & packages
- `keybindings.json` - Keybindings
- `AGENTS.md` - Global agent rules
- `agents/` - Agent definitions (scout, planner, worker, reviewer)
- `extensions/` - Custom extensions
- `prompts/` - Prompt templates
- `themes/` - Themes
- `permission-system-config-template.json` - Permission policy (deployed to
  `~/.pi/agent/extensions/pi-permission-system/config.json`)

## Permissions

`@gotgenes/pi-permission-system` is configured allow-by-default. You are
prompted to approve only:

- Destructive file ops: `rm *`, `sudo rm *`, `find * -delete`,
  `find * -exec rm*`, `shred *`, `dd *`, `mkfs*`, `diskutil erase*/partition*`
- Package-manager installs/removals: `brew`, `npm`, `npx`, `pnpm`, `yarn`,
  `pip`/`pip3`/`pipx`, `cargo install`, `go install`, `gem install`,
  `apt`/`apt-get` install/remove
- Force-pushing git history: `git push --force*` / `git push -f*`

Everything else (`read`, `grep`, `find`, `ls`, `edit`, `bash`, external
directories, etc.) is allowed silently. `.env*`, `.git/*`, `node_modules/*`,
`~/.ssh/*`, `~/.aws/*`, and `~/.config/*/secrets*` stay hard-denied (not
prompted — just blocked) to keep secrets out of context.

`sudo`/`eval`/`bash -c`/`xargs` wrappers are always floored to `ask` by the
extension itself, regardless of config, so an opaque payload can't ride a
permissive rule.

Edit `pi/permission-system-config-template.json` and re-run `./install.sh` to
change the policy (it fully overwrites the deployed config, like
`settings.json`).

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
