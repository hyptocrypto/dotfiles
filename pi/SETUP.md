# Pi Setup

## First Time

```bash
cd ~/dev/dotfiles/pi
./install.sh

pi
/login
```

## Provider Configuration

After login, configure agent models:

```bash
cd ~/dev/dotfiles/pi
./switch-agents.sh
```

This detects your provider and sets models for scout/planner/worker/reviewer.

## Modal Editing

`modal-editor` (custom extension, auto-loaded from `extensions/`) enables
vim-style modal editing of the prompt.

- `jk` in insert mode → normal mode
- `hjkl` to move
- `Esc` also works

## Troubleshooting

**Modal editing not working:**
```bash
./install.sh --clean  # Clean install
```

**Auth errors:**
Package `@gotgenes/pi-anthropic-auth` should fix it. If not:
```bash
pi install npm:@gotgenes/pi-anthropic-auth
/quit && pi
/login
```

## Files

- `install.sh` - Install script
- `switch-agents.sh` - Configure agent models
- `settings.json` - Main config
