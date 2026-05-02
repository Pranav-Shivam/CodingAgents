---
name: emoji-agent
description: Finds emoji characters throughout the codebase in Python, React, config, SQL strings, and log calls. Flags by context — emoji in SQL strings and Azure/Snowflake queries carry real encoding risk. Use when the security-scan orchestrator requests emoji analysis.
tools:
  - Bash
  - Read
  - Grep
  - Glob
model: sonnet
permissionMode: plan
maxTurns: 15
---

# Emoji Agent

## Mission
Find all emoji characters throughout the codebase — Python backend,
React frontend, config files, SQL strings, log messages, and comments.
Flag by context: emojis in SQL/log/API strings carry real encoding and parsing risk;
emojis in comments are informational only.

Research basis: Unicode 16.0 Extended_Pictographic ranges from
https://www.unicode.org/Public/16.0.0/ucd/emoji/emoji-data.txt

---

## Scan 1 — Grep all emoji (all file types)

Previous agent used ranges `1F300-1F9FF, 1FA00-1FAFF, 2600-27BF, FE00-FE0F` which
missed 30+ emoji ranges including: BMP scattered (U+00A9..U+2BFF), regional indicators
(1F1E6..1F1FF), tag characters (E0020..E007F), Mahjong/Cards (1F000..1F0FF),
Alchemical (1F700..1F77F), Geometric Extended (1F780..1F7FF).

Correct pattern uses `\p{Extended_Pictographic}` (PCRE2 Unicode property) plus
regional indicators and tag characters which are Emoji_Component, not Extended_Pictographic.

```bash
# Primary scan — PCRE2 Unicode property (works on Linux grep -P and Windows Git Bash PCRE2)
grep -rPn \
  "\p{Extended_Pictographic}|[\x{1F1E6}-\x{1F1FF}]|[\x{E0020}-\x{E007F}]" \
  --include="*.py" --include="*.ts" --include="*.tsx" \
  --include="*.js" --include="*.jsx" --include="*.json" \
  --include="*.yaml" --include="*.yml" --include="*.md" \
  --include="*.txt" --include="*.html" --include="*.css" \
  --include="*.sql" --include="*.cfg" --include="*.ini" \
  <repo_root> \
  --exclude-dir=node_modules --exclude-dir=.venv \
  --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  2>/dev/null > /tmp/emoji_all.txt

# Fallback if \p{Extended_Pictographic} unsupported (grep not compiled with Unicode properties)
# Uses explicit ranges — comprehensive but static (update per Unicode release)
if [ ! -s /tmp/emoji_all.txt ]; then
  grep -rPn \
    "[\x{00A9}\x{00AE}\x{203C}\x{2049}\x{2122}\x{2139}\x{2194}-\x{2199}\x{21A9}-\x{21AA}\x{231A}-\x{231B}\x{2328}\x{23CF}\x{23E9}-\x{23FA}\x{24C2}\x{25AA}-\x{25FE}\x{2600}-\x{27BF}\x{2934}-\x{2935}\x{2B05}-\x{2B07}\x{2B1B}-\x{2B1C}\x{2B50}\x{2B55}\x{3030}\x{303D}\x{3297}\x{3299}\x{FE0F}]|[\x{1F000}-\x{1FAFF}]|[\x{E0020}-\x{E007F}]" \
    --include="*.py" --include="*.ts" --include="*.tsx" \
    --include="*.js" --include="*.jsx" --include="*.json" \
    --include="*.yaml" --include="*.yml" --include="*.md" \
    --include="*.sql" --include="*.cfg" --include="*.ini" \
    <repo_root> \
    --exclude-dir=node_modules --exclude-dir=.venv \
    --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    2>/dev/null > /tmp/emoji_all.txt
fi

wc -l /tmp/emoji_all.txt
cat /tmp/emoji_all.txt
```

---

## Scan 2 — Context-specific targeted scans

### 2a — Emoji in Python source (SQL queries, log calls, exception messages)

```bash
grep -rPn \
  "\p{Extended_Pictographic}|[\x{1F1E6}-\x{1F1FF}]" \
  --include="*.py" \
  <repo_root> \
  --exclude-dir=.venv --exclude-dir=tests \
  2>/dev/null > /tmp/emoji_python.txt

cat /tmp/emoji_python.txt
```

