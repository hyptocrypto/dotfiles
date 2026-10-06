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

## Vim Mode

Auto-enables on startup.

- `jk` in insert mode → normal mode
- `hjkl` to move
- `Esc` also works

Customize: Edit `~/.pi/agent/pi-vimmode.config.js` then `/vimmode reload`

## Troubleshooting

**Vim mode not working:**
```bash
/vimmode  # Toggle it
/vimmode reload  # Reload config
```

**Extensions not loading:**
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
- `verify-install.sh` - Check installation
- `settings.json` - Main config
- `pi-vimmode-config-template.js` - Vim config template
