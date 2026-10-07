---
description: Fast fresh-context review before commit (blockers only)
---
Use "reviewer" agent with fresh context to check current uncommitted diff.

Focus: P0 blockers only
- Obvious bugs or regressions
- Missing error handling at trust boundaries
- Test coverage for new behavior
- Secrets/credentials in code
- Breaking changes without migration

Return only issues that must be fixed before commit. No optional suggestions.

Target: $@
