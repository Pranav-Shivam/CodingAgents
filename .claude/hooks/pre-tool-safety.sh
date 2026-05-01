#!/usr/bin/env bash
# Runs before every Bash tool call — blocks destructive commands

command=$(jq -r '.tool_input.command // ""' 2>/dev/null)

# Block patterns — irreversible or high blast-radius operations
if echo "$command" | grep -qE "(rm -rf|git push --force|git push -f\b|DROP TABLE|DROP DATABASE|git reset --hard|truncate -s 0|> \.env|>> \.env)"; then
  echo "BLOCKED: Dangerous command detected."
  echo "Command: $command"
  echo "If intentional, run it manually in the terminal."
  exit 1
fi

exit 0
