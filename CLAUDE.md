# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **Claude Code skill and reference library** — not a runnable application. It contains:

- `.claude/security-scan/SKILL.md` — the `security-scan` skill orchestrator specification
- `.claude/security-scan/references/` — ten specialist subagent guides (one per security domain)
- `.claude/rules/principles_v2.md` — agentic coding standards (canonical reference)
- `.claude/rules/principles.md` — extended v1 with additional failure mode detail

There are no build, lint, or test commands. All "execution" happens when Claude Code invokes the skill against a target repo.

---

## Security-scan skill

Triggered when the user says: *"security scan"*, *"security audit"*, *"pre-launch check"*, *"find vulnerabilities"*, *"secrets scan"*, *"is the codebase safe to deploy"*, *"check my auth"*, *"check my database security"*, or *"run a security check before go-live"*.

**Orchestration flow:**

1. Confirm repo root, stack (FastAPI + React default), auth mechanisms, databases, and whether to scan git history.
2. Read each reference file under `references/`, then spawn all 10 subagents **in parallel**.
3. Aggregate findings, deduplicate by `(file, line, rule_id)`, sort CRITICAL → HIGH → MEDIUM → LOW → INFO.
4. Render report using `references/report-template.md`, save to `<repo_root>/security-report-<YYYY-MM-DD>.md`.
5. Verdict: any CRITICAL → **NO-GO**; HIGH → warn, user decides; MEDIUM and below → proceed with remediation plan.

**Severity thresholds (CVSS):**

| Level | CVSS | Action |
|---|---|---|
| CRITICAL | 9.0–10.0 | Hard block — live credential, auth bypass, RCE |
| HIGH | 7.0–8.9 | Fix before launch |
| MEDIUM | 4.0–6.9 | Fix within sprint |
| LOW | 0.1–3.9 | Backlog |
| INFO | — | Best practice gap |

**Subagent → reference file mapping:**

| Domain | Reference file | Key external tools |
|---|---|---|
| Secrets | `references/secrets-agent.md` | trufflehog, gitleaks, detect-secrets |
| SAST | `references/sast-agent.md` | bandit, semgrep |
| Dependencies | `references/deps-agent.md` | pip-audit, safety, npm audit |
| Config & Infra | `references/config-agent.md` | grep/regex |
| Data Exposure | `references/data-agent.md` | AST scan, log pattern grep |
| IaC & Container | `references/iac-container-agent.md` | checkov |
| Crypto & TLS | `references/crypto-tls-agent.md` | sslyze |
| RBAC | `references/rbac-agent.md` | route decorator audit |
| Database | `references/database-agent.md` | connection audit, injection checks |
| Auth | `references/auth-agent.md` | JWT, OAuth2, SAML, session, API key, MFA audit |

Each subagent returns findings as structured JSON:
```json
{
  "agent": "<domain>",
  "severity": "CRITICAL|HIGH|MEDIUM|LOW|INFO",
  "rule_id": "<custom-id>",
  "file": "path/to/file.py",
  "line": 123,
  "description": "...",
  "remediation": "..."
}
```

---

## Agentic coding standards (from `.claude/rules/principles_v2.md`)

These govern how Claude should behave when working in *any* codebase, and are the design rationale behind this repo's approach.

1. **Clarify before building** — State assumptions explicitly; ask once, precisely, before coding.
2. **Lean and purposeful code** — Implement exactly what was asked; no abstractions for single-use code, no future-proofing.
3. **Precise, bounded edits** — Touch only what the task requires; flag (don't fix) unrelated issues spotted along the way.
4. **Outcome-oriented execution** — Convert every task into a verifiable end state before starting; define success criteria, not steps.
5. **Verify and recover** — Run the build/tests after every non-trivial change; never mark done without confirming the success criterion.

**Known failure modes to avoid:** unchecked early assumptions, session memory decay (re-read constraints at task boundaries), phantom API usage (verify signatures against source), pushback capitulation (yield to better arguments, not pressure), scope creep, and optimistic execution through ambiguity.
