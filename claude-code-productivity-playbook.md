# How to 10x Your Productivity With Claude Code: A Practical Playbook

![alt text](image.png)

*Part III of the Claude Code Trilogy · Deep Dive · AI Engineering · Developer Tools*

---

It's Monday morning. 8:57am.

You haven't opened your laptop yet.

But something already happened while you slept.

At 2am, Claude ran a dependency audit. Found a critical vulnerability in a JWT library your auth module depends on. Opened a GitHub issue with the CVE number, severity rating, and three lines of remediation code. At 6am, it scanned every open PR from the weekend. Two touched the login flow without updating the integration tests. It left specific comments on both — file names, line numbers, what was missing. At 8am, it pulled the week's commits, wrote an engineering summary, and posted it to Slack.

You sit down. Your terminal has a task file waiting. The three highest-priority items are already ranked.

You didn't ask for any of it. You set it up once. Three weeks ago.

**That's not a demo. That's what this article teaches you to build.**

---

Parts I and II of this trilogy covered what Claude Code is and how it thinks at the architecture level. This is the part where it becomes *yours*. Configured to your stack. Wired to your workflow. Running while you sleep.

The engineers getting 20% faster are using Claude as a tool. They prompt well, they use Plan Mode, they write decent CLAUDE.md files.

The engineers getting 10x faster built a *system*.

Here's the difference — and how to build it.

---

## The Hidden Tax Nobody Talks About First

Before we get into the system, there's something most Claude Code guides skip entirely.

**Tokens are money. And most engineers are hemorrhaging them without knowing it.**

Here's the mechanic that makes this non-obvious: every message you send re-reads the *entire conversation* from scratch. Message 30 costs 31x more than message 1 — because Claude re-processes all 30 previous messages to generate the 31st response. This isn't a bug. It's how transformer models work. And it compounds invisibly.

Now add what loads *before you type a word*: your CLAUDE.md, every connected MCP server's tool definitions, your skills, your agents. A bloated CLAUDE.md at 5,000 tokens costs 5,000 tokens on **every single message**. Every MCP server you leave connected adds its full tool schema — one idle server can burn 18,000 tokens per turn without touching a single tool.

A team of 6 engineers at Branch8 tracked this across 6 months. Month 1: **$2,400 in Claude Code costs**. After implementing the patterns in this article: **$680 in month 4**. 72% reduction, same output quality.

The Anthropic benchmark: average enterprise cost is **$13 per developer per active day**, $150–$250 per developer per month *before* optimization. If your team is above that — you're burning money on invisible architecture, not bad prompts.

### The Three Cost Drains, In Order of Impact

**1. Long sessions with no resets.** The 40th message in a session is paying for everything that came before it. Context rot is real — quality degrades as older instructions lose weight. The fix is `/clear` between unrelated tasks. Not sometimes. Every time.

**2. Model mismatch.** Haiku costs ~5x less than Sonnet, ~25x less than Opus. Sending every request to Sonnet when Haiku could handle it is like using a Formula 1 car to pick up groceries. The difference between all-Sonnet and properly-routed Haiku/Sonnet/Opus across a full session is $3–7 vs $6–8. Multiply by a team of 10, 250 working days: **$7,500–$12,500 in annual difference from model routing alone.**

**3. MCP server bloat.** Every connected server loads its full tool schema into context on every message — even if you never call it. Disconnect servers you're not actively using. Run `/mcp` at session start, audit what's loaded.

### The Real Model Decision Chart

| Task | Right Model | Wrong Model | Why |
|---|---|---|---|
| Commit message | Haiku | Sonnet | Pattern matching, not reasoning |
| Lint check | Haiku | Opus | Tool call, not thinking |
| Refactor 10 files | Sonnet | Haiku | Real implementation work |
| Auth security audit | Sonnet | Haiku | Domain expertise needed |
| Architecture decision | Opus | Sonnet | Genuine reasoning depth required |
| PR description | Sonnet | Opus | Communication task, not frontier reasoning |

### The Caveman Problem — and the Engineer Who Fixed It Absurdly Well

Here's a thing nobody warned you about when you started using Claude Code.

Claude is extremely polite.

You ask it why your React component is re-rendering. It says: *"The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every time, which triggers a re-render. I'd recommend using useMemo to memoize the object."*

That answer is 69 tokens. Every single word is correct. And about 50 of those tokens are Claude being nice to you.

