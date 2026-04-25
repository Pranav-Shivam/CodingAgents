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
# All jwt.decode() calls
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null > /tmp/jwt_decode_calls.txt
cat /tmp/jwt_decode_calls.txt

# CRITICAL: verify=False or verify_signature=False
grep -rn --include="*.py" \
  -E "jwt\.decode\(.*verify\s*=\s*False|\
options\s*=\s*\{.*['\"]verify_signature['\"].*False|\
options\s*=\s*\{.*['\"]verify_exp['\"].*False" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# CRITICAL: missing algorithms parameter (none-algorithm attack)
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "algorithms\s*="

# HIGH: missing audience validation
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "audience\|aud"

# HIGH: missing issuer validation
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "issuer\|iss"

# MEDIUM: HS256 symmetric key shorter than 256 bits (32 bytes)
grep -rn --include="*.py" \
  -E "SECRET_KEY\s*=\s*['\"][^'\"]{1,31}['\"]|JWT_SECRET\s*=\s*['\"][^'\"]{1,31}['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null

# Token expiry set
grep -rn --include="*.py" \
  -E "(exp|expires_delta|ACCESS_TOKEN_EXPIRE)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Refresh token handling
grep -rn --include="*.py" \
  -E "(refresh_token|REFRESH_TOKEN)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Tokens returned in response body (should prefer HttpOnly cookies)
grep -rn --include="*.py" \
  -E "return.*['\"]access_token['\"]|JSONResponse.*access_token|return.*token.*jwt" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
```

---

## Scan 3 — OAuth2 / OIDC security

```bash
# OAuth2PasswordBearer setup
grep -rn --include="*.py" \
  -E "OAuth2PasswordBearer\(|OAuth2AuthorizationCodeBearer\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# State parameter missing in OAuth2 flows (CSRF on redirect)
grep -rn --include="*.py" \
  -E "(authorize_url|authorization_url|auth_uri)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "state" | head -10
# OAuth2 flow without state parameter → HIGH (CSRF)

# PKCE used in authorization code flow (required for public clients)
grep -rn --include="*.py" --include="*.ts" --include="*.tsx" \
  -E "(code_verifier|code_challenge|PKCE)" \
  <repo_root> --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | head -10

# Implicit flow still used (deprecated, insecure)
grep -rn --include="*.py" --include="*.ts" --include="*.tsx" \
  -E "response_type\s*=\s*['\"]token['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | head -10
# Implicit flow → HIGH (tokens in URL fragment)

# Token endpoint using GET (tokens should only be sent via POST body)
grep -rn --include="*.py" \
  -E "@(app|router)\.get\(.*token|access_token.*GET" \
  <repo_root> --exclude-dir=.git 2>/dev/null

# Open redirect in OAuth2 callback
grep -rn --include="*.py" \
  -E "(redirect_uri|callback_url|next_url)\s*=\s*request\." \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "ALLOWED\|whitelist\|allowed"
