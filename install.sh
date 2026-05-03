#!/usr/bin/env bash
# install.sh — install auto-terminal into any Claude Code project
# Usage: bash install.sh [target-dir]
# Default target: current working directory

set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing auto-terminal into: ${TARGET_DIR}"

# Create directory structure
mkdir -p "${TARGET_DIR}/.claude/commands"
mkdir -p "${TARGET_DIR}/.claude/scripts"
mkdir -p "${TARGET_DIR}/.claude/logs"
mkdir -p "${TARGET_DIR}/reports"

# Copy files
cp "${SOURCE_DIR}/.claude/commands/auto-terminal.md" "${TARGET_DIR}/.claude/commands/auto-terminal.md"
cp "${SOURCE_DIR}/.claude/scripts/spawn-subagent.sh"  "${TARGET_DIR}/.claude/scripts/spawn-subagent.sh"
cp "${SOURCE_DIR}/.claude/scripts/notify.sh"          "${TARGET_DIR}/.claude/scripts/notify.sh"
cp "${SOURCE_DIR}/.claude/report-template.md"         "${TARGET_DIR}/.claude/report-template.md"

# Make scripts executable
chmod +x "${TARGET_DIR}/.claude/scripts/spawn-subagent.sh"
chmod +x "${TARGET_DIR}/.claude/scripts/notify.sh"

# Touch agent-status file
touch "${TARGET_DIR}/.claude/agent-status"

# Merge CLAUDE.md section (guard against duplicate)
CLAUDE_MD="${TARGET_DIR}/CLAUDE.md"
MARKER="## auto-terminal"

CLAUDE_SECTION='
## auto-terminal

### How it works

`/auto-terminal <task>` spawns a child Claude Code agent in a new terminal window.
Child works autonomously on a separate task while parent continues unblocked.

**Flow:**
1. Parent writes `.claude/fork-context.md` — lean project snapshot for the child
2. Parent runs `bash .claude/scripts/spawn-subagent.sh "<slug>" "<task>"`
3. Child opens in new terminal, reads fork-context.md, works fully autonomously
4. Child writes report to `reports/<slug>-report.md` when done
5. Child signals completion: `echo "DONE:<slug>" >> .claude/agent-status`
6. Child calls `bash .claude/scripts/notify.sh "<slug>"` for desktop notification
7. Parent checks `.claude/agent-status` at natural breakpoints

### Report naming — always `<slug>-report.md`

Every report file: `reports/<slug>-report.md`
- Never `reports/<slug>.md`
- slug = lowercase hyphenated task name, max 4 words
- Example: "build frontend components" → `reports/frontend-components-report.md`
- This pattern is enforced in: spawn-subagent.sh, child prompt, notify.sh, auto-terminal.md

### File ownership

Parent declares owned files in `fork-context.md` under `parent_owns`.
Child reads but never writes to those paths.
Each child owns whatever it creates — listed in its report under "Files created".

### Multiple simultaneous children

Each child gets a unique slug. `.claude/agent-status` is append-only:
```
DONE:frontend-components
DONE:auth-middleware
```
Parent checks each slug independently. Each child notifies independently.
Never summarize child output in parent thread — point to `reports/<slug>-report.md`.

### Runtime files (not committed)

- `.claude/agent-status` — completion signals (append-only)
- `.claude/logs/<slug>.log` — child stdout
- `.claude/fork-context.md` — project snapshot (overwritten each spawn)
- `.claude/child-prompt-<slug>.md` — child system prompt
- `.claude/child-pid-<slug>` — PID file (headless fallback only)
'

if [ -f "$CLAUDE_MD" ]; then
  if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
    echo "CLAUDE.md already contains auto-terminal section — skipping merge"
  else
    echo "$CLAUDE_SECTION" >> "$CLAUDE_MD"
    echo "Merged auto-terminal section into existing CLAUDE.md"
  fi
else
  echo "# CLAUDE.md" > "$CLAUDE_MD"
  echo "$CLAUDE_SECTION" >> "$CLAUDE_MD"
  echo "Created CLAUDE.md with auto-terminal section"
fi

# Add runtime files to .gitignore
GITIGNORE="${TARGET_DIR}/.gitignore"
GITIGNORE_ENTRIES=(
  ".claude/agent-status"
  ".claude/logs/"
  ".claude/fork-context.md"
  ".claude/child-prompt-*.md"
  ".claude/child-pid-*"
  ".claude/launcher-*.sh"
)

if [ ! -f "$GITIGNORE" ]; then
  touch "$GITIGNORE"
fi

for entry in "${GITIGNORE_ENTRIES[@]}"; do
  if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
    echo "$entry" >> "$GITIGNORE"
    echo "Added to .gitignore: $entry"
  fi
done

echo ""
echo "Installed. Usage: /auto-terminal <task>  |  Reports -> reports/<feature-name>-report.md"
