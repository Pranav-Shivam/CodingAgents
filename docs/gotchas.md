# Gotchas

Hard-won lessons from real sessions. Grows via `/learn`. Most recent first.

---

<!-- New entries added here by /learn -->

## Agent design

- Agent descriptions must be surgical — name exact mechanisms AND trigger conditions. Vague descriptions cause Claude's invocation engine to miss. "Audits JWT" fires correctly. "Security stuff" does not.
- Agent tools: never give Write to an audit/read-only agent. If it can't write, it can't accidentally break something while scanning.
- Runbook steps with actual bash commands outperform guideline-style instructions. Claude runs the command, reads output, reports finding — no interpretation gap.

## Security scan

- `grep -rn --include="*.py"` works on Linux/Mac. On Windows, use `grep -rn` without `--include` or use `findstr`. The security agents assume Unix-style grep.
- `semgrep` and `bandit` must be installed in the target project's Python environment, not globally. Check with `which semgrep` / `which bandit` before running security-scan.
- `trufflehog filesystem .` scans current directory. Pass `--no-update` to skip version checks in CI.
- `detect-secrets scan` requires a baseline file (`detect-secrets scan > .secrets.baseline`). First run will flag everything — establish baseline, then diff future runs.

## Claude Code behavior

- CLAUDE.md under 50 lines. Bloat degrades instruction-following — Claude has ~150 reliable instruction slots total, system prompt consumes ~50 of them.
- MCP servers load full tool schema on every message even when idle. Disconnect unused servers.
- `/clear` between unrelated tasks. Cost of message N = cost of re-reading all N-1 prior messages. Long sessions compound invisibly.
- Edit/retry (not correction messages) when Claude misunderstands. Wrong response + correction + new response stay in context forever.
