# Architecture

## Repo purpose

Reference library for Claude Code workflows. Not a runnable app. Everything here is specification/template material meant to be copied into or referenced from target codebases.

## Structure

```
.claude/
├── agents/           # 10 specialist security subagents — each owns one domain
│   ├── auth-agent.md         JWT, OAuth2, SAML, session, API keys, OIDC, MFA
│   ├── config-agent.md       CORS, headers, env vars, FastAPI config, rate limiting
│   ├── crypto-tls-agent.md   TLS, weak algorithms, JWT algorithm security, key files
│   ├── data-agent.md         Sensitive data in logs, API responses, client storage
│   ├── database-agent.md     SQL/NoSQL injection, connection security, vector DBs
│   ├── deps-agent.md         CVE scanning — pip-audit, safety, npm audit
│   ├── emoji-agent.md        Emoji in SQL/logs (Azure SQL truncation risk)
│   ├── iac-container-agent.md  Docker, docker-compose, CI/CD pipeline security
│   ├── rbac-agent.md         Route auth coverage, IDOR, permission decorators
│   └── sast-agent.md         Bandit + Semgrep — injection, weak crypto, XSS
│
├── commands/
│   ├── security-scan.md      Orchestrator — dispatches all 10 agents in parallel
│   ├── git-commit.md         Generate conventional commit message from diff
│   ├── pr-description.md     Generate PR description from branch changes
│   └── learn.md              Extract session learnings → save to docs/gotchas.md
│
└── rules/
    ├── principles_v2.md      Canonical agentic coding standards (5 principles)
    └── principles.md         Extended v1 with 10 failure modes, signal checks

docs/
├── architecture.md   This file
└── gotchas.md        Grows each session via /learn
```

## Agent design pattern

Each subagent follows the same structure:
1. **Frontmatter** — name, description (surgical, names exact mechanisms + trigger condition), tools (minimal — Read/Grep/Glob/Bash only, never Write)
2. **Mission** — one domain, one paragraph
3. **Runbook** — executable bash commands, not guidelines
4. **Output schema** — structured JSON with: agent, severity, rule_id, file, line, snippet, description, remediation

## Security scan orchestrator flow

```
/security-scan
  └─ Step 1: Confirm repo root + stack
  └─ Step 2: Dispatch 10 subagents in parallel
  └─ Step 3: Aggregate + deduplicate by (file, line, rule_id)
  └─ Step 4: Generate structured report
       ├─ Executive summary (severity counts)
       ├─ Findings grouped by severity (CRITICAL → INFO)
       ├─ GO / NO-GO verdict
       └─ Raw findings JSON
```

## Severity scale

| Level | CVSS | Action |
|---|---|---|
| CRITICAL | 9.0–10.0 | Hard block — live credential, auth bypass, RCE |
| HIGH | 7.0–8.9 | Fix before launch |
| MEDIUM | 4.0–6.9 | Fix within sprint |
| LOW | 0.1–3.9 | Backlog |
| INFO | — | Best practice gap |
