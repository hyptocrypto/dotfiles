# Should I Use Subagents? - Decision Framework

Quick guide to decide when to use subagents vs. single model.

## 30-Second Decision Tree

```
Is the task < 5 minutes?
├─ YES → Use Sonnet directly
└─ NO → Continue...

Does it need back-and-forth iteration?
├─ YES → Use Opus/Sonnet directly
└─ NO → Continue...

Can it be split into independent parts?
├─ YES → Use subagents! ✓
└─ NO → Continue...

Is search/recon a major part?
├─ YES → scout (Haiku/Gemini) → worker (Sonnet) ✓
└─ NO → Use Sonnet directly
```

## Examples from Your Stack

### 🔍 Go Projects

**Scenario: "Find all HTTP handlers and add rate limiting"**
```
✓ USE SUBAGENTS
1. scout: Find all http.HandleFunc, gin.Router, etc.
2. You: Review findings, decide strategy
3. worker: Implement rate limiting for each
4. reviewer: Security check

Why: Large codebase search (Haiku/Gemini saves $), then targeted work
```

**Scenario: "Fix this nil pointer panic"**
```
✗ DON'T USE SUBAGENTS
Just use Sonnet (or Opus if tricky)

Why: Debugging needs iteration, context, conversation
```

### 🐍 Python Projects

**Scenario: "Audit all SQL queries for injection risks"**
```
✓ USE SUBAGENTS
1. scout: Find all SQL execution (grep + read)
2. reviewer (Opus): Security analysis
3. worker: Fix vulnerabilities

Why: Search is cheap, security review worth Opus
```

**Scenario: "Refactor this class to use dependency injection"**
```
✗ DON'T USE SUBAGENTS
Just use Sonnet

Why: Need full context, single coherent refactor
```

### 🌐 Networking Code

**Scenario: "Review 5 microservices for timeout handling"**
```
✓ USE SUBAGENTS (PARALLEL)
1. scout × 5 (parallel): Check each service
2. You: Review findings
3. worker × N: Fix issues
4. reviewer: Validate fixes

Why: Independent services, parallel saves time
```

**Scenario: "Debug this connection leak"**
```
✗ DON'T USE SUBAGENTS
Use Opus with high thinking

Why: Complex debugging, need deep reasoning
```

### 📱 TypeScript/Vue

**Scenario: "Add TypeScript types to 20 components"**
```
✓ USE SUBAGENTS
1. scout: List all untyped components
2. worker: Type each component

Why: Repetitive, isolated work
```

**Scenario: "Build new form with validation"**
```
✗ DON'T USE SUBAGENTS
Just use Sonnet

Why: Single cohesive feature
```

## Cost Comparison Calculator

### Task Size

| Files to Read | Lines of Code | Tokens (approx) | Model Choice |
|---------------|---------------|-----------------|--------------|
| 1-3 files | < 500 lines | ~10k | Sonnet direct |
| 4-10 files | 500-2k lines | ~30k | Scout + Sonnet |
| 10+ files | 2k+ lines | ~50k+ | Parallel scouts |

### Cost Estimates

**Sonnet Direct (50k input, 10k output):**
- Cost: ~$0.75
- Time: 2-3 min

**Scout → Sonnet (scout 50k → 5k summary, worker 10k → 10k):**
- Cost: ~$0.25 (scout) + $0.40 (worker) = ~$0.65
- Time: 3-4 min
- Savings: ~$0.10

**Worth it if:**
- You do this task 10+ times/day
- Time isn't critical
- Context stays cleaner

## Model Selection Guide

### Haiku (Cheap, Fast)
```
✓ Search/find/locate
✓ List/enumerate
✓ Quick checks
✓ Pattern matching
✗ Complex reasoning
✗ Architecture decisions
✗ Security reviews
```

### Sonnet (Balanced)
```
✓ Most implementation tasks
✓ Refactoring
✓ Code generation
✓ Planning
✓ Normal reviews
✗ Critical security
✗ Complex architecture
```

### Opus (Powerful, Expensive)
```
✓ Architecture design
✓ Security audits
✓ Complex debugging
✓ Critical reviews
✓ Performance optimization
✗ Simple edits
✗ Routine tasks
```

## Red Flags: Don't Use Subagents

❌ **"I need to see the output and iterate"**
→ Use single model (maintains conversation)

❌ **"This depends on decisions I'll make mid-task"**
→ Use single model (adaptive)

❌ **"The task is vague/exploratory"**
→ Use single model (can pivot)

❌ **"Everything depends on everything else"**
→ Use single model (needs full context)

❌ **"I'm debugging something tricky"**
→ Use Opus (needs deep reasoning)

## Green Lights: Use Subagents

✅ **"I need to check 10 different files/services"**
→ Parallel scouts

✅ **"Search is 80% of the work"**
→ scout (Haiku) → you decide next

✅ **"I need both speed AND cost savings"**
→ scout finds, worker implements

✅ **"Independent modules need same changes"**
→ Parallel workers

✅ **"This is a multi-stage pipeline"**
→ Chain: scout → planner → worker → reviewer

## Common Patterns

### Pattern: Large Codebase Refactor
```bash
# Good use of subagents
Use scout to find all occurrences
Review findings yourself
Use worker for each file/module
Use reviewer for security check
```

### Pattern: Quick Feature
```bash
# Skip subagents
Just use Sonnet directly
Faster, simpler, good enough
```

### Pattern: Security Audit
```bash
# Good use of subagents
Use scout (Haiku) to find all auth code
Use reviewer (Opus) for deep analysis
Worth the cost for security
```

### Pattern: Bug Fix
```bash
# Skip subagents
Use Sonnet or Opus directly
Need conversation, iteration, context
```

## Your Copilot vs Claude Devices

### Copilot Device

**Has:** Gemini Flash (fast), Claude Sonnet 5, Claude Opus 5

**Use subagents when:**
- Search with Gemini Flash (super cheap)
- Implement with Sonnet 5
- Review with Opus 5

**Skip when:**
- No Haiku equivalent (Gemini Flash closest)
- Opus 5 is expensive (use sparingly)

### Claude Device

**Has:** Haiku 4-5 (cheapest), Sonnet 4-5, Opus 4-8

**Use subagents when:**
- Haiku for search (10x cheaper than Sonnet)
- Sonnet for implementation
- Opus for critical reviews

**Skip when:**
- Task is small (setup overhead)
- Need thinking levels (doesn't propagate well)

## Rule of Thumb

**Cost-Driven Decision:**
```
Daily tasks × Cost savings = Worth it?
10/day × $0.10 = $1/day = $20/month = YES
1/day × $0.10 = $0.10/day = $2/month = NO
```

**Time-Driven Decision:**
```
Is saving $0.10 worth 1 extra minute?
Depends on your hourly rate:
$60/hr → NO ($1/min > $0.10)
$6/hr → YES ($0.10/min < $0.10)
```

**Quality-Driven Decision:**
```
Does specialization improve output?
Security review → Opus (YES)
Pattern search → Haiku (SAME QUALITY)
```

## Final Checklist

Before using subagents, ask:

- [ ] Task is > 5 minutes
- [ ] Can be split into independent parts
- [ ] Doesn't need iterative conversation
- [ ] Cost/time savings worth the complexity
- [ ] Different models bring different value

If 3+ are YES → Use subagents
If 2 or fewer → Use single model

---

**Remember: Subagents are a tool, not a requirement. Most tasks are fine with just Sonnet.**
