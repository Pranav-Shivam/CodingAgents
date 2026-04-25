# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **Claude Code skill and reference library** — not a runnable application. It contains:

- `.claude/security-scan/SKILL.md` — the `security-scan` skill orchestrator specification
- `.claude/security-scan/references/` — ten specialist subagent guides (one per security domain)
- `.claude/rules/principles_v2.md` — agentic coding standards (canonical reference)
- `.claude/rules/principles.md` — extended v1 with additional failure mode detail


## Agentic coding standards (from `.claude/rules/principles_v2.md`)

These govern how Claude should behave when working in *any* codebase, and are the design rationale behind this repo's approach.

1. **Clarify before building** — State assumptions explicitly; ask once, precisely, before coding.
2. **Lean and purposeful code** — Implement exactly what was asked; no abstractions for single-use code, no future-proofing.
3. **Precise, bounded edits** — Touch only what the task requires; flag (don't fix) unrelated issues spotted along the way.
4. **Outcome-oriented execution** — Convert every task into a verifiable end state before starting; define success criteria, not steps.
5. **Verify and recover** — Run the build/tests after every non-trivial change; never mark done without confirming the success criterion.

**Known failure modes to avoid:** unchecked early assumptions, session memory decay (re-read constraints at task boundaries), phantom API usage (verify signatures against source), pushback capitulation (yield to better arguments, not pressure), scope creep, and optimistic execution through ambiguity.