You didn't need the preamble. You didn't need "I'd recommend." You needed: *"Inline prop = new ref = re-render. Wrap in useMemo."* — 19 tokens. Same fix.

Julius Brussee noticed this. Then he did something beautifully unhinged: he built a Claude Code skill that makes Claude talk like a caveman.

The repo is called [**Caveman**](https://github.com/JuliusBrussee/caveman). The tagline is *"why use many token when few token do trick."* It has **44,300 GitHub stars**. It was not a joke. It worked.

Here's the actual benchmark data from real Claude API calls:

| Task | Normal (tokens) | Caveman (tokens) | Saved |
|---|---|---|---|
| Explain React re-render bug | 1,180 | 159 | **87%** |
| Fix auth middleware token expiry | 704 | 121 | **83%** |
| Set up PostgreSQL connection pool | 2,347 | 380 | **84%** |
| Debug PostgreSQL race condition | 1,200 | 232 | **81%** |
| Implement React error boundary | 3,454 | 456 | **87%** |
| **Average across all tasks** | **1,214** | **294** | **65%** |

A March 2026 research paper backed up the intuition: constraining large models to brief responses actually *improved accuracy by 26 percentage points* on certain benchmarks. Verbose is not always smarter. Sometimes fewer words means more correct.

```
┌─────────────────────────────────────┐
│  TOKENS SAVED          ████████ 75% │
│  TECHNICAL ACCURACY    ████████ 100%│
│  RESPONSE SPEED        ████████ ~3x │
│  GITHUB STARS          ████████ 44k │
└─────────────────────────────────────┘
```

**Three intensity levels — pick your grunt:**

- `/caveman lite` — drops filler, keeps grammar. Professional but no fluff.
- `/caveman full` — default caveman. No articles, sentence fragments, full grunt.
- `/caveman ultra` — maximum compression. Telegraphic. Abbreviate everything.

There's even a 文言文 (classical Chinese literary) mode. Because why not.

**Install in one command:**

```bash
claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman
```

**The killer feature: `caveman-compress`**

Your CLAUDE.md loads on *every single session start*. `caveman-compress` rewrites your memory files into terse caveman-speak so Claude reads less context every time — without you losing the human-readable original:

```bash
/caveman:compress CLAUDE.md
```

```
CLAUDE.md           ← compressed (Claude reads this — fewer tokens every session)
CLAUDE.original.md  ← human-readable backup (you read and edit this)
```

Real numbers on memory file compression:

| File | Original | Compressed | Saved |
|---|---|---|---|
| Project notes | 1,145 tokens | 535 tokens | **53%** |
| Claude preferences | 706 tokens | 285 tokens | **60%** |
| Todo list | 627 tokens | 388 tokens | **38%** |
| **Average** | **898** | **481** | **46%** |

46% off your baseline — on every message, every session, forever. Code blocks, commands, file paths — all pass through untouched. Only prose gets compressed.

> *"Caveman no make brain smaller. Caveman make mouth smaller."*

### Practical Budget Config

Add this to `.claude/settings.json` — two lines that pay for themselves immediately:

```json
{
  "autoCompactPercentageOverride": 75,
  "env": {
    "MAX_THINKING_TOKENS": "8000"
  }
}
```

Auto-compact fires at 75% instead of the default 92% — you stop getting degraded responses in the "dumb zone" before compaction triggers. `MAX_THINKING_TOKENS: 8000` caps extended thinking, which bills as output tokens and can silently burn tens of thousands per request on complex tasks.

Track with `/cost` in-session, `/usage` for quota visibility. Set billing alerts on your Anthropic console. Don't wait for the monthly bill to find out you had a runaway agent loop at 3am.

> *"The biggest Claude Code cost drain isn't your prompt engineering. It's your workflow design."*

---

## Part One: Your Project's Brain — CLAUDE.md Done Right

Most engineers treat CLAUDE.md like a README. Stack overview, some commands, a few coding conventions. Written on day one, never touched again.

That's why they're getting 20%.

CLAUDE.md is not documentation. It's an onboarding doc for a new team member who joins fresh *every single session*. No memory of yesterday. No recollection of the three-hour debugging session last Tuesday. No awareness that you just refactored the entire auth module. Every conversation, Claude starts from zero.

CLAUDE.md is the only bridge between the Claude who knows nothing about your project and the Claude who codes like a senior engineer on your team.

Get it right and every session starts sharp. Get it wrong and you're re-explaining the same context forever — while paying for every repeated token.

### The 50-Line Rule

Here's the math. Claude Code's own system prompt consumes roughly 50 of the 150–200 instructions Claude can reliably follow before instruction-following degrades. Your CLAUDE.md loads *on top of* that, before you type a single word. A 2,000-line CLAUDE.md isn't thorough — it's self-defeating.

HumanLayer, one of the most technically rigorous Claude Code teams writing publicly, keeps their CLAUDE.md **under 60 lines**. That's not minimalism as a philosophy. That's the math working correctly.

**The rule: CLAUDE.md under 50 lines of actual instruction.** Everything else lives in `docs/`, loaded on demand.

### What Goes In, What Stays Out

**What goes in:**

```markdown
# Project Overview
Enterprise data platform — FastAPI backend, React frontend,
Snowflake data layer. Python 3.11, TypeScript strict mode.

## Commands
make dev        # start all services
make test       # full test suite
make lint       # oxlint + mypy + typecheck

## Architecture
- /services/    — FastAPI microservices, one per domain
- /frontend/    — React + Zustand, component-per-feature
- /pipelines/   — Databricks ingestion jobs

## Non-Negotiables
- SHA-256 VARCHAR(32) for all IDs, no exceptions
- TIMESTAMP_NTZ for all audit columns
- No raw SQL outside /services/db/
- No credentials in code — use env vars

## Further Reading
IMPORTANT: Before starting any task, read relevant
docs below first. Do not skip this.

- docs/gotchas.md         — hard-won lessons, non-obvious bugs
- docs/architecture.md    — data flow, system design
- docs/auth-patterns.md   — login flow, session management
- docs/testing-guide.md   — which test type, when
```

45 lines. Done.

**What stays out:**

Anything a tool can enforce. Replace 200 lines of style rules with one line:

```
Run make lint after code changes.
```

Claude runs the linter, reads the output, fixes itself. You never type "you forgot the import" again.

> Vercel's own agent evaluations found that explicit doc pointers in CLAUDE.md outperform skills for reliable context loading — skills were **not invoked in 56% of test cases**. Write the pointer. Trust the pointer.

### The Two Layers Beneath CLAUDE.md

Most engineers stop at the 50-line file. The engineers building compounding systems add two more layers.

**Layer 1 — The `rules/` Directory**

Split global instructions into focused files instead of one flat document:

```
~/.claude/
├── CLAUDE.md              # 5 lines: points to rules/
└── rules/
    ├── principles_v2.md   # engineering philosophy
    ├── git-conventions.md # commit and branch standards
    └── security-rules.md  # auth patterns, data handling
```

This is the structure from my public repo at [github.com/Pranav-Shivam/CodingAgents](https://github.com/Pranav-Shivam/CodingAgents). Each file is focused. Claude loads what matters. Nothing competes for attention.

**Layer 2 — The Behavioural Contract**

Most CLAUDE.md files tell Claude *what* your stack is. My [`principles_v2.md`](https://github.com/Pranav-Shivam/CodingAgents/blob/master/.claude/rules/principles_v2.md) tells Claude *how your team thinks*.

The difference: a Claude that knows you use FastAPI vs a Claude that knows your team's engineering philosophy are not the same Claude.

Three principles from that file that change day-to-day output immediately:

**Clarify Before You Build**

> *"An assumption you didn't state is a defect you haven't found yet."*

Claude's default is to pick silently and proceed when it hits ambiguity. This principle overrides that. The "wait, that's not what I meant" moments drop to near zero.

**Outcome-Oriented Execution**

```
"Fix the login bug"        →  Write a test that reproduces it. Then make it pass.
"Add input validation"     →  Write tests for invalid inputs. Then make them pass.
"Refactor the auth module" →  Tests pass before and after. Zero behaviour change.
```

You stop describing steps. You define what *done* looks like. Claude loops autonomously until verified.

**Known Failure Modes**

The file explicitly names the ways Claude fails in long sessions:

- **Session Memory Decay** — Claude re-introduces code you already removed
- **Phantom API Usage** — Claude calls functions that don't exist in your codebase
- **Pushback Capitulation** — Claude abandons correct solutions when you express doubt
- **Scope Creep** — Claude adds unrequested "improvements" that break things downstream

Most engineers discover these by losing a full afternoon to one of them. You can name them in a rules file and watch them disappear.

### The `/learn` Pattern — Compounding Over Time

Every session, Claude will encounter something genuinely new to your project. A non-obvious Snowflake quirk. A gotcha in your auth middleware. The instinct is to add it to CLAUDE.md.

*Resist.* CLAUDE.md stays lean.

Instead, build a `/learn` skill. At the end of any session where Claude hit something unexpected, run `/learn`. It analyzes the session, extracts the lesson, saves it to `docs/`. The `IMPORTANT:` pointer in CLAUDE.md loads that file at the start of the next relevant session.

```
docs/
├── gotchas.md          # grows every session
├── auth-patterns.md    # login, session, token gotchas
├── testing-guide.md    # your conventions, not generic ones
└── architecture.md     # updated as the system evolves
```

Week 1: CLAUDE.md tells Claude your stack.
Month 3: `docs/` tells Claude everything your stack has ever done wrong.

> *"A bad CLAUDE.md is worse than no CLAUDE.md. Contradictions confuse Claude more than silence ever could."*

---

## Part Two: Skills — Stop Doing the Same Thing Twice

Every workflow you repeat more than three times should be a skill.

I'll be direct: when I first started with Claude Code, my skill library was empty. I was re-typing the same instructions, re-explaining the same conventions, re-running the same workflows manually — session after session. Every repeated prompt was both a time cost and a token cost.

Skills are the fix. A skill is a folder with a `SKILL.md` file. Frontmatter at the top as a control panel, body as the instruction set. Drop it in `.claude/skills/`, and it's live.

### The 5 Questions Every Skill Forces You to Answer

**1. Is this dangerous enough that only I should run it?**

```yaml
disable-model-invocation: true
```

Deploy scripts. Commit workflows. Database migrations. Anything where Claude auto-triggering would be catastrophic. With this flag, the skill only runs when you type `/skill-name`. It is a hard, unforgeable guarantee encoded in the file.

> *"A skill with `disable-model-invocation: true` is a promise to yourself. Claude will never push your code without you in the loop."*

**2. Will this pollute my main context window?**

```yaml
context: fork
agent: Explore
```

Security audits. Large codebase scans. Anything that requires reading 30+ files. Fork it. The skill runs in an isolated context window. Your main conversation sees the summary, not the 40,000 tokens of intermediate work.

**3. Is this simple enough for Haiku?**

```yaml
model: haiku
```

Commit message generation. Documentation updates. Naming suggestions. These are pattern-matching tasks, not reasoning tasks. Haiku handles them at ~25x lower cost than Opus and nearly identical quality.

**4. Should this only activate for certain file types?**

```yaml
paths: src/**/*.ts, src/**/*.tsx
```

A TypeScript review skill should not activate when you're editing a SQL migration. `paths` limits auto-invocation to file patterns that actually match the skill's domain.

**5. What can I pre-approve so it never interrupts me?**

```yaml
allowed-tools: Read, Grep, Glob, Bash(make test*)
```

Pre-approve tools and the skill runs end-to-end without asking permission. `Bash(make test*)` means only `make test` variants. Not arbitrary shell. Not git. Scope tightly.

### The Tools Risk Spectrum

| Risk | Tools | Pre-approve? |
|---|---|---|
| 🟢 Safe | `Read`, `Grep`, `Glob`, `LS` | Always |
| 🟡 Moderate | `Write`, `Edit`, `MultiEdit`, `WebFetch` | When skill is trusted |
| 🔴 High | `Bash` (unscoped), `Task` | Scope tightly or require approval |

### The Skill Library Every Engineering Team Needs

Six skills. Build these first:

| Skill | disable-model-invocation | context | model | When it fires |
|---|---|---|---|---|
| `git-commit` | `true` | main | haiku | You type `/git-commit` |
| `pr-description` | `true` | main | sonnet | You type `/pr-description` |
| `ts-review` | `false` | fork | haiku | Auto on `.ts` edits |
| `update-docs` | `false` | main | haiku | Auto after code changes |
| `deploy-staging` | `true` | main | sonnet | You type `/deploy-staging` |
| `security-audit` | `false` | fork | sonnet | Auto on auth/ files |

A real deploy skill — the one that can't misfire:

```markdown
---
name: deploy-staging
description: Deploy the application to staging environment
disable-model-invocation: true
allowed-tools: Bash(make test), Bash(make deploy-staging), Bash(git status)
model: sonnet
---

Deploy checklist — stop immediately if any step fails:
1. Run `git status` — abort if uncommitted changes exist
2. Run `make test` — abort if any test fails
3. Run `make deploy-staging`
4. Confirm health check passes at staging URL
5. Report deployment status and URL

Do not proceed past a failed step. Surface failures and stop.
```

The safeguard is in the skill, not in your memory. You won't forget the checklist at 5pm on a Friday. The skill won't either.

---

## Part Three: Agents — Give Claude a Personality

There's a difference between *asking* Claude to review your auth code and having a dedicated auth agent that knows every JWT CVE from the last five years, understands your exact stack, and returns structured JSON your CI pipeline can parse.

The first is a conversation. The second is a system component.

Most engineers write agents like they're writing a job description: vague mission statement, broad tool access, aspirational language about "best practices." These agents produce inconsistent results because Claude is interpreting the brief differently every time.

**The agents that work reliably are written like runbooks** — executable steps, minimal tools, structured output.

### Anatomy of a Real Agent — `auth-agent.md`

Here's a production security agent from my public repo at [github.com/Pranav-Shivam/CodingAgents](https://github.com/Pranav-Shivam/CodingAgents/blob/master/.claude/agents/auth-agent.md). Every decision has a reason.

**The frontmatter:**

```yaml
---
name: auth-agent
description: Audits every authentication mechanism — JWT, OAuth2,
  SAML, session management, API keys, OIDC, MFA — for implementation
  flaws, weak configuration, token mishandling, and bypass vectors.
  Use when the security-scan orchestrator requests auth analysis.
tools: Bash, Read, Grep, Glob
model: claude-sonnet-4-6
---
```

**Why it works — four design decisions:**

**Decision 1: The description is surgical.** It names exact auth mechanisms. It names exact vulnerability classes. And critically — it names the trigger condition. Claude's invocation engine pattern-matches on this description. Vague descriptions miss. Specific ones fire correctly.

**Decision 2: Four tools, no more.** `Bash`, `Read`, `Grep`, `Glob`. No `Write`. No `WebFetch`. An audit agent has no business writing files. If it can't write, it can't accidentally break something while auditing.

**Decision 3: The body is a runbook, not a job description.** Each of the agent's 10 scans contains an actual bash command:

```bash
# JWT decode without algorithms= → none-algorithm attack
grep -rn --include="*.py" \
  -E "jwt\.decode\(" \
  <repo_root> --exclude-dir=.git | grep -v "algorithms"
# → CRITICAL if found
```

Claude doesn't interpret "look for JWT issues." It runs this exact command, gets the output, reports the finding.

**Decision 4: Structured JSON output schema.** The agent ends with:

```json
{
  "agent": "auth",
  "severity": "CRITICAL",
  "rule_id": "jwt-algorithm-none",
  "file": "backend/auth/jwt_handler.py",
  "line": 18,
  "snippet": "jwt.decode(token, SECRET_KEY)",
  "description": "jwt.decode called without algorithms parameter...",
  "remediation": "Always specify algorithms=['HS256']..."
}
```

Your CI pipeline parses this. Your orchestrator agent aggregates it alongside output from four other specialist agents. You're processing data, not reading prose.

### The 4 Elements Every Agent Needs

| Element | What it means |
|---|---|
| **Mission** | One paragraph, one domain. If you need "various" to describe scope — it's two agents. |
| **Trigger** | When to invoke, including negative examples. 3–5 concrete `<example>` blocks in the description. |
| **Runbook** | Executable steps, not guidelines. If a new engineer could run it without interpretation, it qualifies. |
| **Output schema** | JSON, defined upfront. Prose output means nothing downstream can consume it automatically. |

### Your Domain Agent Library

```
.claude/agents/
├── auth-agent.md      # JWT, OAuth2, session security
├── db-agent.md        # schema review, query patterns, migration checks
├── api-agent.md       # rate limiting, access control, endpoint review
└── pipeline-agent.md  # ingestion jobs, data quality, schema drift
```

One per domain. Minimal tools. Structured JSON output. An orchestrator agent that runs all four in parallel and synthesizes the results.

---

## Part Four: Subagents — Your AI Development Team

Stop being the developer. Start being the product owner.

That's not a metaphor. It's a literal shift. You define what needs to happen. Claude's agent team figures out how.

Here's what most people miss about subagents: they're not just about doing more work — they're about doing it *without polluting your context window*. Every file Claude reads, every command it runs, every test output it processes — all of it lands in context and stays there, compounding the cost of every subsequent message.

A subagent does that work in its own isolated context window. Your main conversation sees the distilled result. The mess never touches you.

### The 4 Named Patterns

**Pattern 1 — The Parallel Investigator**

You need to understand a codebase before you touch it. Instead of one Claude reading sequentially for 30 minutes, spin up 3–5 Explore subagents simultaneously:

```
"Spin up parallel subagents to research this codebase.
Agent 1: map the authentication flow end to end
Agent 2: map the database schema and key query patterns
Agent 3: map the API layer — endpoints, middleware, auth guards
Each returns a structured summary. You synthesize findings."
```

Three parallel context windows. Results in minutes. Your main conversation pays only for the synthesis, not the investigation.

---

**Pattern 2 — The Spec-Driven Build**

The pattern for any significant feature or refactor. Four phases.

**Phase 1 — Research:** Parallel subagents investigate relevant codebase sections. Main agent synthesizes.

**Phase 2 — Spec:** Main agent writes `docs/feature-spec.md` — approach, checkpoints, success criteria. If implementation goes sideways, the spec is your rollback pin.

**Phase 3 — Refine:** Before implementation, Claude asks clarifying questions. Every ambiguity resolved before a line is written.

**Phase 4 — Implement:**

```
"Implement docs/feature-spec.md.
Use the task tool. Each task gets its own subagent — fresh context.
After each task: commit. Then continue.
You are the tech lead. Subagents are your developers."
```

Each subagent has a fresh context window for one task. Main agent only orchestrates. Clean commit trail. No context blowup.

---

**Pattern 3 — The Clean Room**

For any work that would consume your main context — use `context: fork` in a skill. The skill runs in complete isolation. Returns a distilled summary. Your main conversation sees 500 tokens of findings, not 50,000 tokens of working memory.

Same outcome. No mess in your living room.

---

**Pattern 4 — The Overnight Worker**

This is the Monday morning story from the opening. Scheduled tasks running on Anthropic's infrastructure while you're not at your desk:

```bash
# Nightly at 2am — dependency + auth vulnerability audit
claude trigger create \
  --schedule "0 2 * * *" \
  --prompt "Run npm audit and scan auth/** for known vulnerability
  patterns. If severity medium or above found: open GitHub issue
  with CVE, affected file, line number, and remediation steps."

# Every Monday 9am — sprint health check
claude trigger create \
  --schedule "0 9 * * 1" \
  --prompt "Review all open PRs. Flag: no tests added, stale more
  than 5 days, touches auth/ or API rate limiting without review.
  Post summary to Slack #engineering with action items."
```

Set up once. Runs every night. You arrive Monday to a ranked task list, not a blank slate.

> *"A subagent's context window is its own. When it's done, it's gone. Your main conversation never saw the mess."*

---

## Part Five: Hooks — Encode Your Standards Into the Agent

Rules in documentation get ignored. Rules in hooks get enforced.

A hook is a JSON-configured handler that fires automatically on lifecycle events. The agent does something — a file gets written, a session starts, Claude is waiting for input — and the hook runs. No manual triggering. No memory required.

### The Linting Hook

The first hook every team should set up:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/run-lint.sh"
        }]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# .claude/hooks/run-lint.sh
file_path="$(jq -r '.tool_input.file_path // ""')"
if [[ "$file_path" =~ \.(js|jsx|ts|tsx)$ ]]; then
  make lint
fi
```

Every TypeScript edit triggers the linter automatically. Claude reads the output. Fixes errors before moving on. You never see a lint failure at PR time because it was caught after every single edit.

### The Notification Hook

Stop watching the terminal:

```json
{
  "hooks": {
    "Notification": [{
      "matcher": "permission_prompt|idle_prompt",
      "hooks": [{
        "type": "command",
        "command": "npx tsx \"$CLAUDE_PROJECT_DIR/.claude/hooks/notify.ts\"",
        "timeout": 5
      }]
    }]
  }
}
```

`permission_prompt` — Claude needs your approval before doing something consequential. Desktop notification fires. `idle_prompt` — Claude finished and is waiting. Another notification. You stop checking the terminal every 30 seconds.

**Two placement options:**
- `.claude/settings.json` — committed to git, shared with the team
- `~/.claude/settings.json` — personal, your machine only

> *"Hooks are how you encode your team's quality standards into the agent itself — not into a doc nobody reads."*

---

## Part Six: MCP — Your Entire Stack, Connected

Without MCP, Claude can read your files and run bash commands.

With MCP, Claude can read the Jira ticket, query your database, create the GitHub PR, and post the Slack update — in a single session, from a single prompt.

The shift: from developer who works in files to developer who works across your entire infrastructure.

**The one rule before any setup:** only connect what you're actively using that session. Every connected MCP server loads its full tool schema into context on every message — idle or not. One unused server costs 18,000 tokens per turn. Connect what you need. Disconnect what you don't.

### The 4 Stack Setups

**GitHub** — PR reviews, issue management, branch operations:

```bash
claude mcp add --transport http github https://mcp.github.com \
  --header "Authorization: Bearer ${GITHUB_TOKEN}"
```

> *Real workflow:* "Review all open PRs. Flag any touching auth/ that don't have corresponding test changes. Leave inline comments."

---

**PostgreSQL** — always use a read-only connection string for production:

```bash
claude mcp add postgres \
  --command "npx" \
  --args "-y @modelcontextprotocol/server-postgres" \
  --env DATABASE_URL=postgresql://readonly:pass@prod.db:5432/analytics
```

> *Real workflow:* "Find all API tokens created in the last 7 days that have never been used. Export with user_id and created_at."

---

**Slack** — summaries, alerts, team communication:

```json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://mcp.slack.com/mcp",
      "oauth": { "scopes": "channels:read chat:write search:read" }
    }
  }
}
```

> *Real workflow:* "Generate this week's engineering summary from git log and post to #engineering. Include: features shipped, bugs fixed, PRs merged."

---

**Jira** — use the Atlassian Rovo MCP (the old `/sse` endpoint retires June 2026):

```bash
claude mcp add --transport stdio jira -- \
  npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp
