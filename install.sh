#!/usr/bin/env bash
# install.sh — install CodingAgents skills, agents, commands, and rules
#
# Curl install (global, into ~/.claude):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash
#
# Curl install (project-scoped):
#   curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --project
#
# Local install (from cloned repo):
#   bash install.sh [--global | --project [target-dir]]

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
REPO="Pranav-Shivam/CodingAgents"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# Files to install: "source-path:dest-relative-to-install-root"
# dest is relative to ~/.claude (global) or <project>/.claude (project)
AGENT_FILES=(
  ".claude/agents/auth-agent.md"
  ".claude/agents/config-agent.md"
  ".claude/agents/crypto-tls-agent.md"
  ".claude/agents/data-agent.md"
  ".claude/agents/database-agent.md"
  ".claude/agents/deps-agent.md"
  ".claude/agents/emoji-agent.md"
  ".claude/agents/iac-container-agent.md"
  ".claude/agents/rbac-agent.md"
  ".claude/agents/sast-agent.md"
  ".claude/agents/secrets-agent.md"
)

COMMAND_FILES=(
  ".claude/commands/auto-terminal.md"
  ".claude/commands/git-commit.md"
  ".claude/commands/learn.md"
  ".claude/commands/pr-description.md"
  ".claude/commands/security-scan.md"
)

RULE_FILES=(
  ".claude/rules/principles.md"
  ".claude/rules/principles_v2.md"
)

SCRIPT_FILES=(
  ".claude/scripts/spawn-subagent.sh"
  ".claude/scripts/notify.sh"
)

MISC_FILES=(
  ".claude/report-template.md"
)

HOOK_FILES=(
  ".claude/hooks/pre-tool-safety.sh"
  ".claude/hooks/session-start.sh"
)

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
MODE="global"
TARGET_DIR=""

for arg in "$@"; do
  case "$arg" in
    --project) MODE="project" ;;
    --global)  MODE="global" ;;
    *)         TARGET_DIR="$arg" ;;
  esac
done

if [ "$MODE" = "global" ]; then
  INSTALL_ROOT="${HOME}/.claude"
else
  INSTALL_ROOT="${TARGET_DIR:-$(pwd)}/.claude"
fi

# ---------------------------------------------------------------------------
# Detect execution context: curl pipe vs local
# ---------------------------------------------------------------------------
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -z "$SCRIPT_PATH" ] || [ ! -f "$SCRIPT_PATH" ]; then
  # Running via curl pipe — fetch from GitHub
  USE_REMOTE=true
  LOCAL_ROOT=""
else
  USE_REMOTE=false
  LOCAL_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
install_file() {
  local src="$1"   # repo-relative path, e.g. .claude/agents/auth-agent.md
  local dest="${INSTALL_ROOT}/${src#.claude/}"

  mkdir -p "$(dirname "$dest")"

  if [ "$USE_REMOTE" = true ]; then
    curl -fsSL "${RAW_BASE}/${src}" -o "$dest"
  else
    cp "${LOCAL_ROOT}/${src}" "$dest"
  fi

  echo "  installed: $dest"
}

make_executable() {
  local src="$1"
  local dest="${INSTALL_ROOT}/${src#.claude/}"
  chmod +x "$dest"
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
echo "CodingAgents installer"
echo "  mode:   ${MODE}"
echo "  target: ${INSTALL_ROOT}"
echo ""

echo "Agents:"
for f in "${AGENT_FILES[@]}"; do install_file "$f"; done

echo ""
echo "Commands:"
for f in "${COMMAND_FILES[@]}"; do install_file "$f"; done

echo ""
echo "Rules:"
for f in "${RULE_FILES[@]}"; do install_file "$f"; done

echo ""
echo "Scripts:"
for f in "${SCRIPT_FILES[@]}"; do install_file "$f"; done
for f in "${SCRIPT_FILES[@]}"; do make_executable "$f"; done

echo ""
echo "Misc:"
for f in "${MISC_FILES[@]}"; do install_file "$f"; done

if [ "$MODE" = "project" ]; then
  echo ""
  echo "Hooks:"
  for f in "${HOOK_FILES[@]}"; do install_file "$f"; done
  for f in "${HOOK_FILES[@]}"; do make_executable "$f"; done

  # Touch runtime files
  touch "${INSTALL_ROOT}/agent-status"
  mkdir -p "${INSTALL_ROOT}/logs"

  # .gitignore entries
  PROJECT_ROOT="$(dirname "$INSTALL_ROOT")"
  GITIGNORE="${PROJECT_ROOT}/.gitignore"
  touch "$GITIGNORE"
  for entry in \
    ".claude/agent-status" \
    ".claude/logs/" \
    ".claude/fork-context.md" \
    ".claude/child-prompt-*.md" \
    ".claude/child-pid-*" \
    ".claude/launcher-*.sh"
  do
    if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
      echo "$entry" >> "$GITIGNORE"
    fi
  done
  echo "  updated: .gitignore"
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
