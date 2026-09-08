# Global working rules

These apply to every project unless a project's own AGENTS.md overrides them.

## Stack

Primary languages: **Go, Python, Bash, JavaScript/TypeScript (Vue)**, plus a lot
of **networking** work (HTTP servers/clients, sockets, protocols, packet
handling, CLIs). Match the existing conventions and style of whatever repo you
are in. Prefer the standard library and existing dependencies over adding new
ones.

## Verify your own work (do this automatically)

After you finish editing code — before telling me you're done — run the relevant
checks for the languages you touched, without being asked. Only run checks for
tools that are actually installed; if a tool is missing, skip it and say so.

- **Go:** `gofmt -l <files>` (or `gofmt -w`), `go build ./...`, `go vet ./...`,
  and `go test ./...` when tests are relevant.
- **Python:** `ruff check` and `ruff format --check` (or `--fix`/format), and run
  tests (`pytest`) when relevant.
- **JS/TS/Vue:** `tsc --noEmit` or `vue-tsc --noEmit`, the project's linter, and
  tests when relevant.
- **Bash:** `bash -n <script>` and `shellcheck <script>` if available.

Report a short "Checks run" summary with pass/fail (and note anything skipped
because the tool isn't installed). If a check fails, fix it and re-run before
finishing. Don't declare success on code that doesn't build/lint/pass.

Note: not every device has every language server/linter installed. Detect and
degrade gracefully rather than erroring out.

## Planning & clarifying questions

For any non-trivial task, investigate first (read the code, don't guess), then
**ask clarifying questions before committing to an approach**. Present questions
as a short numbered list where each has concrete lettered options with a
recommended default, e.g.:

```
1. Which retry strategy?
   a) exponential backoff w/ jitter  (recommended)
   b) fixed interval
   c) none
```

Wait for answers on meaningful decisions. If I say "you decide," proceed with the
recommended defaults and state what you chose. Use `/plan` for read-only
exploration + a reviewable checklist before making changes.

## Delegation & model tiering (keep it cheap)

The default model is **Sonnet**. Escalate to **Opus** (Ctrl+L) only for genuinely
hard reasoning, tricky debugging, or architecture. Use the `subagent` tool to
keep the main context small and push cheap/parallelizable work down a tier:

- **scout** (Haiku/Gemini Flash) — fast recon, locating code, compressed context dumps.
- **planner** (Sonnet) — turn findings into a concrete plan.
- **worker** (Sonnet) — implement well-scoped tasks in isolation.
- **reviewer** (Opus) — security/quality/networking review with deep analysis.

Prefer delegating bulk searching/reading to `scout` instead of reading many files
into the main context. Run independent investigations in parallel.

### When to Use Subagents

Use subagents when:
✓ Task can be parallelized (multiple independent modules)
✓ Different models needed (cheap search + smart implementation)
✓ Context needs reset (fresh perspective on each subtask)
✓ Main context would get polluted with bulk file reading
✓ Cost savings matter (Haiku is 10x cheaper than Sonnet)

DON'T use subagents when:
✗ Task is small/simple (< 5 minutes)
✗ Requires iterative back-and-forth debugging
✗ Need to maintain conversation state
✗ All steps need the same full context
✗ Time is more valuable than cost (~1 min overhead per subagent)

See `DECISION-FRAMEWORK.md` for detailed guidance.

## Token efficiency

- Be concise. Don't restate the plan, the file contents, or my request back to me.
- Read narrowly (use offsets/line ranges, grep) rather than dumping whole files.
- Don't re-read files you already have in context.
- Prefer `rg`/`grep`/`find` over reading directories file by file.
- Skip preamble and filler; lead with the answer or the change.

## Extra tools available

- **question** — ask the user a question with selectable options (they can pick
  or type their own). Prefer this over free-text questions when a decision has a
  small set of choices. Put the recommended option first.
- **web_search / web_fetch** — search the web and read pages. Use for current
  docs, library APIs, error messages, and facts you're unsure about. `web_search`
  uses the Brave API if `BRAVE_API_KEY` is set, otherwise a keyless DuckDuckGo
  fallback. Don't guess at external API behavior — look it up.
- **subagent** — delegate to scout/planner/worker/reviewer (see below).

## Networking specifics

When writing or reviewing networking code, always consider: context/timeout
propagation and cancellation, retries/backoff, connection and goroutine leaks,
TLS verification, partial reads/writes, bounds on parsed input, and clear error
wrapping.

## Editor note

The prompt editor is in **vim modal mode**. `Ctrl+C` cancels the current
operation (not `Escape`). `Escape` just switches to NORMAL mode.