```

> *Real workflow:* "Implement the fix for JIRA issue ENG-4521. Read the ticket, understand the requirements, fix the code, create the PR."

---

**The credential rule — non-negotiable.** Never hardcode tokens:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://mcp.github.com",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    }
  }
}
```

`${GITHUB_TOKEN}` reads from your shell environment at runtime. Config is safe to commit. Token never appears in plaintext.

> *"MCP turns Claude from a developer who works in your codebase to a developer who works in your entire stack."*

---

## Part Seven: CI/CD — The Claude That Never Gets Tired

The PR review nobody has time to do properly by Friday afternoon. The security scan that gets skipped because there's a deadline. The dependency audit that should happen on every merge but doesn't — until it does, and it's a production incident.

Claude has time. Claude doesn't get tired at 6pm. Claude reviews the 47th PR of the week with the same scrutiny as the first.

### Headless Mode — The `-p` Flag

Everything in CI runs through one flag: `-p`. It turns Claude Code from an interactive session into a scriptable Unix command.

```bash
# Basic review
claude -p "Review PR changes and list potential issues"

# Read-only — Claude cannot edit files it's reviewing
claude -p "Review PR changes" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json \
  --max-tokens 20000

# Pipe errors directly in
cat auth-service.log | claude -p "Identify the root cause of this error"
```

