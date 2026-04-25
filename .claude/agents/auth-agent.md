---
name: auth-agent
description: Audits every authentication mechanism in the codebase — JWT, OAuth2, SAML, session, API keys, OIDC, MFA — for implementation flaws, weak configuration, token mishandling, and bypass vectors. Use when the security-scan orchestrator requests authentication security analysis.
tools:
  - Bash
  - Read
  - Grep
  - Glob
model: claude-sonnet-4-6
---

# Auth Security Agent

## Mission
Audit every authentication and authorization mechanism in the codebase — JWT, OAuth2,
SAML, session-based, API keys, OIDC, Basic Auth, magic links, and MFA — for
implementation flaws, weak configuration, token mishandling, and bypass vectors.

---

## Scan 1 — Detect auth mechanisms in use

```bash
# Detect from requirements and source
grep -rE "(\
python-jose|PyJWT|jwt|\
authlib|httpx-oauth|\
python3-saml|python-saml|pysaml2|\
itsdangerous|flask-login|django.contrib.auth|\
fastapi.security|OAuth2PasswordBearer|HTTPBearer|APIKeyHeader|\
passlib|bcrypt|argon2-cffi|\
starlette.middleware.sessions|\
msal|okta|onelogin|\
python-social-auth|social-core)" \
  <repo_root>/requirements*.txt \
  <repo_root>/pyproject.toml \
  <repo_root>/backend/requirements*.txt 2>/dev/null | sed 's/==.*//' | sort -u

# Detect auth patterns in Python source
grep -rn --include="*.py" \
  -E "(OAuth2PasswordBearer|OAuth2AuthorizationCodeBearer|HTTPBearer|\
APIKeyHeader|APIKeyQuery|HTTPBasic|\
JWTBearer|jwt\.decode|jwt\.encode|\
SAMLResponse|authn_request|\
msal\.ConfidentialClientApplication|OktaAuth)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -30
```

---

## Scan 2 — JWT security

```bash
# All jwt.decode calls — check for missing safety params
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# Missing algorithms= → none-algorithm attack
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "algorithms"
# → CRITICAL

# verify=False
grep -rn --include="*.py" \
  -E "jwt\.decode\(.*verify\s*=\s*False|options.*verify_signature.*False" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# → CRITICAL

# Missing expiry (exp) validation
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "exp\|leeway\|ExpiredSignatureError"
# → HIGH

# Short-lived token enforcement
grep -rn --include="*.py" \
  -E "(ACCESS_TOKEN_EXPIRE|TOKEN_EXPIRE|JWT_EXPIRY|timedelta)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# JWT secret key entropy (weak key → brute-forceable)
grep -rn --include="*.py" \
  -E "SECRET_KEY\s*=\s*['\"][^'\"]{0,24}['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Key shorter than 32 chars → HIGH
```

---

## Scan 3 — OAuth2 security

```bash
# Check OAuth2 state parameter (CSRF protection)
grep -rn --include="*.py" \
  -E "(state|oauth_state|csrf_token)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | \
  grep -iE "(oauth|authorize|callback)" | head -20
# Missing state param → HIGH (CSRF on OAuth flow)

# PKCE for public clients
grep -rn --include="*.py" \
  -E "(code_challenge|code_verifier|PKCE)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Implicit flow usage (deprecated, insecure)
grep -rn --include="*.py" \
  -E "response_type.*token|implicit.*flow|grant_type.*implicit" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# → HIGH (use authorization code + PKCE instead)

# Redirect URI validation
grep -rn --include="*.py" \
  -E "(redirect_uri|REDIRECT_URI|callback_url)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -20

# Open redirect in OAuth callback
grep -rn --include="*.py" \
  -E "redirect_uri\s*=\s*request\.(query_params|args|form)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Unvalidated redirect_uri → HIGH
```

---

## Scan 4 — SAML security

```bash
# SAML response handling
grep -rn --include="*.py" \
  -E "(SAMLResponse|authn_request|saml\.acs|process_response)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -20

# XXE in SAML XML parsing
grep -rn --include="*.py" \
  -E "(xml\.etree|lxml|defusedxml|XMLParser)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# SAML signature validation disabled
grep -rn --include="*.py" \
  -E "(verify_signatures|validate_cert|check_signature)\s*=\s*(False|0)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# → CRITICAL

# SAML replay protection (InResponseTo / assertion ID tracking)
grep -rn --include="*.py" \
  -E "(InResponseTo|assertion_id|replay)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
```

