#!/usr/bin/env bash
# install.sh — install or uninstall CodingAgents skills, agents, commands, rules, and docs
#
# Install (global, into ~/.claude):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash
#
# Install (project-scoped, run from inside your project):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --project
#
# Uninstall (global):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --uninstall
#
# Uninstall (project-scoped):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --uninstall --project
#
# Local install/uninstall (from cloned repo):
#   bash install.sh [--global | --project] [--uninstall] [target-dir]

set -euo pipefail

REPO="Pranav-Shivam/CodingAgents"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
MODE="global"
ACTION="install"
PROJECT_ROOT=""

for arg in "$@"; do
  case "$arg" in
    --project)   MODE="project" ;;
    --global)    MODE="global" ;;
    --uninstall) ACTION="uninstall" ;;
    --remove)    ACTION="uninstall" ;;
    *)           PROJECT_ROOT="$arg" ;;
  esac
done

if [ "$MODE" = "global" ]; then
  CLAUDE_DIR="${HOME}/.claude"
  PROJECT_ROOT="${HOME}"
else
  PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
  CLAUDE_DIR="${PROJECT_ROOT}/.claude"
fi

# ---------------------------------------------------------------------------
# Detect execution context: curl pipe vs local
# ---------------------------------------------------------------------------
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -z "$SCRIPT_PATH" ] || [ ! -f "$SCRIPT_PATH" ]; then
  USE_REMOTE=true
  LOCAL_ROOT=""
else
  USE_REMOTE=false
  LOCAL_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

# ---------------------------------------------------------------------------
# File lists
# ---------------------------------------------------------------------------
AGENT_FILES=(
  .claude/agents/auth-agent.md
  .claude/agents/config-agent.md
  .claude/agents/crypto-tls-agent.md
  .claude/agents/data-agent.md
  .claude/agents/database-agent.md
  .claude/agents/deps-agent.md
  .claude/agents/emoji-agent.md
  .claude/agents/iac-container-agent.md
  .claude/agents/rbac-agent.md
  .claude/agents/sast-agent.md
  .claude/agents/secrets-agent.md
)

COMMAND_FILES=(
  .claude/commands/auto-terminal.md
  .claude/commands/git-commit.md
  .claude/commands/learn.md
  .claude/commands/pr-description.md
  .claude/commands/security-scan.md
)

RULE_FILES=(
  .claude/rules/principles.md
  .claude/rules/principles_v2.md
)

SCRIPT_FILES=(
  .claude/scripts/spawn-subagent.sh
  .claude/scripts/notify.sh
)

HOOK_FILES=(
  .claude/hooks/pre-tool-safety.sh
  .claude/hooks/session-start.sh
)

GITIGNORE_ENTRIES=(
  ".claude/agent-status"
  ".claude/logs/"
  ".claude/fork-context.md"
  ".claude/child-prompt-*.md"
  ".claude/child-pid-*"
  ".claude/launcher-*.sh"
  ".claude/settings.example.json"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
fetch_raw() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ "$USE_REMOTE" = true ]; then
    curl -fsSL "${RAW_BASE}/${src}" -o "$dest"
  else
    cp "${LOCAL_ROOT}/${src}" "$dest"
  fi
  echo "  installed: $dest"
}

install_claude_file() {
  fetch_raw "$1" "${CLAUDE_DIR}/${1#.claude/}"
}

make_executable() {
  chmod +x "${CLAUDE_DIR}/${1#.claude/}"
}

remove_file() {
  local f="$1"
  if [ -f "$f" ]; then
    rm -f "$f"
    echo "  removed: $f"
  fi
}

