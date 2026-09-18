# Extension Migration

## Replaced with npm Packages

### todo.ts → @juicesharp/rpiv-todo
**Reason:** Pre-built package has live overlay and better persistence.

**Installation:**
```bash
pi install npm:@juicesharp/rpiv-todo
```

**Migration:**
- Old `/todos` command → Same command
- State persists across `/reload` (improved)
- Live overlay in TUI

### btw.ts → @narumitw/pi-btw  
**Reason:** Battle-tested package with identical functionality.

**Installation:**
```bash
pi install npm:@narumitw/pi-btw
```

**Migration:**
- Old `/btw <question>` → Same command
- Same cheap model selection
- Actively maintained

## Kept Custom Extensions

These provide unique functionality not available in pre-built packages:

- **branch-context.ts** — Token-budgeted branch summaries with custom purpose tracking
- **review.ts** — Pi TUI-integrated PR-style code review
- **model-enhanced.ts** — Enhanced model picker with cost info and thinking levels
- **auto-provider-config.ts** — Auto-sync settings when switching providers
- **protected-paths.ts** — Simple path blocking (or use @gotgenes/pi-permission-system for advanced)

## AGENTS.md Simplification

The LeanCTX section was simplified from 15 lines to 2 lines:
- MCP integration handles everything automatically
- Tool descriptions redundant (shown by pi's tool system)
- "Native tools disabled" is enforcement, not instruction

## setup-leanctx.sh Simplification

Now uses `lean-ctx wrap pi` for automatic configuration:
- Auto-detects pi
- Creates MCP config
- Sets aggressive compression + replace mode
- Simplified from 100+ lines to ~40 lines
