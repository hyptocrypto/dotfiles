# Pi Configuration

Dotfiles config for [Pi coding agent](https://pi.dev).

## Install

```bash
cd ~/dev/dotfiles/pi
./install.sh
```

Copies config to `~/.pi/agent/`, installs packages, deploys LeanCTX and
permission-system policy, and configures agent models for whichever provider
you're logged into (via `auth.json`). Idempotent — safe to re-run any time,
same result whether `~/.pi/agent` is empty or already populated.

`./install.sh --clean` wipes `~/.pi/agent` first.

First time: run `./install.sh`, start `pi`, `/login`, then re-run
`./install.sh` to pick up the provider-specific agent models.

## Packages (13)

- @gotgenes/pi-anthropic-auth - Auth
- pi-claude-subscription-connector - Claude Pro/Max subscription billing + usage footer
- pi-web-access - Web search, GitHub, PDF, YouTube
- @juicesharp/rpiv-ask-user-question - Multi-question dialogs
- pi-subagents - Subagent orchestration (scout, planner, worker, reviewer)
- pi-goal-x - Goal tracking (`/goal`)
- @narumitw/pi-usage - Usage tracking
- pi-git-status-line - Git status in the footer
- @zigai/pi-prompt-history - Up/down history (persisted)
- pi-background-tasks - Background jobs
- @gotgenes/pi-permission-system - Permissions
- @juicesharp/rpiv-todo - Todos (`/todos`)
- @narumitw/pi-btw - Quick questions (`/btw`)

`pi-lean-ctx` is installed separately via `lean-ctx init --agent pi` (see
[Files](#files)); it's not counted above.

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

`modal-editor` starts in INSERT. `Esc` or `jk` -> NORMAL.

- NORMAL: `hjkl` (move), `w/b/e` (word motions), `dd` (delete line),
  `i/a/o` (insert), `v/V` (visual)

## Agent Models

`install.sh` detects your provider from `auth.json` and sets `agents/*.md` +
`settings.json` accordingly:

- Anthropic: scout=claude-haiku-4-5, planner/worker/reviewer=claude-sonnet-4-5
- GitHub Copilot: scout=gemini-3.8-flash, planner/worker=claude-sonnet-5,
  reviewer=claude-opus-5

## Permissions

`@gotgenes/pi-permission-system` is allow-by-default. You're prompted to
approve only:

- Destructive file ops: `rm *`, `sudo rm *`, `find * -delete`,
  `find * -exec rm*`, `shred *`, `dd *`, `mkfs*`, `diskutil erase*/partition*`
- Package-manager installs/removals: `brew`, `npm`, `npx`, `pnpm`, `yarn`,
  `pip`/`pip3`/`pipx`, `cargo install`, `go install`, `gem install`,
  `apt`/`apt-get` install/remove
- Force-pushing git history: `git push --force*` / `git push -f*`

Everything else (`read`, `grep`, `find`, `ls`, `edit`, `bash`, external
directories, etc.) is allowed silently. `.env*`, `.git/*`, `node_modules/*`,
`~/.ssh/*`, `~/.aws/*`, and `~/.config/*/secrets*` stay hard-denied (blocked,
not prompted). `sudo`/`eval`/`bash -c`/`xargs` wrappers are always floored to
`ask` by the extension itself regardless of config.

Edit `permission-system-config-template.json` and re-run `./install.sh` to
change the policy.

## Trimmed tools

`fusion_reason`/`fusion_investigate`/`fusion_research`/`fusion_validate`
(`pi-background-tasks`) cost ~3.2k startup tokens and are rarely used day to
day. `subagent`/`subagent_supervisor` (scout/planner/worker/reviewer
delegation) are unaffected and stay on.

`pi-background-tasks` reads its own `PI_BG_FEATURES` env var
(`process,delegate,fusion,attested,attribution` by default) and only loads
the sub-extension for each listed feature — `omz/.zshrc` sets it without
`fusion`, so that code never loads at all (not just hidden from the model):

```zsh
export PI_BG_FEATURES="process,delegate,attested,attribution"
```

`process` keeps `bg_run`/`bg_wait`/`bg_status`/`bg_logs`/`bg_kill`; `delegate`
keeps `bg_delegate`/`bg_result`. Drop the var (or add `fusion` back in) for
one shell to get it back.

## Files

- `install.sh` - the one script: copy config, install packages, configure
  LeanCTX/permissions/agent models
- `settings.json` - Pi settings & packages
- `keybindings.json` - keybindings
- `AGENTS.md` - global agent rules
- `agents/` - agent definitions (scout, planner, worker, reviewer)
- `extensions/` - custom extensions
- `prompts/` - prompt templates
- `themes/` - themes
- `leanctx-config-template.json` - LeanCTX config (deployed to
  `~/.pi/agent/extensions/pi-lean-ctx/config.json`)
- `permission-system-config-template.json` - permission policy (deployed to
  `~/.pi/agent/extensions/pi-permission-system/config.json`)
