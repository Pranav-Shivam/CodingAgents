---
description: Generate a pull request description from branch changes vs main. Invoke with /pr-description. Never auto-triggers.
allowed-tools: Bash(git diff main...HEAD), Bash(git log main..HEAD --oneline), Bash(git log main..HEAD --format="%s%n%b"), Bash(git status)
model: sonnet
disable-model-invocation: true
---

Generate a PR description from all commits on this branch vs main.

Steps:
1. `git log main..HEAD --oneline` — list all commits on branch
2. `git diff main...HEAD` — read full diff
3. Write PR description in this format:

```
## Summary
- <bullet: what changed and why>
- <bullet: second change if distinct>
- <bullet: third change if needed>

## Changes
<Brief technical description — architecture decisions, non-obvious choices>

## Test plan
- [ ] <specific thing to verify>
- [ ] <edge case to test>
- [ ] <regression to check>
```

Rules:
- Title (output separately): under 70 chars, imperative mood ("Add X", not "Added X")
- Summary bullets: WHAT changed and WHY, not HOW
- Test plan: concrete and specific, not generic ("test it works")
- If branch has no commits ahead of main: say so
- No filler phrases, no "I implemented", no hedging
