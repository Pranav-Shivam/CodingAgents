# <feature-name>-report

> Auto-terminal child agent report. Replace `<feature-name>` with the actual task slug.

---

## Task summary

**Asked:** (what the parent requested via /auto-terminal)

**Built:** (what was actually implemented — be specific, reference file paths)

**Scope delta:** (anything not done, and why)

---

## Files created

| Path | Purpose |
|------|---------|
| `path/to/file` | what it contains and why it exists |

---

## Files modified

| Path | What changed |
|------|-------------|
| `path/to/file` | specific change made and reason |

---

## Decisions made

Every non-obvious choice with reasoning. If you picked one approach over another, say why.

| Decision | Chosen | Rejected | Reason |
|----------|--------|----------|--------|
| example | approach A | approach B | reason for A |

---

## How it connects to parent's work

- **Interfaces / contracts:** (function signatures, API endpoints, event names the parent must match)
- **Shared types:** (type definitions, schemas, constants defined here that parent consumes)
- **Integration points:** (where parent wires this in — import paths, config keys, env vars)

---

## How to test / verify

Step-by-step bash commands to confirm the work is correct:

```bash
# 1. (describe what this verifies)
<command>

# 2.
<command>
```

Expected output for each step.

---

## Open items

Checklist of things that need parent review, follow-up, or decisions the child deferred:

- [ ] item needing parent action
- [ ] unresolved edge case
- [ ] integration wiring the parent must complete

---

## Errors / issues encountered

Any errors hit during execution, how they were resolved, and anything unresolved:

| Error | Context | Resolution |
|-------|---------|------------|
| error message | where it occurred | how fixed or why left open |

---

## Full action log

Chronological list of every significant action taken:

1. Read `.claude/fork-context.md` — confirmed project context
2. (each step in order)
