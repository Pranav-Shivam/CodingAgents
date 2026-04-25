# Report Template

## Output filename
`<repo_root>/security-report-<YYYY-MM-DD>.md`

---

## Markdown report schema

```markdown
# Security Audit Report — <project name>
**Date:** <YYYY-MM-DD>
**Repo:** <repo_root>
**Stack:** Python FastAPI + React
**Auth:** <JWT / OAuth2 / SAML / session>
**Scanned by:** Claude Security Scan Skill v1.0
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
- **Agent:** secrets / sast / dependencies / config / data_exposure / iac_container / crypto_tls / rbac
- **Rule:** <rule_id>
- **Description:** <what was found and why it is dangerous>
- **Remediation:**
  ```
  Exact fix steps here
  ```

---

## HIGH findings

### [HIGH-001] <title>
...same structure...

---

## MEDIUM findings

### [MED-001] <title>
...

---

## LOW / INFO findings

(Tabular format for brevity)

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
```

---

## CI/CD comment format (GitHub Actions / GitLab CI / Azure DevOps)

Post this as a PR comment when scan completes:

```markdown
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
```
