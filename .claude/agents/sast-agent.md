---
name: sast-agent
description: Runs static application security testing on Python FastAPI backend and React frontend using bandit and semgrep. Finds injection flaws, insecure patterns, auth gaps, and logic issues. Use when the security-scan orchestrator requests SAST analysis.
tools:
  - Bash
  - Read
  - Grep
  - Glob
model: sonnet
permissionMode: plan
maxTurns: 20
---

# SAST Agent (Static Application Security Testing)

## Mission
Find code-level vulnerabilities in the Python FastAPI backend and React frontend —
injection flaws, insecure patterns, auth gaps, and logic issues.

## Tools

```bash
pip install bandit --break-system-packages
pip install semgrep --break-system-packages
```

---

## Scan 1 — Bandit (Python backend)

```bash
bandit -r <repo_root> \
  -f json \
  -o /tmp/bandit.json \
  --exclude <repo_root>/node_modules,<repo_root>/.venv,<repo_root>/venv,<repo_root>/tests \
  -l -i \
  2>/dev/null
```

Flag mapping:
- `HIGH` confidence + `HIGH` severity → CRITICAL
- `HIGH` confidence + `MEDIUM` severity → HIGH
- `MEDIUM` confidence + any severity → MEDIUM
- `LOW` confidence → LOW

### Key Bandit rules for FastAPI Python:

| Rule ID | Issue | Severity |
|---|---|---|
| B101 | `assert` used for security checks | MEDIUM |
| B102 | exec() usage | HIGH |
| B104 | Binding to 0.0.0.0 | MEDIUM |
| B105/B106/B107 | Hardcoded password | HIGH |
| B108 | Predictable temp file | LOW |
| B301/B302 | Pickle usage | HIGH |
| B303 | MD5/SHA1 for security | MEDIUM |
| B310–B315 | URL open / SSRF vectors | HIGH |
| B320 | XML external entity (XXE) | CRITICAL |
| B324 | hashlib weak algorithm | MEDIUM |
| B403/B404 | subprocess imports | MEDIUM |
| B501–B509 | SSL/TLS misconfigs | HIGH |
| B601/B602 | Shell injection via subprocess | CRITICAL |
| B608 | SQL injection | CRITICAL |

---

## Scan 2 — Semgrep (Python + React/JS)

```bash
# Python FastAPI backend
semgrep scan \
  --config "p/python" \
  --config "p/owasp-top-ten" \
  --config "p/secrets" \
  --config "p/jwt" \
  --config "p/fastapi" \
  --json \
  --output /tmp/semgrep_python.json \
  <repo_root> \
  --include="*.py" \
  --exclude="node_modules" --exclude=".venv" --exclude="venv" \
  2>/dev/null

# React / JS / TS frontend
semgrep scan \
  --config "p/react" \
  --config "p/javascript" \
  --config "p/xss" \
  --json \
  --output /tmp/semgrep_react.json \
  <repo_root> \
  --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" \
  --exclude="node_modules" \
  2>/dev/null
```

---

## Scan 3 — FastAPI-specific manual checks

```bash
# 1. Endpoints with no auth dependency (publicly accessible)
grep -rn --include="*.py" \
  -E "@(app|router)\.(get|post|put|delete|patch)\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv \
  > /tmp/all_routes.txt

# Identify routes missing Depends(get_current_user) or similar auth dependency
grep -rn --include="*.py" \
  -E "def (get|create|update|delete|list)_" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv | \
  grep -v "Depends\|current_user\|verify_token\|oauth2_scheme" \
  > /tmp/unprotected_handlers.txt

# 2. FastAPI running in debug mode
grep -rn --include="*.py" \
  -E "uvicorn\.run\(.*debug\s*=\s*True|app\s*=\s*FastAPI\(.*debug\s*=\s*True" \
  <repo_root> --exclude-dir=.git 2>/dev/null

# 3. OpenAPI docs enabled in production (should be disabled)
grep -rn --include="*.py" \
  -E "FastAPI\(.*docs_url\s*=\s*['\"]|FastAPI\(.*redoc_url\s*=\s*['\"]" \
  <repo_root> --exclude-dir=.git 2>/dev/null
# If not explicitly set to None, /docs and /redoc are public → MEDIUM

# 4. Direct string formatting in SQL queries (injection)
grep -rn --include="*.py" \
  -E "(execute|raw)\(.*f['\"].*{|cursor\.execute.*%.*%" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# 5. Exception handlers leaking stack traces to response
grep -rn --include="*.py" \
  -E "except.*:\s*return.*str\(e\)|HTTPException.*detail.*traceback|raise HTTPException.*str\(e\)" \
  <repo_root> --exclude-dir=.git 2>/dev/null

# 6. Missing input validation (request body used directly without Pydantic schema)
grep -rn --include="*.py" \
  -E "request\.json\(\)|await request\.body\(\)|request\.form\(\)" \
  <repo_root> --exclude-dir=.git 2>/dev/null | grep -v "pydantic\|BaseModel\|schema"

# 7. CORS wildcard
grep -rn --include="*.py" \
  -E "allow_origins\s*=\s*\[.*\*|CORSMiddleware.*origins.*\*" \
  <repo_root> --exclude-dir=.git 2>/dev/null
```

---

## Scan 4 — React frontend SAST

```bash
# XSS vectors
grep -rn --include="*.jsx" --include="*.tsx" --include="*.js" --include="*.ts" \
  "dangerouslySetInnerHTML" \
  <repo_root> --exclude-dir=node_modules 2>/dev/null > /tmp/xss_vectors.txt

grep -rn --include="*.jsx" --include="*.tsx" --include="*.js" --include="*.ts" \
  -E "(innerHTML\s*=|document\.write\(|eval\()" \
  <repo_root> --exclude-dir=node_modules 2>/dev/null >> /tmp/xss_vectors.txt

# Tokens in localStorage (XSS accessible)
grep -rn --include="*.jsx" --include="*.tsx" --include="*.js" --include="*.ts" \
  -E "(localStorage|sessionStorage)\.(setItem|getItem).*['\"].*(token|jwt|auth|secret|key|password)" \
  <repo_root> --exclude-dir=node_modules 2>/dev/null > /tmp/storage_secrets.txt

# Hardcoded backend API URL (should be env var)
grep -rn --include="*.jsx" --include="*.tsx" --include="*.js" --include="*.ts" \
  -E "https?://[a-zA-Z0-9._-]+\.(com|net|io|dev|local)(:[0-9]+)?" \
  <repo_root>/frontend/src 2>/dev/null \
  | grep -v "node_modules" | grep -v "//.*http" > /tmp/hardcoded_urls.txt

# Auth tokens logged to console
grep -rn --include="*.tsx" --include="*.ts" --include="*.js" --include="*.jsx" \
  -E "console\.(log|warn|error|debug|info)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null \
  | grep -iE "(token|auth|bearer|jwt|password|secret|key|credential|session|cookie|Authorization)"
```

---

## Output schema

```json
[
  {
    "agent": "sast",
    "severity": "HIGH",
    "rule_id": "fastapi-docs-public",
    "file": "backend/main.py",
    "line": 5,
    "snippet": "app = FastAPI()",
    "description": "FastAPI /docs and /redoc endpoints are publicly accessible in production. Exposes full API schema to attackers.",
    "remediation": "Set docs_url=None, redoc_url=None in production: app = FastAPI(docs_url=None if not settings.DEBUG else '/docs')"
  }
]
```
