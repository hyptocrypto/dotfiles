# Pi Setup Audit & Optimization

## Current Setup Analysis

### ✅ What You Have (Good)

**Core Configuration:**
- Default model: `claude-sonnet-4-5` (excellent choice)
- Thinking levels configured per model
- Compaction enabled (preserves context)
- Auto-retry enabled
- Nord theme

**Extensions:**
- `subagent` - Task delegation
- `question` - Enhanced questions
- `todo` - Task management
- `web` - Web search
- `git-checkpoint` - Auto-checkpointing
- `confirm-destructive` - Safety gates
- `protected-paths` - Path protection
- `plan-mode` - Planning workflows

**Agents:**
- scout (Haiku) - Fast recon
- planner (Sonnet) - Planning
- worker (Sonnet) - Implementation
- reviewer (Sonnet) - Code review

**AGENTS.md Rules:**
- Stack-aware (Go, Python, Bash, TS/Vue, networking)
- Auto-verification (gofmt, ruff, tsc, shellcheck)
- Planning before action
- Token efficiency guidelines
- Delegation patterns

### ⚠️ Potential Issues

**1. Subagent Overhead**
- Each subagent spawns a new `pi` process
- New context window each time (no shared context)
- Overhead of serializing/deserializing
- Lost conversation history

**2. Model Selection**
- Reviewer uses Sonnet (not Opus) on Claude device
- Could use Opus for critical reviews

**3. Missing Extensions**
- No cost tracking/budgeting
- No session templates for common workflows
- No automatic context optimization

**4. Agent Isolation**
- Agents can't share findings efficiently
- Re-reading same files across agents
- No caching between subagent calls

---

## When Subagents ARE Better

### ✅ Good Use Cases

**1. Parallel Independent Tasks**
```
Task: "Check 3 different microservices for auth bugs"
Better: Use 3 parallel scout agents (run simultaneously)
Why: Saves time, each service is independent
```

**2. Different Skill Sets**
```
Task: "Review this PR for security AND performance"
Better: reviewer (security) + separate performance analysis
Why: Different focus areas, specialized prompts
```

**3. Isolating Expensive Operations**
```
Task: "Search entire codebase for patterns, then refactor"
Better: scout (cheap Haiku) finds files → worker refactors
Why: Haiku is 10x cheaper for search, Sonnet for smart edits
```

**4. Multi-Step with Context Reset**
```
Task: "Plan → Implement → Review"
Better: planner → worker → reviewer chain
Why: Each step starts fresh, no context pollution
```

**5. Keep Main Context Clean**
```
Task: "Deep dive into 50 files, summarize findings"
Better: scout reads all → returns compressed summary
Why: Main context doesn't fill with file dumps
```

---

## When Subagents ARE WORSE

### ❌ Bad Use Cases

**1. Single Coherent Task**
```
Task: "Refactor this function to add caching"
Worse: Using subagents
Better: Just Sonnet (keeps full context, fewer hops)
Why: Added overhead, lost context, more tokens overall
```

**2. Iterative Debugging**
```
Task: "Fix this bug" (requires back-and-forth)
Worse: worker → reviewer → worker loop
Better: Single Opus session (maintains state)
Why: Subagents lose conversation history
```

**3. Small Tasks**
```
Task: "Add a TODO comment"
Worse: Using any subagent
Better: Main model directly
Why: Overhead > benefit
```

**4. When You Need Thinking**
```
Task: "Design this complex architecture"
Worse: Subagents (Haiku can't think deeply)
Better: Opus with high thinking level
Why: Subagents can't access thinking levels properly
```

**5. Shared Context Required**
```
Task: "Refactor 3 related files maintaining consistency"
Worse: 3 parallel workers
Better: Single Sonnet (sees all files)
Why: Needs to understand relationships
```

---

## Actual Cost Analysis

### Token Costs (Rough Math)

**Scenario: Search 20 files, refactor 3**

