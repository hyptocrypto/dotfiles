# LeanCTX Setup - Final Solution

## Root Cause Found

**Problem:** Pi never saw instructions to use `ctx_*` tools.

**Why:** LeanCTX instructions were missing from `~/.pi/agent/AGENTS.md`.

**Result:** Pi used native `read`/`bash` tools → no compression.

## Solution

Added LeanCTX instructions to **global AGENTS.md** so every project gets them.

### What Was Added

```markdown
## Context Compression (LeanCTX)

**Always use ctx_* tools for reading files and running commands.**

- **ctx_read** `<path>` — Read files (instead of native `read`)
- **ctx_shell** `<command>` — Run shell commands (instead of native `bash`)  
- **ctx_search** `<pattern>` — Search code (instead of `grep`)
- **ctx_glob** `<pattern>` — List files (instead of `glob`)
- **ctx_tree** `<path>` — Show directory tree

**Critical:** Native `read`/`bash` tools are disabled. You MUST use `ctx_*` variants.
```

## How Pi Loads AGENTS.md

From pi documentation:
> Pi loads `AGENTS.md` from:
> - `~/.pi/agent/AGENTS.md` (global)
> - Parent directories (walking up from cwd)
> - Current directory
>
> **All matching files are concatenated.**

So even if a project has local AGENTS.md, the global one is ALWAYS loaded too.

## Files Updated

### This Device (Already Applied)
- ✅ `~/.pi/agent/AGENTS.md` - Added LeanCTX instructions

### In Repo (For Other Devices)
- ✅ `pi/AGENTS.md` - Added LeanCTX instructions
- ✅ `pi/install.sh` - Already copies AGENTS.md to ~/.pi/agent/
- ✅ `pi/leanctx-config-template.json` - Replace mode config
- ✅ `pi/setup-leanctx.sh` - Applies template config

## Installation on Other Devices

```bash
cd ~/dev/dotfiles
git pull

# Re-run install to get updated AGENTS.md
./pi/install.sh

# Restart pi
# LeanCTX instructions now present in every session
```

## Verification

After restart, pi should show in startup header:
```
Loaded context:
  ~/.pi/agent/AGENTS.md
  /path/to/project/AGENTS.md (if present)
```

And when you ask it to read a file, it should use `ctx_read` automatically.

Check after session:
```bash
lean-ctx gain
# Should show actual token savings
```

## Why This Works

**Before:**
- Global AGENTS.md: No LeanCTX instructions
- Project AGENTS.md: No LeanCTX instructions
- Pi: Uses native `read`/`bash` (no compression)

**After:**
- Global AGENTS.md: **Always** tells pi to use `ctx_*` tools
- Project AGENTS.md: Can have project-specific instructions
- Pi: Uses `ctx_*` tools (compressed automatically)

## Configuration Summary

**Config file:** `~/.pi/agent/extensions/pi-lean-ctx/config.json`
```json
{
  "env": {
    "LEAN_CTX_COMPRESSION_LEVEL": "aggressive",
    "LEAN_CTX_SAVINGS_FOOTER": "never",
    "LEAN_CTX_PI_MODE": "replace"
  },
  "routeShell": true
}
```

**AGENTS.md instructions:** Tell pi which tools to use
**Config replace mode:** Disables native tools (enforces ctx_* usage)

Both are needed:
1. Instructions → Pi knows to use ctx_* tools
2. Replace mode → Native tools unavailable (backup enforcement)

## Expected Results

**With instructions present:**
- Pi uses `ctx_read`, `ctx_shell`, `ctx_search`, etc.
- Files compressed before sending to model
- 40-50% token savings typical
- 95% savings on cached re-reads

**Session comparison:**
- Before: 183k tokens, $0.15
- After: 35-50k tokens, $0.03-0.05
- Savings: 70-80%

## Troubleshooting

### Still using native tools?

Check AGENTS.md loaded:
```bash
# Pi startup header should show:
# Loaded context:
#   ~/.pi/agent/AGENTS.md
```

If not loaded, verify file exists:
```bash
ls -la ~/.pi/agent/AGENTS.md
```

### No ctx_* tools available?

Check extension installed:
```bash
ls ~/.pi/agent/npm/node_modules/pi-lean-ctx
lean-ctx doctor
```

Should show: "Pi Coding Agent: pi-lean-ctx installed"

### Still high tokens?

Check if compression is working:
```bash
lean-ctx gain
# Should show token savings
```

If zero savings, extension might not be active. Reinstall:
```bash
lean-ctx init --agent pi
```

## Summary

**Root cause:** Missing instructions in global AGENTS.md

**Fix:** Added LeanCTX section to ~/.pi/agent/AGENTS.md

**Result:** Every pi session now includes instructions to use ctx_* tools

**Next step:** Restart pi, verify it uses ctx_* tools, check savings with `lean-ctx gain`

This should finally deliver the promised 70-80% token reduction. 🎯
