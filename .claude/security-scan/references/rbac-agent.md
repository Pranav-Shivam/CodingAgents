# RBAC & Access Control Agent

## Mission
Audit application-level RBAC logic, route-level auth coverage, permission decorator
patterns, and dependency injection structure for over-permissioned access and missing
authorization checks in any FastAPI + React application.

---

## Scan 1 — FastAPI route auth coverage

```bash
# All route handlers
grep -rn --include="*.py" \
  -E "@(app|router)\.(get|post|put|delete|patch|head|options)\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null \
  > /tmp/all_routes.txt

echo "Total route handlers: $(wc -l < /tmp/all_routes.txt)"

# Routes with auth dependency
grep -rn --include="*.py" \
  -E "Depends\((get_current_user|verify_token|get_current_active_user|oauth2_scheme|require_auth|get_user|authenticate)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null \
  > /tmp/protected_routes.txt

echo "Handlers with auth dependency: $(wc -l < /tmp/protected_routes.txt)"

# Check global dependency injection on router or app
grep -rn --include="*.py" \
  -E "(APIRouter|FastAPI)\(.*dependencies\s*=\s*\[Depends" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null
```

Flag: route handlers with no auth dependency that aren't explicitly public (health, ping, auth endpoints) → HIGH.

---

## Scan 2 — Permission / role check coverage

```bash
# Find permission decorator or role check pattern
grep -rn --include="*.py" \
  -E "(@require_permission|@require_role|@has_permission|Depends.*permission|check_permission|verify_role)" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null > /tmp/permission_checks.txt

# Find admin / write / delete endpoints — should have permission check, not just auth
grep -rn --include="*.py" \
  -E "@(app|router)\.(post|put|delete|patch)\(" \
  <repo_root> --exclude-dir=.git --exclude-dir=venv 2>/dev/null | \
  grep -v "$(grep -oE '(get_current_user|require_permission|has_permission|check_permission|verify_role)[^\)]*' \
    /tmp/permission_checks.txt | head -5 | tr '\n' '|' | sed 's/|$//')" \
  > /tmp/mutating_routes_no_permission.txt

# Wildcard / ALL permission grants
grep -rn --include="*.py" \
  -E "['\"]\\*['\"]|ALL_PERMISSIONS|is_superuser\s*=\s*True|roles\s*=\s*\[.*admin" \
  <repo_root>/backend --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -20
```

---

## Scan 3 — Role and permission definitions

```bash
# Find role/permission enums or constants
grep -rn --include="*.py" \
  -E "(class Role|class Permission|ROLES\s*=|PERMISSIONS\s*=|role_map|permission_map)" \
  <repo_root>/backend --exclude-dir=.git 2>/dev/null | head -20

# Check for hardcoded superuser/admin checks
grep -rn --include="*.py" \
  -E "(is_admin|is_superuser|role\s*==\s*['\"]admin['\"]|role\s*in\s*\[.*admin)" \
  <repo_root>/backend --exclude-dir=.git 2>/dev/null | head -20
```

---

## Scan 4 — Frontend-only role enforcement (insecure)

```bash
# Role/permission checks only in React (not backed by server-side check)
grep -rn --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" \
  -E "(userRole|hasRole|isAdmin|canEdit|hasPermission|user\.role\s*===)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -20

# React routes that conditionally render based on role
grep -rn --include="*.tsx" --include="*.ts" \
  -E "(<Route|navigate|redirect).*role|role.*(<Route|navigate|redirect)" \
  <repo_root>/frontend/src --exclude-dir=node_modules 2>/dev/null | head -10
```

Flag as HIGH if: role-restricted UI components exist in React but corresponding backend
endpoints do not have `@require_permission` or equivalent server-side check.

---

## Scan 5 — Auth dependencies structure audit

```bash
# Show all Depends() chains (to understand auth hierarchy)
grep -rn --include="*.py" \
  -E "def (get_current_user|get_current_active_user|verify_token|get_user|authenticate)" \
  <repo_root>/backend --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -20

# Check if token expiry is validated
grep -rn --include="*.py" \
  -E "(exp|expiry|expires_at|TokenExpired|ExpiredSignatureError)" \
  <repo_root>/backend --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
# No expiry check → HIGH

# Check if inactive/banned users are blocked
grep -rn --include="*.py" \
  -E "(is_active|is_banned|is_disabled|user\.active|status.*active)" \
  <repo_root>/backend --exclude-dir=.git --exclude-dir=venv 2>/dev/null | head -10
```

---

## Scan 6 — Object-level authorization (IDOR check)

```bash
# Find resource fetches by ID that may not verify ownership
grep -rn --include="*.py" \
  -E "(get_by_id|\.get\(id|filter_by\(id|\.filter\(.*\.id\s*==)" \
  <repo_root>/backend --exclude-dir=.git --exclude-dir=venv 2>/dev/null \
  | grep -v "current_user\|user_id\|owner\|belongs_to" \
  | head -20
# Resource fetched by ID without user ownership check → potential IDOR → HIGH
```

---

## Scan 7 — API key / service account scope

```bash
# Check if separate service account is used for DB access
grep -rn --include="*.py" \
  -E "(DB_USER|DATABASE_USER|POSTGRES_USER|MYSQL_USER)" \
  <repo_root> --exclude-dir=.git 2>/dev/null | head -10

# Check if application uses a root/superuser DB account
grep -rn --include="*.py" --include="*.env" \
  -E "(root|admin|postgres|sa).*@|DATABASE_URL.*root\|DATABASE_URL.*admin@" \
  <repo_root> --exclude-dir=.git 2>/dev/null
# DB connecting as root/admin → HIGH (should use a scoped service user)
```

---

## Output schema

```json
[
  {
    "agent": "rbac",
    "severity": "HIGH",
    "rule_id": "idor-no-ownership-check",
    "file": "backend/api/routers/documents.py",
    "line": 34,
    "description": "Document fetched by ID (GET /documents/{id}) with no check that document.owner_id == current_user.id. Any authenticated user can access any document.",
    "remediation": "Add ownership check: if document.owner_id != current_user.id: raise HTTPException(status_code=403)"
  }
]
```

Severity rules:
- Frontend-only role check with no backend enforcement / unprotected mutating route → HIGH
- No token expiry check / DB connecting as root / IDOR risk / wildcard permission → HIGH
- Admin endpoint missing specific permission check (only general auth) → MEDIUM
- No inactive user check / missing global dependency / no role enum definition → LOW/MEDIUM