---

## Scan 5 — Session security

```bash
# Session middleware config
grep -rn --include="*.py" \
  -E "SessionMiddleware\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# Session secret key entropy
grep -rn --include="*.py" \
  -E "SessionMiddleware\(.*secret_key\s*=\s*['\"][^'\"]{0,24}['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Short key → HIGH

# Cookie flags (HttpOnly, Secure, SameSite)
grep -rn --include="*.py" \
  -E "(set_cookie|response\.set_cookie)\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | \
  grep -v "httponly\|secure\|samesite" | head -20
# Missing HttpOnly → HIGH. Missing Secure on auth cookie → HIGH.

# Session regeneration after login
grep -rn --include="*.py" \
  -E "(session\.clear\(\)|session\.regenerate\(\)|new_session|session_id.*generate)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# No session regeneration after login → MEDIUM (session fixation)
```

---

## Scan 6 — API key authentication

```bash
# API key storage (should be hashed, not stored in plaintext)
grep -rn --include="*.py" \
  -E "(api_key.*=.*hash|APIKey.*hashed|verify_api_key)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Timing-safe comparison for API keys
grep -rn --include="*.py" \
  -E "(hmac\.compare_digest|secrets\.compare_digest|constant_time_compare)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# Direct string comparison of API keys → MEDIUM (timing attack)

grep -rn --include="*.py" \
  -E "(api_key\s*==|key\s*==\s*request)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# Direct == comparison on API keys → MEDIUM
```

---

## Scan 7 — Password security

```bash
# Password hashing algorithm
grep -rn --include="*.py" \
  -E "(CryptContext|pwd_context|bcrypt|argon2|passlib)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Minimum password length / complexity enforcement
grep -rn --include="*.py" \
  -E "(min_length|password_validator|PasswordStrength|validate_password)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# No password complexity validation → MEDIUM

# Password reset token handling
grep -rn --include="*.py" \
  -E "(reset_token|password_reset|forgot_password)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -20
```

---

## Scan 8 — Rate limiting on auth endpoints

```bash
# Rate limit on login/token endpoints
grep -rn --include="*.py" \
  -E "(@limiter\.|RateLimiter|rate_limit)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | \
  grep -iE "(login|token|auth|signin|password)" | head -10
# No rate limit on /token or /login → HIGH (brute-force)
```

---

## Scan 9 — React/frontend auth token handling

```bash
# JWT stored in localStorage (XSS-accessible)
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  -E "localStorage\.(setItem|getItem)\(['\"].*(token|jwt|auth)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null
# → HIGH (use httpOnly cookie instead)

# Authorization header construction
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  -E "Authorization.*Bearer|headers.*Authorization" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -10

# Token refresh logic
grep -rn --include="*.ts" --include="*.tsx" \
  -E "(refreshToken|refresh_token|useRefreshToken|interceptors.*401)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -10
```

---

## Scan 10 — MFA coverage

```bash
# MFA library usage
grep -rn --include="*.py" \
  -E "(pyotp|totp|hotp|qrcode|two_factor|mfa|authenticator)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# MFA enforcement on admin/privileged routes
grep -rn --include="*.py" \
  -E "(is_mfa_verified|mfa_required|require_mfa|totp_verified)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# Admin routes without MFA enforcement → MEDIUM
```

---

## Output schema

```json
[
  {
    "agent": "auth",
    "severity": "CRITICAL",
    "rule_id": "jwt-algorithm-none",
    "file": "backend/auth/jwt_handler.py",
    "line": 18,
    "snippet": "jwt.decode(token, SECRET_KEY)",
    "description": "jwt.decode called without algorithms parameter. Attacker can craft a token with alg='none' in the header to bypass signature verification entirely.",
    "remediation": "Always specify algorithms: jwt.decode(token, SECRET_KEY, algorithms=['HS256']). Consider switching to RS256 with asymmetric keys for stronger guarantees."
  }
]
```
