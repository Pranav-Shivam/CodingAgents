# CLAUDE.md

## Agentic Coding Standards

1. **Clarify before building** — State assumptions explicitly; ask once, precisely.
2. **Lean and purposeful code** — Implement exactly what was asked; no gold-plating.
3. **Precise, bounded edits** — Touch only what the task requires; flag, don't fix, unrelated issues.
4. **Outcome-oriented execution** — Define verifiable end state before starting.
5. **Verify and recover** — Run verification after every non-trivial change; never mark done without confirming success.

Full detail: `.claude/rules/principles_v2.md`

**Known failure modes:** unchecked assumptions, session memory decay, phantom API usage, pushback capitulation, scope creep, optimistic execution through ambiguity.

## Further Reading

IMPORTANT: Before starting any task, read relevant docs below first.

- `docs/gotchas.md` — hard-won lessons and non-obvious patterns
- `docs/architecture.md` — repo structure, design rationale, agent relationships

## Research Documentation Rule

Any time you use WebSearch, WebFetch, or any external research tool — document findings:

1. List every URL visited, with a one-line description
2. Quote exact text for any fact, claim, or number cited
3. Save findings to `docs/research/` when they inform a decision

## auto-terminal

### How it works

`/auto-terminal <task>` spawns a child Claude Code agent in a new terminal window.
Child works autonomously on a separate task while parent continues unblocked.

**Flow:**
1. Parent writes `.claude/fork-context.md` — lean project snapshot for the child
2. Parent runs `bash .claude/scripts/spawn-subagent.sh "<slug>" "<task>"`
3. Child opens in new terminal, reads fork-context.md, works fully autonomously
4. Child writes report to `reports/<slug>-report.md` when done
5. Child signals completion: `echo "DONE:<slug>" >> .claude/agent-status`
6. Child calls `bash .claude/scripts/notify.sh "<slug>"` for desktop notification
7. Parent checks `.claude/agent-status` at natural breakpoints

### Report naming — always `<slug>-report.md`

Every report file: `reports/<slug>-report.md`
- Never `reports/<slug>.md`
- slug = lowercase hyphenated task name, max 4 words
- Example: "build frontend components" → `reports/frontend-components-report.md`

### File ownership

Parent declares owned files in `fork-context.md` under `parent_owns`.
Child reads but never writes to those paths.
Each child owns whatever it creates — listed in its report under "Files created".

### Multiple simultaneous children

Each child gets a unique slug. `.claude/agent-status` is append-only:
```
DONE:frontend-components
DONE:auth-middleware
```
Parent checks each slug independently.

### Runtime files (not committed)

- `.claude/agent-status` — completion signals (append-only)
- `.claude/logs/<slug>.log` — child stdout
- `.claude/fork-context.md` — project snapshot (overwritten each spawn)
- `.claude/child-prompt-<slug>.md` — child system prompt
- `.claude/child-pid-<slug>` — PID file (headless fallback only)
