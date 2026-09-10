# Branch Context Extension - Example Usage

This demonstrates the branch-context extension with a realistic feature branch scenario.

## Scenario: Large API Refactor Branch

You're working on `feature-api-v2` with 16,000+ line changes over 3 weeks.

### Without Extension (Old Way)

Every new chat session:

```
You: "I'm working on the API v2 refactor branch. Run git diff development 
     to see what changed. This branch rewrites the REST API to support 
     both REST and GraphQL, adds rate limiting, implements a new auth 
     middleware, updates the database schema, and adds comprehensive 
     tests. The main files are in api/v2/, middleware/auth.go, 
     db/migrations/, and tests/."

Agent: <reads 5000+ tokens of diff output>

Agent: "I see you've made extensive changes. Let me understand..."

[5-10 minutes of back and forth to establish context]

Total cost: 6000+ tokens before doing any real work
```

### With Extension (New Way - Opt-In)

First chat (no context yet):

```bash
$ git checkout feature-api-v2
$ pi

[No auto-injection - opt-in required]

You: "/refresh-branch-context"

Agent: "Regenerating context for feature-api-v2..."
[Scout agent analyzes branch - takes ~2-5 seconds]
Agent: "✓ Context refreshed"
[Shows generated context]

You: "Add rate limiting to the user endpoint"

Agent: [understands branch context, provides implementation]
```

Subsequent chats (context enabled):

```bash
$ pi

[Auto-loads from cache instantly]
✓ Branch context loaded for feature-api-v2 (vs development)

You: "Update the GraphQL schema to support pagination"

Agent: [context already loaded, starts work immediately]
```

After merging development:

```bash
$ git merge development
$ pi

You: "/refresh-branch-context"
Agent: "Regenerating context for feature-api-v2..."
Agent: "✓ Context refreshed"

[Context now includes changes from development merge]
```

## Example Auto-Generated Context

This is what gets injected automatically (compressed by scout agent):

