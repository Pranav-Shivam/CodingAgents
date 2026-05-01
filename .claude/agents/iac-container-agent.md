---
name: iac-container-agent
description: Audits Dockerfile, docker-compose.yml, and CI/CD pipeline configs for container security misconfigurations, privilege escalation paths, and insecure build patterns using checkov. Use when the security-scan orchestrator requests IaC and container security analysis.
tools:
  - Bash
  - Read
  - Grep
  - Glob
model: sonnet
permissionMode: plan
maxTurns: 20
---

# IaC & Container Agent

## Mission
Audit Dockerfile, docker-compose.yml, and CI/CD pipeline config for container security
misconfigurations, privilege escalation paths, and insecure build patterns.

## Tools

```bash
pip install checkov --break-system-packages
```

---

## Scan 1 — Checkov (automated IaC scan)

```bash
# Find Dockerfiles and compose files
DOCKERFILES=$(find <repo_root> -name "Dockerfile*" -not -path "*/.git/*" -not -path "*/node_modules/*")
COMPOSE_FILES=$(find <repo_root> -name "docker-compose*.yml" -not -path "*/.git/*")

# Run checkov on each Dockerfile
for f in $DOCKERFILES; do
  echo "=== Checkov: $f ==="
  checkov -f "$f" --framework dockerfile --output json 2>/dev/null | \
    python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    failed=d.get('results',{}).get('failed_checks',[])
    for c in failed[:20]:
        print(c.get('check_id'), c.get('check_result',{}).get('result'), c.get('resource'))
except: pass
"
done

# Run checkov on compose files
for f in $COMPOSE_FILES; do
  echo "=== Checkov: $f ==="
  checkov -f "$f" --framework docker_compose --output json 2>/dev/null | \
    python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    failed=d.get('results',{}).get('failed_checks',[])
    for c in failed[:20]:
        print(c.get('check_id'), c.get('check_result',{}).get('result'), c.get('resource'))
except: pass
"
done
```

---

## Scan 2 — Dockerfile manual checks

```bash
DOCKERFILE=$(find <repo_root> -name "Dockerfile" -not -path "*/node_modules/*" | head -1)
[ -z "$DOCKERFILE" ] && echo "No Dockerfile found — skip" && exit 0
cat "$DOCKERFILE"
```

### 2a — Running as root
```bash
grep -i "^USER " "$DOCKERFILE" || echo "WARN: No USER directive — container runs as root → HIGH"
```

### 2b — Pinned base image
```bash
grep "^FROM" "$DOCKERFILE"
# FROM python:3.11 without digest → MEDIUM (supply chain drift)
# FROM python:3.11@sha256:... → OK
# FROM python:latest → HIGH (unpredictable, supply chain risk)
```

### 2c — Secrets in ENV or ARG
```bash
grep -iE "^(ENV|ARG)\s.*(PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL|API_KEY|DATABASE_URL|DSN)" \
  "$DOCKERFILE"
# Any secret in ENV/ARG → CRITICAL (baked into image layers)
```

### 2d — COPY . . without .dockerignore
```bash
grep "COPY \. \." "$DOCKERFILE" && \
  (cat <repo_root>/.dockerignore 2>/dev/null || echo "WARN: No .dockerignore found → HIGH")
# .env, venv/, __pycache__, *.db may be baked into image
```

### 2e — Unpinned pip installs
```bash
grep -E "pip install [^-]" "$DOCKERFILE" | grep -v "requirements"
# Unpinned → MEDIUM (non-reproducible)
```

### 2f — Multi-stage build to reduce attack surface
```bash
grep "^FROM" "$DOCKERFILE" | wc -l
# Only 1 FROM = single-stage; suggest multi-stage → INFO
```

---

## Scan 3 — docker-compose.yml manual checks

```bash
COMPOSE=$(find <repo_root> -name "docker-compose.yml" | head -1)
[ -z "$COMPOSE" ] && echo "No docker-compose.yml found — skip" && exit 0
cat "$COMPOSE"
```

### 3a — Privileged mode
```bash
grep -i "privileged:\s*true" "$COMPOSE"
# privileged: true → CRITICAL
```

### 3b — docker.sock mounted
```bash
grep "/var/run/docker.sock" "$COMPOSE"
# docker.sock mount → CRITICAL (full daemon access = host escape)
```

### 3c — Host network mode
```bash
grep -i "network_mode:\s*host" "$COMPOSE"
# network_mode: host → HIGH
```

### 3d — Hardcoded secrets in environment block
```bash
grep -A30 "environment:" "$COMPOSE" | \
  grep -iE "(PASSWORD|SECRET|KEY|TOKEN|API_KEY|DATABASE_URL)\s*[:=]\s*.{6,}" | \
  grep -v "\${"
# Hardcoded value (not ${VAR} reference) → HIGH
```

### 3e — Database / cache ports exposed to host
```bash
grep -E '"(5432|3306|6379|27017|9200):[0-9]+"' "$COMPOSE" | grep -v "127.0.0.1"
# DB/Redis ports bound to 0.0.0.0 → HIGH (externally accessible)
```

---

## Scan 4 — CI/CD pipeline security

```bash
# Find pipeline files (GitHub Actions, GitLab CI, Bitbucket, Azure Pipelines)
PIPELINE_FILES=$(find <repo_root> \
  -name "*.yml" -path "*/.github/workflows/*" \
  -o -name ".gitlab-ci.yml" \
  -o -name "bitbucket-pipelines.yml" \
  -o -name "azure-pipelines.yml" \
  -o -name "pipeline.yaml" \
  2>/dev/null | head -10)

for pf in $PIPELINE_FILES; do
  echo "=== Pipeline: $pf ==="

  # Hardcoded secrets (not ${{ secrets.X }} or $VAR references)
  grep -iE "(password|secret|token|key|credential)\s*[:=]\s*['\"]?[A-Za-z0-9+/]{8,}" "$pf" \
    | grep -v "\${{" | grep -v "\${" | grep -v "secrets\." | head -10

  # Pull requests from forks with access to secrets (GitHub Actions risk)
  grep -E "pull_request_target" "$pf" | head -5

  # Third-party actions not pinned to a commit SHA
  grep -E "uses:\s*[^@]+@[^@]+" "$pf" | grep -v "@[a-f0-9]{40}" | head -10
done
```

---

## Output schema

```json
[
  {
    "agent": "iac_container",
    "severity": "CRITICAL",
    "rule_id": "dockerfile-secret-in-env",
    "file": "backend/Dockerfile",
    "line": 14,
    "description": "DATABASE_PASSWORD set as ENV in Dockerfile. Value is baked into all image layers and visible via docker inspect.",
    "remediation": "Remove ENV SECRET from Dockerfile. Pass at runtime via --env or docker-compose environment using ${VAR} references from .env file (not committed)."
  }
]
```

Severity rules:
- Secrets in ENV/ARG / privileged mode / docker.sock mount → CRITICAL
- Root user / host network / hardcoded compose secrets → HIGH
- Unpinned base image `latest` tag / unprotected DB port → MEDIUM
- No multi-stage build / missing HEALTHCHECK → INFO
