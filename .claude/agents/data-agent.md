---
name: data-agent
description: Finds sensitive data leakage through logs, API responses, error messages, client-side storage, and over-scoped database queries. Use when the security-scan orchestrator requests data exposure analysis.
tools:
  - Bash
  - Read
  - Grep
  - Glob
model: sonnet
permissionMode: plan
maxTurns: 20
---

# Data Exposure Agent

## Mission
Find places where the application leaks sensitive data — through logs, API responses,
error messages, client-side storage, or insufficiently scoped database queries.

---

## Check 1 — Sensitive data in logging statements

```bash
# Auth tokens, passwords, secrets in log calls
grep -rn --include="*.py" \
  -E "(logging\.(debug|info|warning|error|exception|critical)|print)\s*\(.*\{?.*(token|password|secret|api_key|bearer|authorization|credential|jwt|access_token|refresh_token)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null > /tmp/logging_secrets.txt

# Entire request objects logged (may contain auth headers or body)
grep -rn --include="*.py" \
  -E "(logging|print).*\b(request|req)\b" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null >> /tmp/logging_secrets.txt

# PII-adjacent fields logged (adapt field names to your domain)
grep -rn --include="*.py" \
  -E "(logging|print).*\b(email|phone|address|ssn|card_number|dob|date_of_birth)\b" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null >> /tmp/logging_secrets.txt
```

Flag: auth tokens in logs → HIGH. Full request body at INFO → MEDIUM.

---

## Check 2 — API response over-exposure

```bash
# Pydantic model serialization dumping all fields (including internal ones)
grep -rn --include="*.py" \
  -E "(\.dict\(\)|\.json\(\)|model_dump\(\)|jsonable_encoder\()" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null \
  | grep -v "exclude\|include\|response_model" > /tmp/full_model_dumps.txt

# FastAPI routes missing response_model (full ORM object may be serialized)
grep -rn --include="*.py" \
  -E "@(app|router)\.(get|post|put|delete|patch)\(" \
  <repo_root> --exclude-dir=.git 2>/dev/null \
  | grep -v "response_model" > /tmp/routes_no_response_model.txt

# Exception handlers returning raw exception string to client
grep -rn --include="*.py" \
  -E "raise HTTPException\(.*detail\s*=\s*str\(e\)|return.*{\s*['\"]detail['\"].*str\(e\)" \
  <repo_root> --exclude-dir=.git 2>/dev/null > /tmp/error_detail_leak.txt
```

---

## Check 3 — JWT / auth token handling

```bash
# JWT decoded without signature verification
grep -rn --include="*.py" \
  -E "jwt\.decode\(.*verify\s*=\s*False|jwt\.decode\(.*options\s*=.*['\"]verify" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# verify=False → CRITICAL

# JWT decode missing algorithms parameter (algorithm confusion)
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "algorithms"
# Missing algorithms → CRITICAL (none attack)

# JWT decode missing audience validation
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "audience\|iss\|issuer"
# Missing audience → HIGH

# Tokens returned in response body (should be HttpOnly cookie or avoided)
grep -rn --include="*.py" \
  -E "return.*['\"]access_token['\"]|return.*['\"]token['\"]|JSONResponse.*access_token" \
  <repo_root> --exclude-dir=.git 2>/dev/null > /tmp/token_in_body.txt
```

---

## Check 4 — React client-side data exposure

```bash
# Auth tokens in localStorage (XSS-accessible)
grep -rn --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" \
  -E "(localStorage|sessionStorage)\.(setItem|getItem).*['\"].*(token|jwt|auth|secret|password)" \
  <repo_root> --exclude-dir=node_modules 2>/dev/null > /tmp/client_token_storage.txt

# Sensitive data in React state logged to console
grep -rn --include="*.tsx" --include="*.ts" --include="*.js" --include="*.jsx" \
  -E "console\.(log|warn|error|debug)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null \
  | grep -iE "(token|auth|bearer|jwt|password|secret|key|credential|session)"

# User data fetched but stored entirely client-side
grep -rn --include="*.tsx" --include="*.ts" \
  -E "(useState|useReducer|localStorage|sessionStorage).*user|setUser\(" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -20
```

---

## Check 5 — Database query exposure

```bash
# Raw SQL with user input (injection + over-fetch)
grep -rn --include="*.py" \
  -E "SELECT \*|engine\.execute|cursor\.execute.*f['\"]|text\(f['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# ORM queries without field selection (may return all columns including sensitive)
grep -rn --include="*.py" \
  -E "(session\.query|db\.query)\(\w+\)\.filter\|Model\.objects\.all\(\)" \
  <repo_root> --exclude-dir=.git 2>/dev/null | head -20
# SELECT * or full model query without explicit column selection → LOW/INFO
```

---

## Check 6 — Unsafe deserialization

```bash
# pickle (arbitrary code execution on load)
grep -rn --include="*.py" \
  -E "import pickle|import dill|pickle\.(loads|load)\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Any pickle.loads → HIGH

# yaml.load without safe loader
grep -rn --include="*.py" \
  -E "yaml\.load\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "Loader="
# yaml.load without Loader → HIGH (use yaml.safe_load)

# eval / exec on external data
grep -rn --include="*.py" \
  -E "(eval|exec)\s*\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "#"
```

---

## Output schema

```json
[
  {
    "agent": "data_exposure",
    "severity": "CRITICAL",
    "rule_id": "jwt-no-algorithm",
    "file": "backend/auth/dependencies.py",
    "line": 22,
    "snippet": "jwt.decode(token, SECRET_KEY)",
    "description": "JWT decoded without specifying algorithms. Attacker can set alg='none' in token header to bypass signature verification entirely.",
    "remediation": "Always pass algorithms: jwt.decode(token, SECRET_KEY, algorithms=['HS256']). Use RS256 with public/private key pair for production."
  }
]
```
