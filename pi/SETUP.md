# Quick Setup Guide

## New Device Setup (2 steps)

```bash
# 1. Install (copies config)
cd ~/dev/dotfiles/pi
./install.sh

# 2. Login to your provider
pi
/login  # Choose Claude or Copilot
/quit
pi       # Restart - auto-detects provider and configures models
```

Done! Models auto-configure based on your authenticated provider.

## How Auto-Configuration Works

The `auto-provider-config` extension runs on session start:
- Reads `~/.pi/agent/auth.json` to detect your provider
- If provider changed, updates `settings.json` and agent model references
- Notifies you and suggests `/reload`

No manual `switch-agents.sh` needed unless you want to force a re-configuration.

## What Happens

**install.sh:**
- Creates `~/.pi/agent/` directory
- **Copies** all config from repo (no symlinks)
- Safe to re-run (backs up existing files on first run)
- Updates local config to match repo templates

**auto-provider-config extension:**
- Runs automatically on session start
- Detects provider from `~/.pi/agent/auth.json`
- Updates `settings.json` and `~/.pi/agent/agents/*.md` with correct models
- Claude device → haiku/sonnet models
- Copilot device → gemini/sonnet/opus models

**switch-agents.sh (manual override):**
- Same behavior as auto-config, but runs explicitly
- Useful if auto-config fails or you want to force re-detection

## Models Used

### Claude Device
```
scout    → claude-haiku-4-5   (fast, cheap)
planner  → claude-sonnet-4-5  (planning)
worker   → claude-sonnet-4-5  (implementation)
reviewer → claude-sonnet-4-5  (review)
```

### Copilot Device
```
scout    → gemini-3.8-flash   (fast, cheap)
planner  → claude-sonnet-5    (planning)
worker   → claude-sonnet-5    (implementation)
reviewer → claude-opus-5      (deep analysis)
```

## Syncing Changes

**After making changes on one device:**
```bash
cd ~/dev/dotfiles
git add pi/
git commit -m "Update pi config"
git push
```

**On another device:**
```bash
cd ~/dev/dotfiles
git pull
cd pi
./switch-agents.sh  # Reconfigure for this device's provider
```

## Troubleshooting

**Agents not loading?**
```bash
cd ~/dev/dotfiles/pi
./install.sh  # Re-create symlinks
```

**Wrong models?**
```bash
# Option 1: Restart pi (auto-detects)
pi
/quit
pi

# Option 2: Manual override
cd ~/dev/dotfiles/pi
./switch-agents.sh  # Force re-detect and configure
```

**Check symlinks:**
```bash
ls -la ~/.pi/agent/
# Should show symlinks pointing to ~/dev/dotfiles/pi/
```

**Reload pi:**
```
/reload  # In pi, after changing configs
```

## File Locations

**Repo (version controlled):**
```
~/dev/dotfiles/pi/agents/*.md        # Templates
~/dev/dotfiles/pi/extensions/*.ts    # Templates
~/dev/dotfiles/pi/switch-agents.sh   # Script
~/dev/dotfiles/pi/settings.json      # Template
```

**Pi reads from (local copies):**
```
~/.pi/agent/agents/*.md              # Device-specific
~/.pi/agent/extensions/*.ts          # Local copies
~/.pi/agent/settings.json            # Local copy
```

**Not in repo (local only):**
```
~/.pi/agent/auth.json                # Credentials
~/.pi/agent/sessions/                # Session history
```

**Not in repo (local only):**
```
~/.pi/agent/auth.json         - Your login credentials
~/.pi/agent/sessions/         - Session history
```