### The PR Review Workflow

```yaml
# .github/workflows/claude-review.yml
name: Claude PR Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Run Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review the changes in this PR.
          Flag specifically: missing tests, potential security
          issues in auth flows, breaking API changes.
          Be precise — file names and line numbers." \
          --allowedTools "Read,Grep,Glob" \
          --output-format json \
          --max-tokens 20000 > review.json
```

**Four things that prevent CI disasters:**

- `fetch-depth: 0` — without full git history, Claude reviews a single commit, not the PR
- `--allowedTools "Read,Grep,Glob"` — read-only, Claude cannot push changes to a PR it's reviewing
- `--max-tokens 20000` — hard budget per run, prevents runaway cost at 3am across 40 PRs
- `timeout-minutes: 15` — hard kill, if a review takes 15 minutes something went wrong

### 3 CI Automations to Set Up This Week

| Automation | Trigger | Tools | Token cap | Cost estimate |
|---|---|---|---|---|
| PR review | PR opened/updated | Read, Grep, Glob | 20K | ~$0.03/review |
| Nightly security scan | `cron: 0 2 * * *` | Read, Bash(npm audit) | 100K | ~$0.15/night |
| Docs sync check | Push to main | Read, Grep, Glob | 30K | ~$0.05/push |

At 20 PRs/week: ~$0.60/week. At 365 nights of audits: ~$55/year. The cost of missing one critical vulnerability in production is not $55.

