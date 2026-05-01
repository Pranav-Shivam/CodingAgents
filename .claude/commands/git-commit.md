---
description: Generate a conventional commit message from staged changes. Invoke with /git-commit. Never auto-triggers — always requires explicit invocation.
allowed-tools: Bash(git diff --cached), Bash(git diff), Bash(git status), Bash(git log --oneline -10)
model: haiku
disable-model-invocation: true
---

Generate a commit message for staged changes. Conventional Commits format.

Steps:
1. Run `git diff --cached` — read staged diff fully
2. Run `git log --oneline -10` — match repo's existing commit style
3. Write commit message:
   - Subject: `<type>(<scope>): <what changed>` — max 50 chars
   - Types: feat, fix, docs, refactor, test, chore, security
   - Body: only when WHY is non-obvious (workaround, constraint, incident cause)
   - No co-author lines unless asked

Output: the commit message only. No explanation. No preamble.

Rules:
- Subject describes WHAT changed, body explains WHY (if needed)
- No "this commit", no "I", no period at end of subject
- Breaking change: add `!` after type, BREAKING CHANGE footer
- If nothing staged: say "Nothing staged. Run `git add <files>` first."
