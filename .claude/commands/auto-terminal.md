# /auto-terminal

Spawn a child Claude Code agent in a new terminal window to work autonomously on a separate task, keeping the current context window clean and unblocked.

## Usage

```
/auto-terminal <task description>
```

## What this command does

When invoked, Claude must execute these steps in order:

### Step 1 — Write fork-context.md

Write `.claude/fork-context.md` with a lean project snapshot. Include:

- `cwd`: current working directory (absolute path)
- `project_name`: name of the project
- `parent_task`: what the parent session is currently working on
- `parent_owns`: list of files/directories the parent is actively modifying (child must not touch these)
- `child_task`: the exact task description passed to /auto-terminal
- `relevant_paths`: file paths the child will likely need (source dirs, config files, package.json, etc.)
- `tech_stack`: languages, frameworks, key dependencies
- `conventions`: coding style, naming patterns, test conventions, commit format
- `repo_root`: absolute path to repo root

Keep it under 60 lines. Child reads this to orient itself without the full parent thread.

### Step 2 — Generate task slug

Derive a slug from the task description:
- Lowercase
- Hyphen-separated words
- Max 4 words
- Strip filler words (a, an, the, for, and, or, to)
- Example: "build frontend for frame_comp" → `frontend-frame-comp`
- Example: "add authentication middleware" → `add-auth-middleware`

### Step 3 — Spawn child agent

Run this exact command:

```bash
bash .claude/scripts/spawn-subagent.sh "<slug>" "<task description>"
```

Wait for the spawn script to confirm it launched (it prints the child PID). This takes under 2 seconds.

### Step 4 — Confirm to user

Print exactly one line:

```
Child spawned → task: <slug> | report: reports/<slug>-report.md
```

No other output. Do not describe what the child will do. Do not explain the system.

### Step 5 — Continue parent work immediately

Return to whatever the parent was working on. Do not wait, poll, or block.

### Step 6 — Periodic status check

At natural breakpoints (after completing a chunk of parent work, when user asks, or when switching topics), run:

```bash
grep "DONE:<slug>" .claude/agent-status 2>/dev/null
```

If found, notify the user:

```
Child task <slug> finished. Report at reports/<slug>-report.md
```

Do not summarize the child's work. Do not repeat its output. Just point to the report file.

## Multi-child support

If /auto-terminal is called while a child is already running:
- Generate a new slug (must differ from all existing slugs)
- Spawn second child independently with its own prompt file and log
- Each child writes to its own `reports/<slug>-report.md`
- `.claude/agent-status` is append-only — each `DONE:<slug>` line is independent
- Check each slug separately

## File ownership

Parent declares ownership of files in `parent_owns` field of fork-context.md. Child must never write to those paths. If child needs output from those files, it reads but does not modify.

## Rules

- Never summarize child output in the parent thread
- Never block parent work waiting for child
- Report path is always `reports/<slug>-report.md` — never `reports/<slug>.md`
- slug must be unique per session; prefix with a counter if collision (e.g. `auth-middleware-2`)