> *"CI/CD Claude doesn't get tired at 6pm. It reviews the 47th PR of the week the same way it reviewed the first."*

---

## Part Eight: The Daily Routine That Compounds

Habits that look like 20% improvements in week one become 10x by month six.

The compounding is in the system design, not the individual session.

```
8:55am  Check overnight outputs
        Nightly audit ran at 2am — one medium auth vulnerability
        flagged. GitHub issue opened with CVE, file, line, fix.
        Monday summary posted to Slack at 8am.

9:00am  /load-context
        Skill fires in 30 seconds. Claude knows the project,
        the sprint, open tasks, recent gotchas. Fresh session.
        Full context. No re-explaining.

9:15am  Chat 1: Planning
        Plan subagent reads codebase. Produces spec file.
        Approach, checkpoints, success criteria. You review.
        Approve or adjust. Claude doesn't build until you say so.

9:30am  Chat 2: Implementation
        Fresh context. /load-context + feed in the spec.
        Subagents execute each task. Commit after each one.
        update-docs fires automatically after code changes.
        git-commit generates the message from the diff.

11:00am  PR raised
         GitHub Actions runs the review workflow automatically.
         Claude posts inline comments on the PR.
         You get the summary in Slack via MCP.

5:45pm  /learn
        Two new gotchas discovered this session.
        Claude proposes where to save them in docs/.
        You approve. Tomorrow's Claude starts sharper.
```

