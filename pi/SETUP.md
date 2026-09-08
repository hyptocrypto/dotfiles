# Quick Setup Guide

## New Device Setup (3 steps)

```bash
# 1. Install (creates symlinks)
cd ~/dev/dotfiles/pi
./install.sh

# 2. Login to your provider
pi
/login  # Choose Claude or Copilot
/quit

# 3. Configure agents
./switch-agents.sh
```

Done! Your agents are now configured for your provider.

## What Happens

**install.sh:**
- Creates `~/.pi/agent/` directory
- **Copies** all config from repo (no symlinks)
- Safe to re-run (backs up existing files on first run)
- Updates local config to match repo templates

**switch-agents.sh:**
- Reads `~/.pi/agent/auth.json` to detect your provider
- Updates agent configs in the repo with correct models
- Claude device → haiku/sonnet models
- Copilot device → gemini/sonnet/opus models

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
cd ~/dev/dotfiles/pi
./switch-agents.sh  # Re-detect and configure
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