```markdown
# Feature Branch Context

You are working on branch: **feature-api-v2** (vs **development**)

## Purpose
Complete rewrite of REST API to v2 with dual REST/GraphQL support, 
implementing rate limiting, new authentication middleware, and 
comprehensive test coverage for all endpoints.

## Key Changes

1. **New API v2 Implementation**
   - Complete rewrite in `api/v2/` (28 files)
   - Dual protocol support: REST + GraphQL
   - Backward-compatible v1 endpoints maintained

2. **Rate Limiting System**
   - Redis-based distributed rate limiter
   - Per-user and per-IP limits
   - Configurable thresholds per endpoint

3. **Authentication Middleware Refactor**
   - Replaced JWT with session-based auth
   - Added OAuth2 support
   - New permission system with role-based access

4. **Database Schema Changes**
   - 12 new migrations in `db/migrations/`
   - Added `api_keys`, `rate_limits`, `sessions` tables
   - Indexed high-traffic queries

5. **Comprehensive Testing**
   - 156 new integration tests
   - GraphQL query validation tests
   - Rate limit edge case coverage

## Changed Files (Grouped)

**API Core (28 files)**
- `api/v2/*.go` - New v2 handlers and routing
- GraphQL schema definitions and resolvers
- Request/response validation

**Middleware (8 files)**
- `middleware/auth.go` - Session-based authentication
- `middleware/ratelimit.go` - Redis rate limiter
- `middleware/cors.go` - Updated CORS policy

**Database (12 migrations)**
- `db/migrations/` - Schema changes for new features
- Added indexes for GraphQL queries
- Session storage schema

**Tests (45 files)**
- `tests/api/v2/*_test.go` - Endpoint tests
- `tests/graphql/*_test.go` - GraphQL tests
- `tests/integration/ratelimit_test.go` - Rate limit tests

**Configuration**
- `config/api.yaml` - V2 API settings
- `config/ratelimit.yaml` - Rate limit thresholds
- `.env.example` - New environment variables

## Technical Context

**Dependencies Added:**
- `github.com/graphql-go/graphql` - GraphQL support
- `github.com/redis/go-redis/v9` - Rate limiting backend
- `github.com/gorilla/sessions` - Session management

**Breaking Changes:**
- V1 auth endpoints deprecated (still functional)
- New session cookie format (old cookies invalid)
- Rate limits now enforced on all endpoints

**Migration Required:**
Run `make migrate` before deploying to apply 12 new database migrations.

**Environment Variables:**
- `REDIS_URL` - Required for rate limiting
- `SESSION_SECRET` - Required for session auth
- `GRAPHQL_ENABLED` - Toggle GraphQL support (default: true)

---

Use `/refresh-branch-context` if branch changes significantly.
Use `/set-branch-purpose "<purpose>"` to override inferred purpose.
```

## Token Comparison

| Scenario | Without Extension | With Extension | Savings |
|----------|-------------------|----------------|---------|
| **First chat** | ~6000 tokens | ~1800 tokens | 70% |
| **Subsequent chats** | ~6000 tokens | ~1800 tokens | 70% |
| **Time to context** | 5-10 minutes | Instant | 100% |
| **Manual work** | Explain every time | Zero | 100% |

## Real Workflow Example

Day 1 - Starting the branch:
```bash
$ git checkout -b feature-api-v2 development
$ # ... make initial changes ...
$ git commit -m "Initial API v2 structure"
$ pi

[No context yet - working without it for now]

You: "Implement the user endpoint with GraphQL support"
Agent: [works on implementation without branch context]

# After a few days, branch is large enough to benefit from context:
You: "/set-branch-purpose 'API v2 rewrite with GraphQL and rate limiting'"
Agent: "✓ Set purpose for feature-api-v2"

You: "/refresh-branch-context"
Agent: "Regenerating context for feature-api-v2..."
Agent: "✓ Context refreshed"
[Context now enabled for future chats]
```

Day 7 - Mid-feature work:
```bash
$ pi

[Context auto-loaded from cache - instant]
✓ Branch context loaded for feature-api-v2 (vs development)

You: "Add pagination to the GraphQL user query"
Agent: [context already available, starts immediately]
```

Day 14 - After merge conflict with development:
```bash
$ git merge development
$ # ... resolve conflicts ...
$ pi

You: "/refresh-branch-context"
Agent: "✓ Context refreshed"

[Context regenerated to include new changes from merge]
```

Day 21 - Final review:
```bash
$ pi

You: "/branch-context"
Agent: [shows full cached context]

You: "Review the rate limiting implementation for edge cases"
Agent: [uses context to understand which files/tests to check]
```

## Commands In Action

### View Context
```
You: "/branch-context"

Agent:
**Branch:** feature-api-v2
**Base:** development
**Cached:** 2024-01-15 14:32:11

## Purpose
Complete rewrite of REST API to v2...
[full context shown]
```

### Refresh Context
```
You: "/refresh-branch-context"

Agent: "Regenerating context for feature-api-v2..."
[Scout agent analyzes diff]
Agent: "✓ Context refreshed"
[Shows updated context]
```

### Set Custom Purpose
```
You: "/set-branch-purpose 'Rewrite API with GraphQL, rate limiting, and new auth'"

Agent: "✓ Updated purpose for feature-api-v2"
```

## Benefits Demonstrated

1. **Zero Manual Setup**
   - No explaining branch purpose every chat
   - No running manual git diffs
   - No copying commit messages

2. **Instant Context**
   - Chat starts with full understanding
   - Agent knows what files changed and why
   - Agent understands technical decisions

3. **Token Efficiency**
   - 70% fewer tokens vs manual approach
   - Scout agent compresses 16k changes into 2k tokens
   - Cache reuse across multiple chats

4. **Smart Updates**
   - Only regenerates when diff changes
   - Preserves custom notes across refreshes
   - Detects merges and prompts for refresh

5. **Repo Agnostic**
   - Works with any base branch name
   - Auto-detects default branch
   - No configuration needed

## Tips

- Set custom purpose early: `/set-branch-purpose "..."` on day 1
- Refresh after major merges: `/refresh-branch-context`
- Check context if confused: `/branch-context`
- Let it auto-inject - don't manually explain unless needed
- Works best on branches lasting >1 week with >100 commits
