---
description: Complete workflow - scout, plan, implement, parallel review, apply fixes
---
Execute a complete implementation workflow using subagents:

1. **Scout**: Use "scout" agent to gather context about: $@
2. **Plan**: Use "planner" agent to create implementation plan using scout's findings
3. **Implement**: Use "worker" agent to implement the plan
4. **Review**: Launch 3 parallel "reviewer" agents with fresh context:
   - Correctness and regressions
   - Tests and validation
   - Simplicity and maintainability
5. **Fix**: Apply synthesized review feedback with "worker" agent

Execute as an async workflow with chain for scout→planner→worker, then parallel reviewers, then fix worker.

Report: final diff, validation results, deferred items, and merge verdict.
