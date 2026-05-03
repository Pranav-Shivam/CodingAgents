# Claude Code Skill & Reference Library

A collection of Claude Code skills, subagent definitions, and agentic coding standards — not a runnable application.

## Install

**Global** — agents and commands available in all projects:

```bash
curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash
```

**Project-scoped** — installs into current directory's `.claude/`:

```bash
curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --project
```

Restart Claude Code after install. See [setup.md](setup.md) for full options including Windows and clone-based install.

---

## Contents

```
.claude/
├── commands/
│   └── security-scan.md      # /security-scan orchestrator skill
├── agents/                   # Ten specialist security subagents
│   ├── auth-agent.md
│   ├── sast-agent.md
│   ├── secrets-agent.md
│   ├── deps-agent.md
│   ├── config-agent.md
│   ├── data-agent.md
│   ├── iac-container-agent.md
│   ├── crypto-tls-agent.md
│   ├── rbac-agent.md
│   └── database-agent.md
└── rules/
    ├── principles_v2.md      # Agentic coding standards (canonical)
    └── principles.md         # Extended v1 with failure mode detail
```

## Security Scan Skill

`/security-scan` is an orchestrator that spawns all ten subagents in parallel, aggregates their findings, and produces a structured `security-report-<YYYY-MM-DD>.md`.

**Supported stack:**
- Python FastAPI backend
- React frontend (Vite / CRA / Next.js)
- Any auth: JWT, OAuth2, SAML, OIDC, session, API keys, MFA
- Any database: PostgreSQL, MySQL, MongoDB, Redis, Snowflake, BigQuery, Elasticsearch, vector DBs
- Docker / docker-compose
- CI/CD pipeline configs

**Usage:**
```
/security-scan
```

The orchestrator will ask for repo root, stack details, and scan scope, then dispatch all agents simultaneously.

### Subagents

| Agent | Tools | Checks |
|---|---|---|
| `secrets-agent` | trufflehog, gitleaks, detect-secrets | Hardcoded credentials, tokens, API keys in code and git history |
| `sast-agent` | bandit, semgrep | Injection flaws, insecure patterns, auth gaps |
| `deps-agent` | pip-audit, npm audit, safety | Known CVEs, outdated packages |
| `config-agent` | grep/regex | CORS policy, security headers, env var handling |
| `data-agent` | AST scan, grep | Sensitive data in logs, API responses, client-side storage |
| `iac-container-agent` | checkov | Dockerfile, docker-compose, CI/CD misconfigurations |
| `crypto-tls-agent` | sslyze, grep | TLS config, weak algorithms, JWT algorithm security |
| `rbac-agent` | grep | Route-level auth coverage, RBAC logic, over-permissioned access |
| `database-agent` | grep | Connection security, SQL/NoSQL injection, privilege scope |
| `auth-agent` | grep | JWT, OAuth2, SAML, session, API key, MFA implementation flaws |

### Report structure

```
security-report-<date>.md
├── Executive summary (severity table + GO/NO-GO verdict)
├── CRITICAL findings (hard block — resolve before deployment)
├── HIGH findings
├── MEDIUM findings
├── LOW / INFO findings (table)
├── Remediation priority order
└── Tools run + raw findings JSON
```

**Severity scale:**

| Level | CVSS | Go-live impact |
|---|---|---|
| CRITICAL | 9.0–10.0 | Hard block |
| HIGH | 7.0–8.9 | Fix before launch |
| MEDIUM | 4.0–6.9 | Fix within sprint |
| LOW | 0.1–3.9 | Backlog |
| INFO | — | Best practice gap |

## Agentic Coding Standards

`principles_v2.md` is the canonical behavioral framework for LLM-assisted development:

1. **Clarify before building** — State assumptions explicitly; ask once, precisely
2. **Lean and purposeful code** — Implement exactly what was asked; no premature abstraction
3. **Precise, bounded edits** — Touch only what the task requires
4. **Outcome-oriented execution** — Define verifiable end states, not step-by-step instructions
5. **Verify and recover** — Run build/tests after every non-trivial change; never mark done without confirming success

`principles.md` is the extended v1 with deeper failure mode analysis covering: unchecked assumptions, session memory decay, phantom API usage, pushback capitulation, scope creep, and optimistic execution.