### The 5 Habits That Separate 20% From 10x

**1. Fresh chat for every new task.** `/clear` between unrelated work. The debt from an old conversation is a tax on every new message. Single highest-ROI habit in the list.

**2. Plan Mode before every non-trivial implementation.** `Shift+Tab` twice. Claude explores the codebase, maps the problem, proposes an approach — before writing a single line. Prevents the most expensive mistake: 200 lines in the wrong direction before you notice.

**3. Edit/retry instead of correction messages.** When Claude misunderstands, don't send a follow-up. The wrong response, your correction, and the new response sit permanently in context, compounding forever. Use the edit button. Rewrite the original prompt. The bad exchange vanishes.

**4. `/learn` at end of sessions with new gotchas.** Any time Claude hit something unexpected — capture it. Month-3 Claude is dramatically better than day-1 Claude because the docs folder compounds.

**5. Auto-compact at 75%, token budget on extended thinking.**

```json
{
  "autoCompactPercentageOverride": 75,
  "env": { "MAX_THINKING_TOKENS": "8000" }
}
```

Quality degrades before 92%. You're already in the dumb zone before the default fires. Set it earlier. Cap extended thinking. Two settings, one-time change, immediate savings.

---

## The Compounding Machine

Go back to the Monday morning story.

The overnight vulnerability report — Scheduled Task on cron, auth-agent returning structured JSON, GitHub MCP opening the issue automatically.

