---
description: Extract non-obvious learnings from this session and save to docs/gotchas.md. Invoke with /learn at session end. Never auto-triggers.
allowed-tools: Read, Bash(git diff HEAD), Bash(git log --oneline -5)
model: haiku
disable-model-invocation: true
---

Capture session learnings to docs/gotchas.md. Only extract what future Claude sessions won't know from reading the code.

Steps:
1. Read `docs/gotchas.md` — know what's already captured
2. Scan this session for:
   - Non-obvious bugs discovered and why they happened
   - Tool/command quirks (flags, platform differences, version issues)
   - Agent behavior patterns that surprised you
   - Workarounds for specific constraints
   - Anything a new Claude session would get wrong without this note
3. Filter ruthlessly: skip anything derivable from the code or docs

For each lesson worth saving, write one compact entry:
```
## <topic>

- <specific, actionable fact> — <why it matters or when it bites you>
```

Output: proposed additions only. Present them. Ask user to approve before writing.

After approval: prepend entries to docs/gotchas.md under the `<!-- New entries added here by /learn -->` comment.

Rules:
- No generic best practices — only project/tool-specific observations
- No "remember to X" — only specific facts with concrete consequences
- If nothing new discovered: say "Nothing new to capture."
