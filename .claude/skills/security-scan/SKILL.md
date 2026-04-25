---
name: security-scan
description: >
  Full pre-production security and severity audit for any Python FastAPI + React application.
  Spawns ten specialist subagents in parallel covering secrets, SAST, dependencies, config,
  data exposure, containers, crypto/TLS, RBAC, database security (PostgreSQL, MySQL, MongoDB,
  Redis, Snowflake, Qdrant, Chroma, Pinecone, Weaviate, Elasticsearch, and more), and auth
  (JWT, OAuth2, SAML, session, API keys, OIDC, MFA). Aggregates findings by CVSS severity
  and produces a go/no-go markdown report. Trigger whenever the user says "security scan",
  "security audit", "pre-launch check", "find vulnerabilities", "secrets scan",
  "is the codebase safe to deploy", "check my auth", "check my database security",
  or "run a security check before go-live". Always run before any production deployment.
---

# Security Scan — Orchestrator

## Overview

You are the **security scan orchestrator**. Your job is to coordinate ten specialist
subagents, collect their findings, deduplicate, score, and produce a single structured report.

**Default stack in scope (adapt to what exists in the repo):**
- Python FastAPI backend
- React frontend (Vite / CRA / Next.js)
- Any database: relational (PostgreSQL, MySQL, SQLite), document (MongoDB, CouchDB),
  cache (Redis), vector (Qdrant, Chroma, Pinecone, Weaviate, Milvus),
  columnar/cloud (Snowflake, BigQuery), search (Elasticsearch, OpenSearch)
- Any auth: JWT, OAuth2, SAML, OIDC, session, API keys, MFA
- Docker / docker-compose (if present)
- `requirements.txt` / `pyproject.toml`, `package.json`
- `.env` files, config files, CI/CD pipeline files

---

## Step 1 — Confirm repo root and stack

Ask the user for:
1. Repo root path (if not already provided)
2. Backend directory name (default: `backend/` or `api/`)
3. Frontend directory name (default: `frontend/` or `client/`)
4. Auth mechanism(s) in use (JWT / OAuth2 / SAML / OIDC / session / API keys)
5. Database(s) in use (auto-detected if not provided)
6. Scan git history? (default: yes)
7. Post report to PR/CI comment? (default: ask)

---

## Step 2 — Dispatch subagents in parallel

Spawn all ten subagents simultaneously using the Agent tool. Use each agent's registered name:

| Subagent | Agent name | Primary tools |
|---|---|---|
| Secrets | `secrets-agent` | trufflehog, gitleaks, detect-secrets |
| SAST | `sast-agent` | bandit, semgrep |
| Dependencies | `deps-agent` | pip-audit, npm audit, safety |
| Config & Infra | `config-agent` | grep/regex, manual checklist |
| Data Exposure | `data-agent` | AST scan, log pattern grep |
| IaC & Container | `iac-container-agent` | checkov, Dockerfile/docker-compose manual checks |
| Crypto & TLS | `crypto-tls-agent` | sslyze, weak algo grep, JWT algo audit |
| RBAC | `rbac-agent` | route decorator audit, role logic grep |
| Database | `database-agent` | connection audit, injection checks, vector DB auth |
| Auth | `auth-agent` | JWT, OAuth2, SAML, session, API key, MFA audit |

Pass the repo root path to each agent as context. Each agent returns a structured findings list (see `references/report-template.md` for schema).

---

## Step 3 — Aggregate and deduplicate

- Merge all findings into one list
- Deduplicate by `(file, line, rule_id)`
- Sort by severity: CRITICAL → HIGH → MEDIUM → LOW → INFO
- Count totals per severity bucket

---

## Step 4 — Generate report

Use `references/report-template.md` as the output schema.
Save report to `<repo_root>/security-report-<YYYY-MM-DD>.md`.

---

## Step 5 — Go/no-go verdict

- Any CRITICAL finding → **NO-GO**. List blockers explicitly.
- HIGH findings → warn, user decides.
- MEDIUM and below → proceed with remediation plan.

---

## Severity definitions

| Level | CVSS | Meaning |
|---|---|---|
| CRITICAL | 9.0–10.0 | Live credential, auth bypass, RCE vector — hard block |
| HIGH | 7.0–8.9 | Exploitable in production, fix before launch |
| MEDIUM | 4.0–6.9 | Real risk, fix within current sprint |
| LOW | 0.1–3.9 | Defense-in-depth, backlog |
| INFO | — | Best practice gap, no direct exploitability |
