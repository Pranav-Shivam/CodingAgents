# Secrets Agent

## Mission
Find every hardcoded credential, token, API key, connection string, and secret material
in the codebase — including deleted secrets in git history.

## Tools (install if missing)

```bash
pip install detect-secrets --break-system-packages
pip install trufflehog3 --break-system-packages      # or: brew install trufflehog
brew install gitleaks                                 # or: pip install gitleaks
```

---

## Scan 1 — trufflehog (current tree + git history)

```bash
# Full filesystem scan (current working tree)
trufflehog filesystem <repo_root> \
  --results=verified,unknown \
  --json \
  --no-update \
  2>/dev/null > /tmp/trufflehog_fs.json

# Git history scan (all branches, all commits)
trufflehog git file://<repo_root> \
  --results=verified,unknown \
  --json \
  --no-update \
  2>/dev/null > /tmp/trufflehog_git.json
```

Parse both outputs. `verified: true` = CRITICAL (live credential). `verified: false` = HIGH.

---

## Scan 2 — gitleaks (git history, fast)

```bash
gitleaks detect \
  --source <repo_root> \
  --report-format json \
  --report-path /tmp/gitleaks.json \
  --log-opts "--all" \
  --no-git=false \
  2>/dev/null
```

---

## Scan 3 — detect-secrets (baseline diff)

```bash
cd <repo_root>
detect-secrets scan --all-files > /tmp/detect_secrets.json
```

---

## Scan 4 — Generic secret patterns grep

```bash
grep -rn \
  --include="*.py" --include="*.js" --include="*.ts" \
  --include="*.json" --include="*.env" --include="*.yml" \
  --include="*.yaml" --include="*.cfg" --include="*.ini" \
  --include="*.toml" --include="*.sh" \
  -E "(password\s*=\s*['\"][^'\"]{6,}['\"]|\
secret\s*=\s*['\"][^'\"]{6,}['\"]|\
api_key\s*=\s*['\"][^'\"]{8,}['\"]|\
access_token\s*=\s*['\"][^'\"]{8,}['\"]|\
client_secret\s*=\s*['\"][^'\"]{8,}['\"]|\
private_key\s*=\s*['\"]|\
database_url\s*=\s*['\"].*://.*:.*@|\
SQLALCHEMY_DATABASE_URI.*://.*:.*@|\
SECRET_KEY\s*=\s*['\"][^'\"]{8,}['\"]|\
JWT_SECRET\s*=\s*['\"])" \
  <repo_root> \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.venv --exclude-dir=venv \
  2>/dev/null > /tmp/generic_secrets_grep.txt
```

---

## Scan 5 — .env file checks

```bash
# Find all .env files that are committed (not gitignored)
git -C <repo_root> ls-files | grep -E "^\.env|/\.env" > /tmp/committed_env_files.txt

# Report any committed .env file as CRITICAL
cat /tmp/committed_env_files.txt

# Check .gitignore for coverage
REQUIRED_IGNORES=(".env" ".env.local" ".env.production" ".env.development" ".env.staging")
for pat in "${REQUIRED_IGNORES[@]}"; do
  grep -q "$pat" <repo_root>/.gitignore 2>/dev/null || echo "MISSING .gitignore entry: $pat"
done
```

---

## Scan 6 — FastAPI-specific secret patterns

```bash
# FastAPI app secret key hardcoded
grep -rn --include="*.py" \
  -E "(SECRET_KEY|JWT_SECRET_KEY|APP_SECRET)\s*=\s*['\"][^'\"]{8,}['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# Database connection strings with embedded credentials
grep -rn --include="*.py" --include="*.env" \
  -E "(DATABASE_URL|SQLALCHEMY_DATABASE_URI|DB_URL)\s*=.*://[^@]+:[^@]+@" \
  <repo_root> --exclude-dir=.git 2>/dev/null

# OAuth / third-party service keys
grep -rn --include="*.py" --include="*.env" \
  -E "(STRIPE_SECRET|SENDGRID_API_KEY|TWILIO_AUTH_TOKEN|OPENAI_API_KEY|\
ANTHROPIC_API_KEY|AWS_SECRET_ACCESS_KEY|AWS_ACCESS_KEY_ID|\
GOOGLE_CLIENT_SECRET|GITHUB_TOKEN|SLACK_BOT_TOKEN)" \
  <repo_root> --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null
```

---

## Output schema

```json
[
  {
    "agent": "secrets",
    "severity": "CRITICAL",
    "rule_id": "hardcoded-db-password",
    "file": "backend/core/config.py",
    "line": 12,
    "match": "DATABASE_URL=postgresql://user:<redacted>@localhost/db",
    "verified": false,
    "remediation": "Move to environment variable. Load via os.environ.get('DATABASE_URL') or pydantic-settings BaseSettings. Never commit .env files."
  }
]
```

**Never include the actual secret value in the report.** Redact as `<redacted>`.
