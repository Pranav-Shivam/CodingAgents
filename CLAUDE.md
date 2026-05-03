# CLAUDE.md

## What this repo is

Claude Code skill and reference library — not a runnable app. Contains:

- `.claude/commands/security-scan.md` — `/security-scan` orchestrator (dispatches 10 parallel subagents)
- `.claude/agents/` — 10 specialist security subagents (auth, sast, deps, config, data, iac, crypto, rbac, database, secrets)
- `.claude/commands/` — workflow skills (git-commit, pr-description, learn)
- `.claude/rules/principles_v2.md` — agentic coding standards (canonical)
- `.claude/rules/principles.md` — extended v1 with full failure mode detail

## Agentic Coding Standards

1. **Clarify before building** — State assumptions explicitly; ask once, precisely.
2. **Lean and purposeful code** — Implement exactly what was asked; no gold-plating.
3. **Precise, bounded edits** — Touch only what the task requires; flag, don't fix, unrelated issues.
4. **Outcome-oriented execution** — Define verifiable end state before starting.
5. **Verify and recover** — Run verification after every non-trivial change; never mark done without confirming success.

**Known failure modes:** unchecked assumptions, session memory decay, phantom API usage, pushback capitulation, scope creep, optimistic execution through ambiguity.

## Communication Rules

- No emoji in any output — responses, code, commits, docs, comments. None. Ever.

## Research Documentation Rule

IMPORTANT: Any time you use WebSearch, WebFetch, or any external research tool — you MUST document findings as follows:

1. List every URL visited, with a one-line description of what it contained
2. Quote exact text for any fact, claim, or number cited
3. Note if a URL returned no useful content or was inaccessible
4. Save research findings to `docs/research/` when they inform a decision or change made in this repo

Format for inline citation:
```
Source: [page title](https://full-url) — what was found there
```

Never summarize research without citing where it came from. Uncited claims = unverifiable claims.

## Further Reading

IMPORTANT: Before starting any task, read relevant docs below first. Do not skip this.

- `docs/gotchas.md` — hard-won lessons and non-obvious patterns
- `docs/architecture.md` — repo structure, design rationale, agent relationships
- `docs/research/` — web research logs with sources (created when research informs decisions)

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
- Enforced in: spawn-subagent.sh, child prompt, notify.sh, auto-terminal.md

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
Parent checks each slug independently. Each child notifies independently.
Never summarize child output in parent thread — point to `reports/<slug>-report.md`.

### Runtime files (not committed)

- `.claude/agent-status` — completion signals (append-only)
- `.claude/logs/<slug>.log` — child stdout
- `.claude/fork-context.md` — project snapshot (overwritten each spawn)
- `.claude/child-prompt-<slug>.md` — child system prompt
- `.claude/child-pid-<slug>` — PID file (headless fallback only)
