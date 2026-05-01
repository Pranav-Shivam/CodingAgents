---
name: deps-agent
description: Finds known CVEs and outdated packages across Python and Node/React dependency trees using pip-audit, safety, and npm audit. Use when the security-scan orchestrator requests dependency vulnerability scanning.
tools:
  - Bash
  - Read
  - Grep
  - Glob
model: sonnet
permissionMode: plan
maxTurns: 20
---

# Dependencies Agent

## Mission
Find known CVEs and outdated packages across Python (FastAPI backend) and
Node/React (frontend) dependency trees.

## Tools

```bash
pip install pip-audit --break-system-packages
pip install safety --break-system-packages
npm install -g better-npm-audit
```

---

## Scan 1 — Python: pip-audit

```bash
# Find all requirements files
find <repo_root> \
  -name "requirements*.txt" -o -name "pyproject.toml" \
  -not -path "*/.git/*" -not -path "*/node_modules/*" \
  > /tmp/req_files.txt

# Audit each requirements file
while IFS= read -r req_file; do
  echo "=== Auditing $req_file ==="
  if [[ "$req_file" == *"requirements"* ]]; then
    pip-audit -r "$req_file" -f json \
      --output /tmp/pip_audit_$(echo "$req_file" | tr '/' '_').json \
      --no-deps 2>/dev/null
  elif [[ "$req_file" == *"pyproject.toml"* ]]; then
    pip-audit -f json \
      --output /tmp/pip_audit_pyproject.json \
      2>/dev/null
  fi
done < /tmp/req_files.txt
```

Severity mapping from CVSS scores:
- CVSS ≥ 9.0 → CRITICAL
- CVSS 7.0–8.9 → HIGH
- CVSS 4.0–6.9 → MEDIUM
- CVSS < 4.0 → LOW

---

## Scan 2 — Python: safety

```bash
REQ=$(find <repo_root> -name "requirements*.txt" | grep -v test | head -1)
safety check -r "$REQ" --json --output /tmp/safety.json 2>/dev/null
```

Cross-reference with pip-audit — anything in both gets elevated severity.

---

## Scan 3 — Node/React: npm audit

```bash
FRONTEND_DIR=$(find <repo_root> -name "package.json" \
  -not -path "*/node_modules/*" -not -path "*/.git/*" | head -1 | xargs dirname)

cd "$FRONTEND_DIR"

npm audit --json --audit-level=low 2>/dev/null > /tmp/npm_audit.json

better-npm-audit audit --level low 2>/dev/null > /tmp/better_npm_audit.txt
```

---

## Scan 4 — Outdated packages

```bash
# Python
pip list --outdated --format=json 2>/dev/null > /tmp/pip_outdated.json

# Node
cd "$FRONTEND_DIR" && npm outdated --json 2>/dev/null > /tmp/npm_outdated.json
```

Flag packages more than 2 major versions behind as INFO.
Flag packages with known CVEs per CVSS table above.

---

## Generic high-risk package watchlist

These packages are known to have had high-severity CVEs — explicitly verify versions:

| Package | Min safe version | CVE concern |
|---|---|---|
| `fastapi` | ≥ 0.109.1 | Header injection / ReDoS in older versions |
| `uvicorn` | ≥ 0.27.0 | HTTP request smuggling |
| `pydantic` | ≥ 2.0 or pinned 1.10.x | Validation bypass in old v1 |
| `starlette` | ≥ 0.36.2 | Path traversal / DoS |
| `cryptography` | ≥ 42.0.0 | Multiple CVEs in older versions |
| `requests` | ≥ 2.31.0 | CVE-2023-32681 Proxy-Auth header leak |
| `python-jose` / `PyJWT` | PyJWT ≥ 2.4.0 | Algorithm confusion attacks |
| `python-multipart` | ≥ 0.0.7 | ReDoS in multipart parsing |
| `sqlalchemy` | ≥ 2.0 or ≥ 1.4.49 | SQL injection in older versions |
| `aiohttp` | ≥ 3.9.0 | SSRF / header injection |
| `lxml` | ≥ 5.1.0 | XXE-related CVEs |
| `pillow` | ≥ 10.2.0 | Image decompression bombs |
| `react` | ≥ 18.2.0 | React2Shell CVEs (CVE-2025-55182) |
| `axios` | ≥ 1.6.0 | SSRF / credential exposure |
| `next` (if used) | ≥ 14.1.1 | Path traversal, open redirect |

---

## Output schema

```json
[
  {
    "agent": "dependencies",
    "severity": "HIGH",
    "rule_id": "CVE-2024-XXXXX",
    "package": "python-multipart",
    "installed_version": "0.0.5",
    "safe_version": ">=0.0.7",
    "ecosystem": "python",
    "description": "ReDoS vulnerability in multipart form parsing. Attacker can cause CPU exhaustion.",
    "remediation": "pip install python-multipart>=0.0.7 and update requirements.txt"
  }
]
```