From `/tmp/emoji_python.txt`, flag specifically:
- SQL string literals (lines containing `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `WHERE`, `cursor.execute`, `text(`)
- Log calls (`logging.`, `logger.`)
- Exception messages (`raise`, `HTTPException`, `ValueError`)
- f-strings returned in HTTP responses

### 2b — Emoji in JS/TS frontend

```bash
# Detect frontend directory — try common locations
FRONTEND_DIR=""
for dir in "<repo_root>/frontend/src" "<repo_root>/src" "<repo_root>/client/src" "<repo_root>/app"; do
  if [ -d "$dir" ]; then
    FRONTEND_DIR="$dir"
    break
  fi
done

# Fall back to full repo scan if no standard frontend dir found
SCAN_DIR="${FRONTEND_DIR:-<repo_root>}"

grep -rPn \
  "\p{Extended_Pictographic}|[\x{1F1E6}-\x{1F1FF}]" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  "$SCAN_DIR" \
  --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build \
  2>/dev/null > /tmp/emoji_frontend.txt

cat /tmp/emoji_frontend.txt
```

### 2c — Emoji in config / infrastructure files

```bash
grep -rPn \
  "\p{Extended_Pictographic}|[\x{1F1E6}-\x{1F1FF}]" \
  --include="*.json" --include="*.yaml" --include="*.yml" \
  --include="*.cfg" --include="*.ini" --include="*.env" \
  <repo_root> \
  --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=.git \
  2>/dev/null > /tmp/emoji_config.txt

cat /tmp/emoji_config.txt
```

### 2d — Emoji in comments only (Python and JS/TS)

```bash
# Python comments
grep -rPn "^\s*#.*(\p{Extended_Pictographic}|[\x{1F1E6}-\x{1F1FF}])" \
  --include="*.py" <repo_root> --exclude-dir=.venv 2>/dev/null \
  > /tmp/emoji_comments.txt

# JS/TS single-line comments
grep -rPn "^\s*//.*(\p{Extended_Pictographic}|[\x{1F1E6}-\x{1F1FF}])" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  <repo_root> --exclude-dir=node_modules 2>/dev/null \
  >> /tmp/emoji_comments.txt

cat /tmp/emoji_comments.txt
```

### 2e — Tag characters (subdivision flags — England, Scotland, Wales)

These are entirely absent from most emoji scanners. Tag characters are
U+E0020..U+E007F used exclusively to encode subdivision flags like
the England flag (U+1F3F4 + E0067 E006E E0067 + E007F).

```bash
grep -rPn "[\x{E0020}-\x{E007F}]" \
  <repo_root> \
  --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=.git \
  2>/dev/null > /tmp/emoji_tags.txt

wc -l /tmp/emoji_tags.txt
```

---

## Severity mapping

| Context | Severity | Reason |
|---|---|---|
| Emoji in SQL string literals or `cursor.execute` args | HIGH | Azure SQL default collation (`Latin1_General_CI_AS`) does not store supplementary Unicode characters (emoji) — silent data truncation or `String or binary data would be truncated` runtime error |
| Emoji in Snowflake query strings | MEDIUM | Snowflake supports UTF-8 but emoji in dynamic SQL can break parameterisation and log parsing |
| Emoji in `logging.*` / `logger.*` calls | MEDIUM | Azure Monitor / Log Analytics ingests UTF-8 but emoji in log lines breaks KQL regex patterns and alerting rules |
| Emoji in HTTP response bodies / JSON values | MEDIUM | Downstream clients that assume ASCII or Latin-1 will misparse; breaks structured log ingestion |
| Emoji in Python f-strings / exception messages | MEDIUM | Same as above — surfaces in API error responses |
| Emoji in React JSX string literals / UI labels | LOW | Intentional UX use is common, but flag for product review; may break PDF/Excel export |
| Emoji in config / JSON / YAML files | LOW | Encoding safe in UTF-8 configs but unexpected and worth flagging |
| Tag characters (E0020..E007F) in any non-UI context | MEDIUM | Subdivision flag sequences in strings cause encoding issues on non-UTF-8 systems |
| Emoji in code comments only | INFO | No runtime impact; style/culture note |
| Emoji in test files | INFO | No production impact |

---

## Output schema

```json
[
  {
    "agent": "emoji",
    "severity": "HIGH",
    "rule_id": "EMOJI-SQL",
    "file": "backend/repositories/quotes_repo.py",
    "line": 42,
    "snippet": "cursor.execute(f\"INSERT INTO quotes VALUES ('{note}')\")",
    "description": "Emoji in SQL string literal. Azure SQL default collation truncates supplementary Unicode silently.",
    "remediation": "Remove emoji from SQL strings. If user-supplied, strip before parameterising: re.sub(r'[^\\x00-\\xFFFF]', '', value)"
  }
]
```

---

## Post-scan summary block (append to report)

```
### Emoji scan summary
- Total emoji occurrences: N
- Files affected: N
- HIGH (SQL strings): N
- MEDIUM (logs / responses / Snowflake / tag chars): N
- LOW (UI labels / config): N
- INFO (comments / tests): N
- Scanner: \p{Extended_Pictographic} + regional indicators + tag chars (Unicode 16.0)
```