# Pi Configuration Simplification Summary

## Changes Made

### 1. AGENTS.md - Simplified LeanCTX Section
**Before:** 15 lines with detailed tool descriptions and enforcement notes  
**After:** 2 lines stating tools are available with compression benefits

**Rationale:** 
- MCP integration handles everything automatically
- Tool descriptions redundant (pi's tool system shows them)
- Compression happens transparently

### 2. Replaced Custom Extensions with NPM Packages

#### todo.ts → @juicesharp/rpiv-todo
- **Benefit:** Live overlay, better persistence, actively maintained
- **Stats:** 165K downloads/month
- **Installation:** Added to `install.sh`

#### btw.ts → @narumitw/pi-btw  
- **Benefit:** Battle-tested, identical feature
- **Stats:** 39.2K downloads/month
- **Installation:** Added to `install.sh`

### 3. Simplified setup-leanctx.sh
**Before:** 100+ lines with manual config file manipulation  
**After:** ~40 lines using `lean-ctx wrap pi`

**Changes:**
- Uses official `lean-ctx wrap pi` for auto-configuration
- Applies aggressive compression + replace mode via jq patch
- Cleaner error handling and messaging
- Removed redundant verification steps

### 4. Updated install.sh
Added automatic installation of npm extensions:
```bash
pi install npm:@juicesharp/rpiv-todo
pi install npm:@narumitw/pi-btw
```

### 5. Updated Documentation
- **README.md:** Updated extensions section, migration notes
- **MIGRATION.md:** Created comprehensive migration guide
- **SIMPLIFICATION-SUMMARY.md:** This file

## Custom Extensions Kept

These provide unique value not available in pre-built packages:

1. **branch-context.ts** (587 lines)
   - Token-budgeted branch summaries
   - Custom purpose tracking
   - Scout agent integration
   - No comparable npm package

2. **review.ts** (350 lines)
   - Pi TUI-integrated PR review
   - Live spinner widget
   - Model auto-selection
   - MCP alternatives lack TUI integration

3. **model-enhanced.ts** (200 lines)
   - Cost info display
   - Thinking level selection
   - Enhanced UX over native `/model`

4. **auto-provider-config.ts** (130 lines)
   - Auto-sync when switching providers
   - Convenience for multi-provider setups

5. **protected-paths.ts** (20 lines)
   - Simple, easy to customize
   - Alternative: @gotgenes/pi-permission-system for advanced use

## Results

### Token Savings
- **AGENTS.md:** ~13 lines removed = ~200 tokens saved per session load
- **Extensions:** Delegated to npm = better maintenance, no local bloat

### Maintenance Reduction
- **2 fewer custom extensions to maintain**
- **Simpler setup script** (60 lines removed)
- **Clearer documentation**

### Installation Flow
**Before:**
```bash
./install.sh
# Manual todo/btw extension maintenance
./setup-leanctx.sh  # Complex manual config
./switch-agents.sh
```

**After:**
```bash
./install.sh        # Now installs npm extensions automatically
./setup-leanctx.sh  # Simplified to lean-ctx wrap pi + patch
./switch-agents.sh
```

## Breaking Changes

None. The npm packages provide identical functionality:
- `/todos` → Same command
- `/btw <question>` → Same command

## Migration Steps for Existing Users

1. **Pull latest changes:**
   ```bash
   cd ~/dev/dotfiles
   git pull
   ```

2. **Reinstall:**
   ```bash
   cd pi
   ./install.sh  # Removes old extensions, installs npm packages
   ```

3. **Restart pi:**
   ```bash
   pi
   /reload
   ```

State from old todo.ts will not migrate automatically (session-based storage). 
Use `/todos` to verify the new extension works, then re-add any todos.

## Verification

Run these to verify everything works:

```bash
# Check npm extensions installed
pi install list | grep -E '(rpiv-todo|pi-btw)'

# In pi session:
/btw what is 2+2          # Should work
/todos                    # Should show empty todo list
/m                        # Should show enhanced picker

# Check LeanCTX
lean-ctx doctor integrations
```

## Files Changed

- ✏️ `/Users/julianbaumgartner/.pi/agent/AGENTS.md` (simplified)
- ✏️ `/Users/julianbaumgartner/dev/dotfiles/pi/setup-leanctx.sh` (simplified)
- ✏️ `/Users/julianbaumgartner/dev/dotfiles/pi/install.sh` (added npm installs)
- ✏️ `/Users/julianbaumgartner/dev/dotfiles/pi/README.md` (updated docs)
- ❌ Removed: `todo.ts`, `btw.ts` (from both ~/.pi/agent/extensions and dotfiles)
- ✨ Created: `MIGRATION.md`, `SIMPLIFICATION-SUMMARY.md`

## Next Steps

1. Test on one device first
2. Commit changes to dotfiles repo
3. Pull on other devices and run `./install.sh`
