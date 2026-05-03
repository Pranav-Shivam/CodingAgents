#!/usr/bin/env bash
# spawn-subagent.sh — launches a child Claude Code agent in a new terminal
# Usage: bash .claude/scripts/spawn-subagent.sh "<slug>" "<task description>"

set -euo pipefail

TASK_SLUG="${1:?slug required}"
TASK_DESC="${2:?task description required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_PATH="reports/${TASK_SLUG}-report.md"
PROMPT_FILE="${REPO_ROOT}/.claude/child-prompt-${TASK_SLUG}.md"
LOG_FILE="${REPO_ROOT}/.claude/logs/${TASK_SLUG}.log"
STATUS_FILE="${REPO_ROOT}/.claude/agent-status"
CONTEXT_FILE="${REPO_ROOT}/.claude/fork-context.md"
NOTIFY_SCRIPT="${REPO_ROOT}/.claude/scripts/notify.sh"

mkdir -p "${REPO_ROOT}/.claude/logs"
mkdir -p "${REPO_ROOT}/reports"

# Write child system prompt
cat > "$PROMPT_FILE" <<PROMPT
You are a Claude Code child agent spawned by /auto-terminal.

## Your task
${TASK_DESC}

## Project context
Read .claude/fork-context.md immediately. It contains:
- The project root and tech stack
- What the parent session is working on (do NOT touch those files)
- File paths relevant to your task
- Conventions you must follow exactly

## Working directory
${REPO_ROOT}

## Your report
When done, write a complete report to: ${REPORT_PATH}

Use the template at .claude/report-template.md. Fill every section. The header of your report must be: ${TASK_SLUG}-report

## Completion signal
After writing the report, run exactly:
  echo "DONE:${TASK_SLUG}" >> .claude/agent-status
Then run:
  bash .claude/scripts/notify.sh "${TASK_SLUG}"

## Rules
1. Read .claude/fork-context.md before doing anything else
2. Never touch files listed under parent_owns in fork-context.md
3. Work fully autonomously — use all tools (Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch)
4. Follow all project conventions from fork-context.md exactly
5. Do not ask questions — make decisions and document them in the report
6. Your report is your only output channel to the parent — make it complete
7. Report path is always ${REPORT_PATH} — no variations
PROMPT

# Resolve claude CLI path — new terminals may not inherit npm PATH
CLAUDE_BIN="$(command -v claude 2>/dev/null || echo "claude")"

# Write a launcher script — avoids quoting/length limits when passing prompt content
LAUNCHER="${REPO_ROOT}/.claude/launcher-${TASK_SLUG}.sh"
cat > "$LAUNCHER" <<LAUNCHER_EOF
#!/usr/bin/env bash
# Source profile so npm/nvm PATH entries are available
# shellcheck disable=SC1091
[ -f "\$HOME/.bashrc" ] && source "\$HOME/.bashrc" 2>/dev/null || true
[ -f "\$HOME/.bash_profile" ] && source "\$HOME/.bash_profile" 2>/dev/null || true

cd "${REPO_ROOT}"
"${CLAUDE_BIN}" --dangerously-skip-permissions -p "\$(cat '${PROMPT_FILE}')" 2>&1 | tee '${LOG_FILE}'
echo ""
echo "--- child done: ${TASK_SLUG} | report: ${REPORT_PATH} ---"
# Keep terminal open so user can see output
exec bash
LAUNCHER_EOF
chmod +x "$LAUNCHER"

# Detect OS and open new terminal
OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"

case "$OS_TYPE" in
  Darwin)
    # macOS: try iTerm2 first, fall back to Terminal.app
    if osascript -e 'tell application "iTerm2" to version' &>/dev/null 2>&1; then
      osascript <<APPLESCRIPT
tell application "iTerm2"
  create window with default profile
  tell current session of current window
    write text "bash '${LAUNCHER}'"
  end tell
end tell
APPLESCRIPT
    else
      osascript <<APPLESCRIPT
tell application "Terminal"
  do script "bash '${LAUNCHER}'"
  activate
end tell
APPLESCRIPT
    fi
    ;;

  Linux)
    if command -v gnome-terminal &>/dev/null; then
      gnome-terminal -- bash -c "bash '${LAUNCHER}'; exec bash" &
    elif command -v wezterm &>/dev/null; then
      wezterm start -- bash "${LAUNCHER}" &
    elif command -v kitty &>/dev/null; then
      kitty bash "${LAUNCHER}" &
    elif command -v xterm &>/dev/null; then
      xterm -e bash "${LAUNCHER}" &
    else
      echo "[spawn] No GUI terminal found — running child in background" >&2
      nohup bash "${LAUNCHER}" > "$LOG_FILE" 2>&1 &
      echo "$!" > "${REPO_ROOT}/.claude/child-pid-${TASK_SLUG}"
    fi
    ;;

  Windows*|MINGW*|CYGWIN*|MSYS*)
    # Convert POSIX path to Windows path for native Windows tools
    WIN_LAUNCHER="$(cygpath -w "${LAUNCHER}" 2>/dev/null || echo "${LAUNCHER}")"
    # Find bash.exe — wt.exe needs a Windows executable, not the bash alias
    BASH_EXE="$(cygpath -w "$(command -v bash)" 2>/dev/null || echo "bash.exe")"

    if command -v wt.exe &>/dev/null 2>&1; then
      # bash.exe needs POSIX path for the script arg, Windows path only for the executable
      wt.exe nt --title "${TASK_SLUG}" -- "${BASH_EXE}" "${LAUNCHER}" &
    else
      # Fallback: powershell Start-Process opens a visible new window
      powershell.exe -NonInteractive -Command \
        "Start-Process -FilePath '${BASH_EXE}' -ArgumentList '${LAUNCHER}' -WindowStyle Normal" &
    fi
    ;;

  *)
    echo "[spawn] Unknown OS '${OS_TYPE}' — running child in background" >&2
    nohup bash "${LAUNCHER}" > "$LOG_FILE" 2>&1 &
    echo "$!" > "${REPO_ROOT}/.claude/child-pid-${TASK_SLUG}"
    ;;
esac

echo "[spawn] Child launched → slug: ${TASK_SLUG} | report: ${REPORT_PATH} | log: .claude/logs/${TASK_SLUG}.log"