# Unvalidated redirect_uri → HIGH (open redirect / token theft)
```

---

## Scan 4 — SAML security (if used)

```bash
SAML_FILES=$(grep -rln --include="*.py" \
  -E "(SAMLResponse|authn_request|python3_saml|saml2|OneLogin)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null)

[ -z "$SAML_FILES" ] && echo "No SAML usage detected — skip Scan 4" && exit 0

echo "SAML files found: $SAML_FILES"

# Check settings for critical security flags
python3 -c "
import json, glob
for f in glob.glob('<repo_root>/**/saml_settings.json', recursive=True) + \
          glob.glob('<repo_root>/**/settings.json', recursive=True):
    try:
        with open(f) as fp:
            s = json.load(fp)
        security = s.get('security', {})
        required = {
            'wantAssertionsSigned': True,
            'wantMessagesSigned': True,
            'rejectDeprecatedAlgorithm': True,
            'signMetadata': True,
            'wantNameIdEncrypted': False,  # warn if False but not block
        }
        for k, expected in required.items():
            v = security.get(k, 'NOT SET')
            status = 'OK' if v == expected else f'WARN — expected {expected}'
            print(f'{f}: {k} = {v} [{status}]')
    except Exception as e:
        pass
" 2>/dev/null

# XXE vulnerability: SAML response parsed with lxml/etree without defusedxml
grep -rn --include="*.py" \
  -E "(etree\.fromstring|lxml.*fromstring|ElementTree\.fromstring)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "defusedxml"
# lxml/etree without defusedxml → CRITICAL (XXE on SAML response)

# SAML assertion attributes trusted before signature validation
grep -rn --include="*.py" \
  -E "get_attributes\(\)|getAttributes\(\)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Replay attack protection: check InResponseTo / timestamp validation
grep -rn --include="*.py" \
  -E "(InResponseTo|notOnOrAfter|notBefore|valid_until)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
```

---

## Scan 5 — Session security

```bash
# Session middleware setup
grep -rn --include="*.py" \
  -E "(SessionMiddleware|starlette.middleware.sessions|session_cookie|cookie_name)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Session secret key hardcoded or weak
grep -rn --include="*.py" \
  -E "SessionMiddleware\(.*secret_key\s*=\s*['\"][^'\"]{1,20}['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Short/hardcoded secret → HIGH

# Session cookie flags
grep -rn --include="*.py" \
  -E "(https_only\s*=\s*False|secure\s*=\s*False|httponly\s*=\s*False|samesite\s*=\s*['\"]None['\"])" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# secure=False → HIGH. httponly=False → HIGH. samesite=None without secure → HIGH.

# Session fixation: session regenerated after login?
grep -rn --include="*.py" \
  -E "(request\.session\.clear\(\)|session\.regenerate|new_session)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Absolute session timeout set
grep -rn --include="*.py" \
  -E "(SESSION_EXPIRE|max_age|session_lifetime|SESSION_TIMEOUT)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
```

---

## Scan 6 — API key authentication

```bash
# API key read from header or query
grep -rn --include="*.py" \
  -E "(APIKeyHeader|APIKeyQuery|APIKeyCookie)\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# API key compared with == (timing attack)
grep -rn --include="*.py" \
  -E "api_key\s*==\s*|x_api_key\s*==\s*|token\s*==\s*['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "secrets.compare_digest\|hmac.compare_digest"
# Direct == comparison on secrets → MEDIUM (use hmac.compare_digest or secrets.compare_digest)

# API keys in query string (logged by proxies/servers)
grep -rn --include="*.py" \
  -E "APIKeyQuery\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# APIKeyQuery (key in URL) → MEDIUM (prefer header)

# Hardcoded API keys for internal service auth
grep -rn --include="*.py" \
  -E "(INTERNAL_API_KEY|SERVICE_API_KEY|X_API_KEY)\s*=\s*['\"][^'\"]{8,}['\"]" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
```

---

## Scan 7 — Password handling

```bash
# Password hashing library in use
grep -rn --include="*.py" \
  -E "(CryptContext|pwd_context|bcrypt\.hashpw|argon2\.hash|passlib)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Weak scheme in CryptContext
grep -rn --include="*.py" \
  -E "CryptContext\(.*schemes.*['\"]?(md5_crypt|des_crypt|sha1_crypt|plaintext)['\"]?" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Weak scheme → HIGH

# Plain SHA for password hashing
grep -rn --include="*.py" \
  -E "(hashlib\.(sha256|sha512|md5)\(.*password|sha256\(.*password\.encode)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | grep -v "bcrypt\|argon2\|pbkdf2\|scrypt"
# Plain SHA without salt/iterations → HIGH

# Password length / complexity checks present
grep -rn --include="*.py" \
  -E "(min_length|password.*len|validate_password|check_password_strength)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Password stored in plaintext anywhere
grep -rn --include="*.py" \
  -E "user\.password\s*=\s*password|db_user\.password\s*=\s*plain" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Plaintext password storage → CRITICAL
```

---

## Scan 8 — Rate limiting on auth endpoints

```bash
# Check for rate limiting on login / token / auth routes
grep -rn --include="*.py" \
  -E "(slowapi|RateLimiter|@limiter\.limit|rate_limit)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Auth endpoints without rate limiting
grep -rn --include="*.py" \
  -E "@(app|router)\.(post|get)\(.*(/auth|/login|/token|/signup|/register|/reset-password|/forgot-password)" \
  <repo_root> --exclude-dir=.git 2>/dev/null > /tmp/auth_endpoints.txt

grep -rn --include="*.py" \
  -E "@limiter\.limit|@rate_limit|RateLimiter" \
  <repo_root> --exclude-dir=.git 2>/dev/null > /tmp/rate_limited.txt

echo "Auth endpoints: $(wc -l < /tmp/auth_endpoints.txt)"
echo "Rate-limited handlers: $(wc -l < /tmp/rate_limited.txt)"
```

No rate limiting on `/login` or `/token` → HIGH (brute force / credential stuffing).

---

## Scan 9 — React / frontend auth handling

```bash
# Token storage (localStorage is XSS-accessible, prefer HttpOnly cookies)
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  -E "(localStorage|sessionStorage)\.(setItem|getItem).*['\"].*(token|jwt|auth|access|refresh)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null > /tmp/frontend_token_storage.txt

# Token in URL / hash fragment (implicit flow artifact)
grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  -E "(location\.hash|window\.location\.hash|URLSearchParams.*access_token|hash.*token)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -10

# Auth state in React context exposed globally
grep -rn --include="*.ts" --include="*.tsx" \
  -E "(AuthContext|useAuth|authState|currentUser).*token|token.*AuthContext" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -10

# MSAL / OIDC SDK: check production logging guard
grep -rn --include="*.ts" --include="*.tsx" \
  -E "loggerCallback" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null
# loggerCallback without NODE_ENV production guard → MEDIUM (auth logs in DevTools)

# Protected routes: client-side only check (must be backed by server auth)
grep -rn --include="*.tsx" --include="*.ts" \
  -E "(PrivateRoute|ProtectedRoute|RequireAuth|withAuth)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -10
```

---

## Scan 10 — MFA and account takeover surface

```bash
# Check if TOTP / MFA is implemented
grep -rn --include="*.py" \
  -E "(pyotp|totp|hotp|mfa|two_factor|2fa|authenticator)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Password reset: token secure and time-limited?
grep -rn --include="*.py" \
  -E "(password_reset|reset_token|forgot_password)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10

# Confirm reset tokens expire
grep -rn --include="*.py" \
  -E "(RESET_TOKEN_EXPIRE|reset.*expires|token.*expiry)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# No expiry on reset tokens → HIGH

# Account enumeration via login error messages
grep -rn --include="*.py" \
  -E "raise HTTPException.*(['\"]User not found['\"]|['\"]Email not registered['\"]|['\"]No account['\"])" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
# Distinct error for "user not found" vs "wrong password" → LOW (enumeration)

# Brute force: lockout after N failures?
grep -rn --include="*.py" \
  -E "(login_attempts|failed_attempts|account_locked|lockout)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
```

---

## Output schema

```json
[
  {
    "agent": "auth",
    "severity": "CRITICAL",
    "rule_id": "jwt-no-algorithm",
    "file": "backend/auth/dependencies.py",
    "line": 28,
    "auth_type": "JWT",
    "snippet": "payload = jwt.decode(token, settings.SECRET_KEY)",
    "description": "jwt.decode called without algorithms parameter. Attacker can forge a token with alg='none' to completely bypass signature verification.",
    "remediation": "Always specify algorithms: jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256']). For production prefer RS256 with asymmetric keys."
  },
  {
    "agent": "auth",
    "severity": "HIGH",
    "rule_id": "oauth2-missing-state",
    "file": "backend/auth/oauth.py",
    "line": 55,
    "auth_type": "OAuth2",
    "snippet": "return RedirectResponse(authorization_url)",
    "description": "OAuth2 authorization redirect missing state parameter. Attacker can perform CSRF to force authorization code grant.",
    "remediation": "Generate a cryptographically random state, store in session, include in redirect, validate on callback: state = secrets.token_urlsafe(32)"
  }
]
```
