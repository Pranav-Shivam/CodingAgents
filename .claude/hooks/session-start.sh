#!/usr/bin/env bash
# Runs at session start — injects git context so Claude knows current branch state

branch=$(git branch --show-current 2>/dev/null || echo "unknown")
uncommitted=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
last_commit=$(git log --oneline -1 2>/dev/null || echo "no commits")
stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

echo "[SESSION START]"
echo "Branch: $branch"
echo "Uncommitted changes: $uncommitted files"
echo "Last commit: $last_commit"
if [ "$stash_count" -gt 0 ]; then
  echo "Stashed: $stash_count entries"
fi
