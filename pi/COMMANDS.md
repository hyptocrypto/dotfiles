# Custom Commands Reference

This document describes custom commands added via extensions.

## Quick Reference

**Model switching:** Use `/m` (or `/pick`) instead of `/model` for enhanced experience
- Shows cost info inline
- Interactive thinking level selection
- Shows available models

**Quick questions:** Use `/btw <question>` for one-off questions to cheap models

**Branch context:** Automatic feature branch context injection
- `/branch-context` - Show current cached context
- `/refresh-branch-context` - Regenerate context
- `/set-branch-purpose "<purpose>"` - Set custom purpose

## Quick Questions

### `/btw <question>`

**By The Way** - Ask a quick one-off question to a cheap model without interrupting your current session.

**Features:**
- Uses cheapest model for your provider (Haiku on Claude, Gemini Flash on Copilot)
- Non-blocking (doesn't interrupt current prompt)
- Shows answer in notification popup
- Doesn't affect session transcript or history

**Examples:**
```
/btw what is the capital of France?
/btw how do I reverse a string in Python?
/btw explain the difference between TCP and UDP
```

**Response:**
- Shows "Thinking..." notification while processing
- Displays answer in popup (truncated to 500 chars if long)
- Timeout after 30 seconds

---



## Enhanced Model Picker

### `/m` or `/pick`

Enhanced interactive model picker with cost information and thinking level selection.

**Note:** Extensions cannot override the built-in `/model` command, so use `/m` or `/pick` for the enhanced experience.

**Requirements:**
- Models must be configured in `enabledModels` in your `settings.json`
- Only shows models that are explicitly enabled (prevents selecting unavailable models)
- If no models enabled, shows helpful message with setup instructions

**Features:**
- Shows only enabled models (from settings.json)
- Displays cost per million tokens inline
- Interactive thinking level selection for reasoning models
- Two-step selection: model first, then thinking level

**Flow:**
1. Run `/m` (or `/pick`)
2. Select from enabled models (shows cost info)
3. If reasoning model: select thinking level
4. Done! Model and thinking level are switched

**Example:**
```
Select model:
→ anthropic/claude-sonnet-4-5 [in:$3 out:$15/1M]
  anthropic/claude-haiku-4-5 [in:$0.40 out:$2/1M]
  anthropic/claude-opus-4-8 [in:$15 out:$75/1M]

Thinking level for claude-sonnet-4-5:
  Off - No extended reasoning
  Minimal - Quick tasks
  Low - Simple problems
→ Medium - Balanced (recommended)
  High - Complex reasoning
  Extra High - Very difficult
  Max - Hardest problems

✓ Switched to anthropic/claude-sonnet-4-5 (medium)
```



---

## Branch Context (Auto-Injected)

### Auto-Injection on Chat Start

When working on a feature branch, context is automatically generated and injected at chat start. No manual setup needed.

**How it works:**
1. Detects you're on a feature branch (not main/master/development/etc)
2. Loads cached context or generates fresh summary using scout agent
3. Injects ~2000 token compressed summary into system prompt
4. Shows notification: "Branch context loaded for feature-xyz"

**Automatic detection:**
- Finds base branch via origin/HEAD or common names (main, master, development, develop, dev)
- Works with any repository's branch naming convention
- Only activates on feature branches (skips if on default branch)

### `/branch-context`

Show the current cached context for your branch.

**Example:**
```
You: "/branch-context"

Agent:
**Branch:** feature-api-v2
**Base:** development
**Cached:** 2024-01-15 14:32:11

## Purpose
Complete rewrite of REST API to v2 with GraphQL support...

## Key Changes
1. New API v2 implementation (28 files)
2. Rate limiting system
3. Authentication middleware refactor
...
```

### `/refresh-branch-context`

Force regeneration of branch context. Use after:
- Merging main/development into your branch
- Making major changes
- Want fresher summary

**Example:**
```
You: "/refresh-branch-context"

Agent: "Regenerating context for feature-api-v2..."
[Scout agent analyzes diff, commits, changed files]
Agent: "✓ Context refreshed"
[Shows updated context]
```

### `/set-branch-purpose "<purpose>"`

Override the auto-detected branch purpose with a custom note. Useful for providing human context that git history doesn't capture.

**Example:**
```
You: "/set-branch-purpose 'Rewrite auth system to use Redis sessions instead of JWT'"

Agent: "✓ Updated purpose for feature-api-v2"
```

**Custom purpose persists:**
- Saved in cache across chats
- Included in context regeneration
- Scout agent uses it when analyzing branch

### Token Savings

**Without extension (manual approach):**
```
You: "I'm working on the API v2 refactor. Run git diff development..."
Agent: <reads 5000+ tokens of diff>
You: "This branch rewrites the REST API to support..."
[More back and forth]

Total: ~6000 tokens before real work
```

**With extension (automatic):**
```
[Auto-injected at chat start]
## Purpose: API v2 rewrite with GraphQL
## Key Changes: [compressed summary]
## Changed Files: [grouped by area]

Total: ~2000 tokens, zero manual setup
Savings: 70% fewer tokens
```

### Use Cases

**Best for:**
- ✅ Long-running feature branches (>1 week)
- ✅ Large changes (1000+ lines, 10+ files)
- ✅ Frequent chat context switches
- ✅ Team members jumping into unfamiliar branches
- ✅ Branches with complex purpose/architecture

**Not needed for:**
- ❌ Quick bug fixes (1-2 files)
- ❌ On main/master/development branch
- ❌ Experimental throwaway branches
- ❌ Branches lasting <1 day

### How It Works

**First chat on branch:**
1. Extension detects feature branch
2. Computes diff hash: `md5(git diff base...feature)`
3. Invokes scout agent with:
   - Changed files list
   - Diff stats
   - Commit log
   - Custom purpose (if set)
4. Scout generates compressed summary (~2000 tokens)
5. Caches in `~/.pi/branch-context/<branch>.json`
6. Injects into system prompt

**Subsequent chats:**
1. Loads cached context (instant)
2. Checks diff hash
3. If unchanged: uses cache
4. If changed: regenerates automatically

**Cache invalidation:**
- Diff hash changes → auto-regenerate
- Manual `/refresh-branch-context` → force regenerate
- Custom purpose change → regenerate on next refresh

### Examples

See `extensions/EXAMPLE-branch-context.md` for detailed scenarios with 16k+ line branches.

---

## Built-in Commands (for reference)

These are built into pi:

- `/model` - Built-in model picker (basic)
- `/thinking` - Change thinking level directly (off, minimal, low, medium, high, xhigh, max)
- `/session` - Show session info (file, ID, messages, tokens, cost)

**Enhanced alternatives (via extensions):**
- `/m` or `/pick` - Enhanced model picker with costs and thinking levels

---

## Cost Comparison

### Quick Reference

| Model | Use Case | Input Cost | Output Cost |
|-------|----------|------------|-------------|
| Haiku 4-5 | Search, quick tasks | $0.40/1M | $2.00/1M |
| Sonnet 4-5 | Most work | $3.00/1M | $15.00/1M |
| Opus 4-8 | Complex, critical | $15.00/1M | $75.00/1M |
| Gemini 3.8 Flash | Search (Copilot) | ~$0.10/1M | ~$0.50/1M |

### When to Use /btw

**Good for:**
- ✅ Quick factual questions ("what is X?")
- ✅ Simple how-to ("how do I...")
- ✅ Clarifications without context
- ✅ One-off queries while working on something else

**Not good for:**
- ❌ Questions needing current session context
- ❌ Complex reasoning or analysis
- ❌ Multi-step interactions
- ❌ Code generation needing project context

**Cost savings example:**
- `/btw` with Haiku: ~$0.002 per question
- Main Sonnet session: ~$0.015 per similar question
- Savings: ~7x cheaper for simple questions

---

## Tips

### Workflow Optimization

1. **Use /btw for quick lookups** while working on a complex task in main session
2. **Check /costs before starting** expensive operations (helps choose right model)
3. **Monitor with /usage** periodically if on pay-per-use API
4. **Use /thinking** to lower reasoning cost for simple tasks

### Cost Management

**For Claude API users:**
- Use Haiku for search/exploration (10x cheaper)
- Use Sonnet for most coding (balanced)
- Reserve Opus for architecture/security (expensive)
- Monitor with `/usage` to track spend

**For subscriptions (Claude Pro/Copilot):**
- `/btw` still useful for speed (Haiku is faster)
- `/usage` shows session activity
- Cost numbers shown but you're on flat rate
- No need to optimize cost, but speed/quality still matters

---

## Troubleshooting

### `/btw` issues

**"Failed to spawn pi"**
- Ensure `pi` is in your PATH
- Try running `which pi` to verify

**"Request timed out"**
- Question took > 30 seconds
- Try simplifying the question
- Use main session for complex queries

**"No response from model"**
- Model may not be available
- Check `/model` to see available models
- Try the main session instead

### `/usage` issues

**"No usage in current session"**
- You haven't sent any messages yet
- Usage tracked from assistant responses

**Account info not showing**
- Claude subscription: Check footer for live usage (🧠)
- Copilot: Account totals not available via API
- API keys: Only session totals available

### `/model+` or `/costs` issues

**Not showing all models**
- Only shows models you have access to
- Run `/model` to see the actual picker
- Check `/login` if models are missing

---

## See Also

- `AUDIT.md` - Full pi setup audit
- `DECISION-FRAMEWORK.md` - When to use subagents vs direct
- `README.md` - Main setup documentation
- `AGENTS.md` - Global agent rules and guidelines