**Option 1: Just Sonnet**
```
Input:  ~50k tokens (20 files read)
Output: ~10k tokens (3 refactors + explanation)
Cost:   ~$0.75
Time:   2-3 minutes
```

**Option 2: Scout → Worker**
```
Scout input:  ~50k tokens (20 files)
Scout output: ~5k tokens (compressed summary)
Worker input: ~10k tokens (summary + task)
Worker output: ~10k tokens (3 refactors)
Cost: ~$0.25 (scout on Haiku) + ~$0.40 (worker) = ~$0.65
Time: 3-4 minutes (extra spawn overhead)
```

**Savings: ~$0.10, but +1 minute and complexity**

**When it matters:**
- Doing this 100 times/day → $10 savings
- One-off task → not worth the complexity

---

## Recommendations

### 🎯 High Priority

**1. Add Cost Budget Extension**
```typescript
// Track spending per session
// Alert when approaching limits
// Auto-switch to cheaper models
```

**2. Optimize Subagent Prompts**
```markdown
# Add to scout.md:
## Critical: Return Minimal Context
Only include code that the next agent MUST see.
Compress aggressively. No full file dumps.
```

**3. Smart Model Selection**
```json
// settings.json - Add model tiers
"modelTiers": {
  "cheap": "claude-haiku-4-5",
  "balanced": "claude-sonnet-4-5",
  "powerful": "claude-opus-4-8"
}
```

**4. Subagent Caching**
Create extension to cache scout results:
```typescript
// If same codebase scouted <5min ago, reuse results
// Saves tokens and time
```

**5. Session Templates**
```markdown
# templates/deep-refactor.md
1. Scout entire codebase (Haiku)
2. Plan changes (Sonnet)
3. Implement (Sonnet)
4. Security review (Opus)
```

### 🔧 Medium Priority

**6. Enhanced Reviewer**
- Use Opus for security reviews
- Add specialized prompts for:
  - SQL injection checks
  - Race condition detection
  - Memory leak patterns

**7. Parallel Scout Optimization**
```markdown
# When scouting multiple modules:
- Spawn scouts in parallel (not serial)
- Merge results efficiently
- Deduplicate findings
```

**8. Context Sharing**
```typescript
// Extension: shared-context.ts
// Let subagents access parent context selectively
// Reduces re-reading same files
```

**9. Metrics Extension**
```typescript
// Track:
// - Subagent success rate
// - Average token usage
// - Cost per task type
// - Time saved vs direct approach
```

### 📚 Nice to Have

**10. Workflow Recorder**
```typescript
// Record successful multi-agent workflows
// Generate reusable templates
// "This worked before, reuse it"
```

**11. Agent Fallback**
```markdown
# If subagent fails, fallback to main model
# Don't leave tasks incomplete
```

**12. Smart Agent Selection**
```typescript
// Analyze task, recommend best approach:
// "This is small, just use Sonnet"
// "This is huge, use scout → worker"
```

---

## Optimized Workflow Patterns

### Pattern 1: Large Codebase Investigation
```
1. scout (Haiku, parallel across modules)
   → compressed findings
2. You review findings in main context
3. planner (Sonnet) creates targeted plan
4. worker (Sonnet) implements
5. reviewer (Opus) security check
```

### Pattern 2: Quick Feature
```
Just use Sonnet directly
(Subagents add overhead for small tasks)
```

### Pattern 3: Critical Refactor
```
1. Opus with high thinking (design)
2. worker (Sonnet) implements each module
3. reviewer (Opus) validates
```

### Pattern 4: Bug Investigation
```
1. scout (Haiku) finds relevant code
2. Opus with high thinking (root cause analysis)
3. worker (Sonnet) fixes
4. Test and validate in main context
```

---

## Recommended Settings Changes

### Update settings.json