The PR flagging — GitHub Actions workflow, Claude Code in headless mode, read-only tools, 20K token cap.

The Slack summary — Slack MCP, triggered by the scheduled task, generated from git log.

The task file on your desk — spec-driven subagent workflow from the planning session.

The CLAUDE.md that made all of it coherent — 50 lines, a behavioural contract in `rules/`, progressive disclosure into `docs/`, getting smarter every session via `/learn`.

---

A team of 6 engineers cut Claude Code costs **72% in four weeks** using these patterns. The average enterprise cost is $13 per active day before optimization. With model routing, context hygiene, and session discipline — that number drops substantially. With the full system running, the productivity gains compound against a falling cost curve.

That's the real 10x. Not prompting harder. **Building a system that gets smarter and cheaper every week you use it.**

> *"You don't 10x your productivity by working harder inside Claude. You 10x it by designing a system that works when you're not there."*

---

**Start with one thing.** Pick the section of this article that describes your biggest daily friction. Build that first. One skill for the workflow you repeat. One agent for the domain that bites you most. One MCP for the tool you context-switch to constantly.

One system. One week.

Then watch it compound.

---

*This is Part III of a trilogy.*
*[Part I](https://medium.com/@pranavsinghtomar/the-ai-coding-tool-thats-booming-and-helping-every-sde-656e0a09c3bf) covered the origin story and leaked architecture.*
*Part II goes one layer deeper — how the model reasons, how tool selection works internally, how memory compaction preserves intent.*

*If this changed how you think about Claude Code, share it with one engineer on your team. These patterns compound better when the whole team runs them.*

*Follow for more deep dives on AI engineering, developer tools, and the systems that actually matter.*