remove_dir_if_empty() {
  local d="$1"
  if [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
    rmdir "$d"
    echo "  removed (empty): $d"
  fi
}

# ---------------------------------------------------------------------------
# UNINSTALL
# ---------------------------------------------------------------------------
if [ "$ACTION" = "uninstall" ]; then
  echo "CodingAgents uninstaller"
  echo "  mode:        ${MODE}"
  echo "  claude dir:  ${CLAUDE_DIR}"
  echo "  project:     ${PROJECT_ROOT}"
  echo ""

  echo "Agents:"
  for f in "${AGENT_FILES[@]}"; do remove_file "${CLAUDE_DIR}/${f#.claude/}"; done
  remove_dir_if_empty "${CLAUDE_DIR}/agents"

  echo ""
  echo "Commands:"
  for f in "${COMMAND_FILES[@]}"; do remove_file "${CLAUDE_DIR}/${f#.claude/}"; done
  remove_dir_if_empty "${CLAUDE_DIR}/commands"

  echo ""
  echo "Rules:"
  for f in "${RULE_FILES[@]}"; do remove_file "${CLAUDE_DIR}/${f#.claude/}"; done
  remove_dir_if_empty "${CLAUDE_DIR}/rules"

  echo ""
  echo "Scripts:"
  for f in "${SCRIPT_FILES[@]}"; do remove_file "${CLAUDE_DIR}/${f#.claude/}"; done
  remove_dir_if_empty "${CLAUDE_DIR}/scripts"

  echo ""
  echo "Misc:"
  remove_file "${CLAUDE_DIR}/report-template.md"

  if [ "$MODE" = "project" ]; then
    echo ""
    echo "Hooks:"
    for f in "${HOOK_FILES[@]}"; do remove_file "${CLAUDE_DIR}/${f#.claude/}"; done
    remove_dir_if_empty "${CLAUDE_DIR}/hooks"

    echo ""
    echo "Runtime files:"
    remove_file "${CLAUDE_DIR}/agent-status"
    remove_file "${CLAUDE_DIR}/settings.example.json"
    if [ -d "${CLAUDE_DIR}/logs" ] && [ -z "$(ls -A "${CLAUDE_DIR}/logs" 2>/dev/null)" ]; then
      rmdir "${CLAUDE_DIR}/logs"
      echo "  removed (empty): ${CLAUDE_DIR}/logs"
    fi

    echo ""
    echo "Settings:"
    remove_file "${CLAUDE_DIR}/settings.json"

    echo ""
    echo "Docs:"
    remove_file "${PROJECT_ROOT}/docs/gotchas.md"
    remove_file "${PROJECT_ROOT}/docs/architecture.md"
    remove_dir_if_empty "${PROJECT_ROOT}/docs/research"
    remove_dir_if_empty "${PROJECT_ROOT}/docs"

    echo ""
    echo "Reports directory:"
    if [ -d "${PROJECT_ROOT}/reports" ] && [ -z "$(ls -A "${PROJECT_ROOT}/reports" 2>/dev/null)" ]; then
      rmdir "${PROJECT_ROOT}/reports"
      echo "  removed (empty): ${PROJECT_ROOT}/reports"
    else
      echo "  skipped: ${PROJECT_ROOT}/reports — not empty, remove manually if desired"
    fi

    echo ""
    echo "CLAUDE.md:"
    echo "  skipped: CLAUDE.md not removed — may contain your own content. Remove manually if needed."

    echo ""
    echo ".gitignore:"
    GITIGNORE="${PROJECT_ROOT}/.gitignore"
    if [ -f "$GITIGNORE" ]; then
      for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
          grep -vF "$entry" "$GITIGNORE" > "${GITIGNORE}.tmp" && mv "${GITIGNORE}.tmp" "$GITIGNORE"
          echo "  removed: $entry"
        fi
      done
    fi
  fi

  echo ""
  echo "Uninstall complete. Restart Claude Code."
  exit 0
fi

# ---------------------------------------------------------------------------
# INSTALL
# ---------------------------------------------------------------------------
echo "CodingAgents installer"
echo "  mode:        ${MODE}"
echo "  claude dir:  ${CLAUDE_DIR}"
echo "  project:     ${PROJECT_ROOT}"
echo ""

echo "Agents:"
for f in "${AGENT_FILES[@]}"; do install_claude_file "$f"; done

echo ""
echo "Commands:"
for f in "${COMMAND_FILES[@]}"; do install_claude_file "$f"; done

echo ""
echo "Rules:"
for f in "${RULE_FILES[@]}"; do install_claude_file "$f"; done

echo ""
echo "Scripts:"
for f in "${SCRIPT_FILES[@]}"; do install_claude_file "$f"; done
make_executable .claude/scripts/spawn-subagent.sh
make_executable .claude/scripts/notify.sh

echo ""
echo "Misc:"
install_claude_file .claude/report-template.md

if [ "$MODE" = "project" ]; then

  echo ""
  echo "Hooks:"
  for f in "${HOOK_FILES[@]}"; do install_claude_file "$f"; done
  make_executable .claude/hooks/pre-tool-safety.sh
  make_executable .claude/hooks/session-start.sh

  echo ""
  echo "Docs:"
  fetch_raw "docs/gotchas.md"      "${PROJECT_ROOT}/docs/gotchas.md"
  fetch_raw "docs/architecture.md" "${PROJECT_ROOT}/docs/architecture.md"
  mkdir -p "${PROJECT_ROOT}/docs/research"
  echo "  created: ${PROJECT_ROOT}/docs/research/"

  echo ""
  echo "Reports directory:"
  mkdir -p "${PROJECT_ROOT}/reports"
  echo "  created: ${PROJECT_ROOT}/reports/"

  echo ""
  echo "Settings:"
  SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
  if [ -f "$SETTINGS_FILE" ]; then
    fetch_raw ".claude/settings.json" "${CLAUDE_DIR}/settings.example.json"
    echo "  skipped: settings.json already exists — reference copy saved as settings.example.json"
  else
    fetch_raw ".claude/settings.json" "$SETTINGS_FILE"
  fi

  echo ""
  echo "CLAUDE.md:"
  CLAUDE_MD="${PROJECT_ROOT}/CLAUDE.md"
  if [ -f "$CLAUDE_MD" ]; then
    if grep -q "## auto-terminal" "$CLAUDE_MD" 2>/dev/null; then
      echo "  skipped: CLAUDE.md already contains auto-terminal section"
    else
      if [ "$USE_REMOTE" = true ]; then
        curl -fsSL "${RAW_BASE}/CLAUDE.template.md" | tail -n +3 >> "$CLAUDE_MD"
      else
        tail -n +3 "${LOCAL_ROOT}/CLAUDE.template.md" >> "$CLAUDE_MD"
      fi
      echo "  merged:  ${CLAUDE_MD}"
    fi
  else
    mkdir -p "$(dirname "$CLAUDE_MD")"
    if [ "$USE_REMOTE" = true ]; then
      curl -fsSL "${RAW_BASE}/CLAUDE.template.md" -o "$CLAUDE_MD"
    else
      cp "${LOCAL_ROOT}/CLAUDE.template.md" "$CLAUDE_MD"
    fi
    echo "  created: ${CLAUDE_MD}"
  fi

  echo ""
  echo "Runtime files:"
  touch "${CLAUDE_DIR}/agent-status"
  mkdir -p "${CLAUDE_DIR}/logs"
  echo "  created: .claude/agent-status, .claude/logs/"

  echo ""
  echo ".gitignore:"
  GITIGNORE="${PROJECT_ROOT}/.gitignore"
  touch "$GITIGNORE"
  for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
      echo "$entry" >> "$GITIGNORE"
      echo "  added: $entry"
    fi
  done

fi

echo ""
echo "Done. Restart Claude Code to pick up new agents and commands."
echo ""
echo "Available commands:"
echo "  /security-scan    — run 10 parallel security subagents"
echo "  /auto-terminal    — spawn autonomous child agent in new terminal"
echo "  /git-commit       — structured commit workflow"
echo "  /pr-description   — generate PR description"
echo "  /learn            — capture lessons to gotchas.md"
echo ""
echo "To uninstall:"
echo "  curl -fsSL ${RAW_BASE}/install.sh | bash -s -- --uninstall --project"
