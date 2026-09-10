# Branch Context Extension - Installation

## Quick Install

Extension is already included in this dotfiles repo. Just run the install script:

```bash
cd ~/dev/dotfiles/pi
./install.sh
```

This copies all extensions (including branch-context.ts) to `~/.pi/agent/extensions/`.

## Verify Installation

Check that the extension file exists:

```bash
ls -l ~/.pi/agent/extensions/branch-context.ts
```

Should show:
```
-rw-r--r--  1 user  staff  11K Sep 10 09:48 /Users/user/.pi/agent/extensions/branch-context.ts
```

## Test It

1. **Create or switch to a feature branch:**
   ```bash
   git checkout -b test-branch main
   # Make some changes
   git commit -m "test changes"
   ```

2. **Start pi:**
   ```bash
   pi
   ```

3. **Look for notification:**
   ```
   ✓ Branch context generated for test-branch (vs main)
   ```

4. **Verify context was injected:**
   ```
   You: "/branch-context"
   
   Agent: [shows generated context]
   ```

## Troubleshooting

### Extension not loading

**Check if extension is in the right place:**
```bash
ls ~/.pi/agent/extensions/branch-context.ts
```

**Check pi logs for errors:**
```bash
pi --verbose
```

### "subagent" tool not found

The extension uses the subagent tool to invoke scout agent. Ensure:

1. **Subagent extension is installed:**
   ```bash
   ls ~/.pi/agent/extensions/subagent/
   ```

2. **Scout agent exists:**
   ```bash
   ls ~/.pi/agent/agents/scout/
   ```

If missing, re-run install script:
```bash
cd ~/dev/dotfiles/pi
./install.sh
```

### Context not generating

**Check you're on a feature branch:**
```bash
git branch --show-current
```

Should NOT be: main, master, development, develop, dev

**Check git repository:**
```bash
git status
```

Extension only works in git repositories.

**Manually test git commands:**
```bash
# Get current branch
git rev-parse --abbrev-ref HEAD

# Get default branch
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'

# Get diff
git diff main...$(git rev-parse --abbrev-ref HEAD)
```

### Scout agent fails

**Test scout agent manually:**
```bash
echo "Test task" | pi --agent scout --print
```

If it fails, scout agent may not be configured. Check:
```bash
cat ~/.pi/agent/agents/scout/agent.md
```

Should contain valid agent configuration.

## Uninstall

To disable the extension without removing it:

1. **Edit settings:**
   ```bash
   nano ~/.pi/agent/settings.json
   ```

2. **Remove from extensions array:**
   ```json
   {
     "extensions": [
       // Remove or comment out "branch-context"
     ]
   }
   ```

Or remove the file entirely:
```bash
rm ~/.pi/agent/extensions/branch-context.ts
```

## Re-enable After Uninstall

Re-run install script to restore:
```bash
cd ~/dev/dotfiles/pi
./install.sh
```

## Configuration

No configuration needed - works out of the box.

**Optional customization** (edit the extension file):

```typescript
// Adjust token budget for context summary
const CONTEXT_TOKEN_BUDGET = 2000; // Increase for very large branches

// Modify cache directory
const CACHE_DIR = path.join(os.homedir(), ".pi", "branch-context");
```

After editing, restart pi:
```bash
/quit
pi
```

## Cache Management

### View cached contexts

```bash
ls -lh ~/.pi/branch-context/
```

### Clear cache for a branch

```bash
rm ~/.pi/branch-context/feature-xyz.json
```

Next chat will regenerate.

### Clear all caches

```bash
rm -rf ~/.pi/branch-context/
```

All branches will regenerate on next use.

## Updates

To update to latest version:

```bash
cd ~/dev/dotfiles
git pull
cd pi
./install.sh
```

Extension will be updated automatically.

## Support

See:
- `README-branch-context.md` - Full documentation
- `EXAMPLE-branch-context.md` - Usage examples
- `../COMMANDS.md` - All available commands
- `../README.md` - Pi setup guide

Or check the extension code:
```bash
cat ~/.pi/agent/extensions/branch-context.ts
```