```json
{
  "defaultModel": "claude-sonnet-4-5",
  "defaultThinkingLevel": "medium",
  
  // Add these:
  "enabledModels": [
    "anthropic/claude-haiku-4-5",
    "anthropic/claude-sonnet-4-5",
    "anthropic/claude-opus-4-8",
    "anthropic/claude-opus-4-5"
  ],
  
  "modelThinkingLevels": {
    "anthropic/claude-opus-4-8": "high",
    "anthropic/claude-opus-4-5": "high",
    "anthropic/claude-sonnet-4-5": "medium",
    "anthropic/claude-haiku-4-5": "off"
  },
  
  "compaction": {
    "enabled": true,
    "reserveTokens": 32768,  // Increase for bigger context
    "keepRecentTokens": 40000
  },
  
  // New: Task-based model hints
  "autoModelSelection": {
    "enabled": true,
    "patterns": {
      "search|find|locate": "haiku",
      "security|review|audit": "opus",
      "refactor|implement|build": "sonnet"
    }
  }
}
```

### Update AGENTS.md

Add section:
```markdown
## When to Use Subagents

Use subagents when:
✓ Task can be parallelized
✓ Different models needed (cheap search + smart edit)
✓ Context needs reset (fresh perspective)
✓ Main context would get polluted

DON'T use subagents when:
✗ Task is small/simple
✗ Requires iterative back-and-forth
✗ Need to maintain conversation state
✗ All steps need same context
```

---

## Cost vs Performance Trade-offs

### Your Stack (Go, Python, TS, Networking)

**Typical Tasks:**

| Task | Recommended Approach | Why |
|------|---------------------|-----|
| "Add HTTP endpoint" | Sonnet direct | Small, needs context |
| "Find all SQL queries" | scout → you decide | Cheap search, manual triage |
| "Refactor auth system" | Opus with thinking | Architecture, high stakes |
| "Fix bug in handler" | Sonnet direct | Iterative debugging |
| "Review PR (security)" | reviewer (Opus) | Worth the cost |
| "Search 10 repos" | parallel scouts | Time savings |
| "Add unit tests" | worker (Sonnet) | Isolated, clear task |

---

## Bottom Line: When Are Subagents Worth It?

### ✅ Use Subagents When:

1. **Cost matters and task is parallelizable**
   - Searching many files → Haiku scout
   - Main work → Sonnet
   
2. **Different expertise needed**
   - Security review → Opus reviewer
   - Implementation → Sonnet worker

3. **Main context getting bloated**
   - Scout compresses findings
   - You get summary, not raw files

4. **Truly independent subtasks**
   - Parallel scouts across microservices
   - Parallel workers on isolated modules

### ❌ Skip Subagents When:

1. **Task is small** (< 5 minutes)
2. **Need conversation history**
3. **Iterative/debugging** work
4. **All steps need same full context**
5. **Time is more valuable than cost**

---

## Recommended Next Steps

### Immediate (Today):

1. ✅ Update reviewer to use Opus on Claude device
2. ✅ Add clearer subagent guidelines to AGENTS.md
3. ✅ Test one subagent workflow end-to-end

### This Week:

4. 📊 Track actual costs (add metrics extension)
5. 🎯 Create workflow templates for common tasks
6. 🔧 Optimize subagent prompts (more compression)

### Nice to Have:

7. 💰 Cost budget extension
8. 🤖 Smart model selector
9. 📈 Workflow analytics

---

## Summary

**Your setup is solid.** Main improvements:

1. **Use subagents strategically, not dogmatically**
   - Big, parallelizable tasks → Yes
   - Quick edits → No, just Sonnet

2. **Upgrade reviewer to Opus**
   - Security is worth the cost

3. **Add metrics**
   - Track whether subagents actually save money/time

4. **Better decision framework**
   - Guidelines in AGENTS.md
   - Auto-suggestions based on task

**The multi-agent approach is powerful but has overhead. Use it when the benefits (cost, parallelism, specialization) exceed the costs (spawning, context loss, complexity).**
