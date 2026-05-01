# Code Review Criteria

Used by automated PR review (`.github/workflows/claude-review.yml`) and the `/review` skill.

## What to flag

### Agent and skill definitions
- Vague runbook steps with no concrete bash commands → flag as HIGH (agent will produce inconsistent results)
- Security agent tool list includes `Write` or `Edit` → flag as CRITICAL (audit agents must be read-only)
- Agent `model` field uses hardcoded model ID (`claude-sonnet-4-6`) instead of alias (`sonnet`) → flag as LOW
- Agent missing `permissionMode: plan` → flag as MEDIUM
- Agent missing `maxTurns` → flag as LOW (cost control)
- Orchestrator agent gives subagents unbounded tool access → flag as HIGH

### CLAUDE.md and rules
- CLAUDE.md exceeds 50 lines of actual instruction content → flag as MEDIUM
- Inline content that belongs in `docs/` instead → flag as LOW
- Contradictory instructions between CLAUDE.md and `rules/` files → flag as HIGH

### settings.json
- `autoCompactPercentageOverride` removed or set above 85 → flag as MEDIUM
- `MAX_THINKING_TOKENS` removed or set above 20000 → flag as MEDIUM (cost risk)
- Hook script paths changed without updating hook scripts → flag as HIGH

### Documentation
- Architecture change in agents or commands with no update to `docs/architecture.md` → flag as LOW
- New gotcha discovered (non-obvious bug/workaround) not captured in `docs/gotchas.md` → flag as LOW

### CI/CD
- `ANTHROPIC_API_KEY` referenced inline instead of via secrets → flag as CRITICAL
- `fetch-depth: 0` removed from checkout step → flag as HIGH (Claude will review single commit not full PR)
- `--allowedTools` removed from review run → flag as HIGH (Claude could push changes to PR being reviewed)

## What NOT to flag
- Style/formatting in agent markdown body text
- Comments added for clarity
- Whitespace-only changes
- Changes to `docs/gotchas.md` or `docs/architecture.md` (informational only)
- Test or example files

## Severity scale
- **CRITICAL**: Security risk or data loss (hardcoded secrets, write access on audit agents)
- **HIGH**: Breaks functionality or defeats safety mechanisms
- **MEDIUM**: Degrades quality or increases cost without clear justification
- **LOW**: Best practice deviation, non-urgent improvement
