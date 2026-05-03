#!/usr/bin/env bash
# install.sh — install CodingAgents skills, agents, commands, rules, and docs
#
# Curl install (global, into ~/.claude — agents/commands available in all projects):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash
#
# Curl install (project-scoped — run from inside your project):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --project
#
# Local install (from cloned repo):
#   bash install.sh [--global | --project [target-dir]]

set -euo pipefail

REPO="Pranav-Shivam/CodingAgents"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
MODE="global"
PROJECT_ROOT=""

for arg in "$@"; do
  case "$arg" in
    --project) MODE="project" ;;
    --global)  MODE="global" ;;
    *)         PROJECT_ROOT="$arg" ;;
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
# Helpers
# ---------------------------------------------------------------------------

# fetch_raw: download or copy a repo-relative file, write to $dest
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

# install_claude_file: maps .claude/X → $CLAUDE_DIR/X
install_claude_file() {
  local src="$1"
  fetch_raw "$src" "${CLAUDE_DIR}/${src#.claude/}"
}

make_executable() {
  chmod +x "${CLAUDE_DIR}/${1#.claude/}"
}

# ---------------------------------------------------------------------------
# Install agents, commands, rules, scripts, misc
# ---------------------------------------------------------------------------
echo "CodingAgents installer"
echo "  mode:        ${MODE}"
echo "  claude dir:  ${CLAUDE_DIR}"
echo "  project:     ${PROJECT_ROOT}"
echo ""

echo "Agents:"
for f in \
  .claude/agents/auth-agent.md \
  .claude/agents/config-agent.md \
  .claude/agents/crypto-tls-agent.md \
  .claude/agents/data-agent.md \
  .claude/agents/database-agent.md \
  .claude/agents/deps-agent.md \
  .claude/agents/emoji-agent.md \
  .claude/agents/iac-container-agent.md \
  .claude/agents/rbac-agent.md \
  .claude/agents/sast-agent.md \
  .claude/agents/secrets-agent.md
do install_claude_file "$f"; done

echo ""
echo "Commands:"
for f in \
  .claude/commands/auto-terminal.md \
  .claude/commands/git-commit.md \
  .claude/commands/learn.md \
  .claude/commands/pr-description.md \
  .claude/commands/security-scan.md
do install_claude_file "$f"; done

echo ""
echo "Rules:"
for f in \
  .claude/rules/principles.md \
  .claude/rules/principles_v2.md
do install_claude_file "$f"; done

echo ""
echo "Scripts:"
for f in \
  .claude/scripts/spawn-subagent.sh \
  .claude/scripts/notify.sh
do install_claude_file "$f"; done
make_executable .claude/scripts/spawn-subagent.sh
make_executable .claude/scripts/notify.sh

echo ""
echo "Misc:"
install_claude_file .claude/report-template.md

# ---------------------------------------------------------------------------
# Project-mode extras: hooks, CLAUDE.md, docs, settings, reports, .gitignore
# ---------------------------------------------------------------------------
if [ "$MODE" = "project" ]; then

  echo ""
  echo "Hooks:"
  for f in \
    .claude/hooks/pre-tool-safety.sh \
    .claude/hooks/session-start.sh
  do install_claude_file "$f"; done
  make_executable .claude/hooks/pre-tool-safety.sh
  make_executable .claude/hooks/session-start.sh

  echo ""
  echo "Docs:"
  fetch_raw "docs/gotchas.md"    "${PROJECT_ROOT}/docs/gotchas.md"
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
    echo "  skipped: ${SETTINGS_FILE} already exists — review .claude/settings.example.json for reference"
    fetch_raw ".claude/settings.json" "${CLAUDE_DIR}/settings.example.json"
  else
    fetch_raw ".claude/settings.json" "$SETTINGS_FILE"
    echo "  installed: ${SETTINGS_FILE}"
  fi

  echo ""
  echo "CLAUDE.md:"
  CLAUDE_MD="${PROJECT_ROOT}/CLAUDE.md"
  if [ -f "$CLAUDE_MD" ]; then
    if grep -q "## auto-terminal" "$CLAUDE_MD" 2>/dev/null; then
      echo "  skipped: CLAUDE.md already contains auto-terminal section"
    else
      # Append template content (skip the # CLAUDE.md header line)
      if [ "$USE_REMOTE" = true ]; then
        curl -fsSL "${RAW_BASE}/CLAUDE.template.md" | tail -n +3 >> "$CLAUDE_MD"
      else
        tail -n +3 "${LOCAL_ROOT}/CLAUDE.template.md" >> "$CLAUDE_MD"
      fi
      echo "  merged:  ${CLAUDE_MD}"
    fi
  else
    fetch_raw "CLAUDE.template.md" "$CLAUDE_MD"
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
  for entry in \
    ".claude/agent-status" \
    ".claude/logs/" \
    ".claude/fork-context.md" \
    ".claude/child-prompt-*.md" \
    ".claude/child-pid-*" \
    ".claude/launcher-*.sh" \
    ".claude/settings.example.json"
  do
    if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
      echo "$entry" >> "$GITIGNORE"
      echo "  added: $entry"
    fi
  done

fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "Done. Restart Claude Code to pick up new agents and commands."
echo ""
echo "Available commands:"
echo "  /security-scan    — run 10 parallel security subagents"
echo "  /auto-terminal    — spawn autonomous child agent in new terminal"
echo "  /git-commit       — structured commit workflow"
echo "  /pr-description   — generate PR description"
echo "  /learn            — capture lessons to gotchas.md"
