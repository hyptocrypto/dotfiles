# Custom Commands Reference

This document describes custom commands added via extensions.

## Quick Reference

**Model switching:** Use `/m` (or `/pick`) instead of `/model` for enhanced experience
- Shows cost info inline
- Interactive thinking level selection
- Shows available models

**Quick questions:** Use `/btw <question>` for one-off questions to cheap models

**Account usage:** Use `/usage` for account-wide usage limits (not session-scoped)

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

## Account Usage

### `/usage`

Show account-wide usage information and limits.

**Important:** This shows ACCOUNT-level usage, not session usage. Use `/session` for session-specific info.

**Displays:**
- **Claude Subscription (OAuth):** References footer for live usage limits
- **Claude API (Admin Key):** Total tokens and cost for last 7 days
- **Copilot:** AI credits used/remaining (requires org/enterprise)
- **Other Providers:** Links to provider dashboards

**Example Output (Claude Subscription):**
```
📊 Account Usage

Claude Account:

Claude Subscription:

✅ Live usage limits shown in footer (🧠)

The footer shows:
  • 5h    = 5-hour rolling window
  • wk    = Weekly all-models limit
  • opus/sonnet = Per-model weekly limits

⚠️  If you see extra usage warning, you've exceeded subscription limits
```

**Example Output (Claude API with Admin Key):**
```
📊 Account Usage

Claude Account:

Recent Usage (last 7 days):

Total Tokens:     2.5M
Total Cost:       $12.45

For detailed breakdown:
  https://console.anthropic.com/settings/cost
```

**Example Output (Copilot - Org/Enterprise):**
```
📊 Account Usage

GitHub Copilot Account:

AI Credits Used:  1.2k
Credits Remaining: 8.8k
Period: Current billing cycle

For detailed breakdown:
  https://github.com/settings/copilot
```

**Example Output (Copilot - Individual):**
```
📊 Account Usage

GitHub Copilot Account:

ℹ️  Usage data not available

Copilot usage API requires:
  • Enterprise or Organization account
  • 'Copilot usage metrics' policy enabled
  • Appropriate permissions

Check your account at:
  https://github.com/settings/copilot
```

**Important Notes:**

**Claude:**
- **Subscription (OAuth)**: Live limits shown in footer, `/usage` references it
- **API Key (Admin)**: Requires Admin API key (sk-ant-admin01-...) for account data
- **API Key (Regular)**: Only session data available (use `/session`)

**Copilot:**
- **Enterprise/Org**: Usage API available with proper permissions
- **Individual**: No programmatic usage API, check website

**For session data** (any provider): Use `/session` command

---

## Enhanced Model Picker

### `/m` or `/pick`

Enhanced interactive model picker with cost information and thinking level selection.

**Note:** Extensions cannot override the built-in `/model` command, so use `/m` or `/pick` for the enhanced experience.

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
