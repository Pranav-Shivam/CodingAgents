#!/usr/bin/env bash
# notify.sh — desktop notification when child agent completes
# Usage: bash .claude/scripts/notify.sh "<slug>"

TASK_SLUG="${1:?slug required}"
REPORT_PATH="reports/${TASK_SLUG}-report.md"
MSG="Task ${TASK_SLUG} complete — report at ${REPORT_PATH}"
TITLE="Claude Code / auto-terminal"

OS_TYPE="$(uname -s 2>/dev/null || echo "Windows")"

case "$OS_TYPE" in
  Darwin)
    osascript -e "display notification \"${MSG}\" with title \"${TITLE}\" sound name \"Glass\"" 2>/dev/null || true
    ;;

  Linux)
    if command -v notify-send &>/dev/null; then
      notify-send "${TITLE}" "${MSG}" 2>/dev/null || true
    else
      # stdout banner fallback
      echo ""
      echo "======================================================"
      echo "  ${TITLE}"
      echo "  ${MSG}"
      echo "======================================================"
      echo ""
    fi
    ;;

  Windows*|MINGW*|CYGWIN*|MSYS*)
    powershell.exe -NonInteractive -Command "
      Add-Type -AssemblyName System.Windows.Forms
      \$n = New-Object System.Windows.Forms.NotifyIcon
      \$n.Icon = [System.Drawing.SystemIcons]::Information
      \$n.BalloonTipTitle = '${TITLE}'
      \$n.BalloonTipText = '${MSG}'
      \$n.Visible = \$true
      \$n.ShowBalloonTip(5000)
      Start-Sleep -Seconds 6
      \$n.Dispose()
    " 2>/dev/null || echo "[notify] ${MSG}"
    ;;

  *)
    echo "[notify] ${MSG}"
    ;;
esac
