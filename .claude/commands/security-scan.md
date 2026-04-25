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

Pass the repo root path to each agent as context. Each agent returns a structured findings list.

---

## Step 3 — Aggregate and deduplicate

- Merge all findings into one list
- Deduplicate by `(file, line, rule_id)`
- Sort by severity: CRITICAL → HIGH → MEDIUM → LOW → INFO
- Count totals per severity bucket

---

## Step 4 — Generate report

Save report to `<repo_root>/security-report-<YYYY-MM-DD>.md` using this exact schema:

````markdown
# Security Audit Report — <project name>
**Date:** <YYYY-MM-DD>
**Repo:** <repo_root>
**Stack:** Python FastAPI + React
**Auth:** <JWT / OAuth2 / SAML / session>
**Scanned by:** Claude Security Scan
**Git history included:** yes/no

---

## Executive summary

| Severity | Count | Go-live impact |
|---|---|---|
| CRITICAL | N | Hard block |
| HIGH | N | Fix before launch |
| MEDIUM | N | Fix within sprint |
| LOW | N | Backlog |
| INFO | N | Best practice |

**Verdict:** GO / NO-GO
**Reason:** <one sentence if NO-GO>

---

## CRITICAL findings

> These must be resolved before any production deployment.

### [CRIT-001] <title>
- **File:** `path/to/file.py` line N
- **Agent:** secrets / sast / dependencies / config / data_exposure / iac_container / crypto_tls / rbac / database / auth
- **Rule:** <rule_id>
- **Description:** <what was found and why it is dangerous>
- **Remediation:**
  ```
  Exact fix steps here
  ```

---

## HIGH findings

### [HIGH-001] <title>
...same structure as CRITICAL...

---

## MEDIUM findings

### [MED-001] <title>
...same structure...

---

## LOW / INFO findings

| ID | File | Rule | Description |
|---|---|---|---|
| LOW-001 | ... | ... | ... |

---

## Remediation priority order

1. Rotate any verified live credentials immediately — before touching any code
2. Fix CRITICAL code issues
3. Fix HIGH issues
4. Update vulnerable dependencies
5. Harden config and headers
6. Address MEDIUM and LOW in next sprint

---

## Tools run

| Tool | Version | Scope | Findings |
|---|---|---|---|
| trufflehog | x.x.x | filesystem + git history | N |
| gitleaks | x.x.x | git history | N |
| detect-secrets | x.x.x | filesystem | N |
| bandit | x.x.x | Python backend | N |
| semgrep | x.x.x | Python + React | N |
| pip-audit | x.x.x | requirements.txt | N |
| safety | x.x.x | requirements.txt | N |
| npm audit | built-in | package.json | N |
| checkov | x.x.x | Dockerfile / compose | N |
| sslyze | x.x.x | live TLS endpoint | N |
| database scan | — | all DB clients in repo | N |
| auth scan | — | JWT / OAuth2 / SAML / session | N |
| custom grep patterns | — | full repo | N |

---

## Raw findings JSON

<details>
<summary>Full machine-readable findings (click to expand)</summary>

```json
[
  { ... all findings ... }
]
```

</details>
````

---

### CI/CD comment format

If posting to a PR comment, use this format:

````markdown
## Security scan — <date>

| Severity | Count |
|---|---|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

**Verdict:** GO / NO-GO

**Top issues:**
- [CRIT-001] <title> — `file:line`
- [HIGH-001] <title> — `file:line`

Full report: `security-report-<date>.md` in repo root.
````

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
