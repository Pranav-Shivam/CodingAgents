# Research: Claude Code Community Best Practices — Repo Setup Patterns

**Date:** 2026-05-01
**Question:** What do top GitHub repos and official docs say about Claude Code setup — CLAUDE.md, agents, skills, hooks, CI/CD? What did we get wrong vs. right?

## Sources visited

| URL | Status | Content summary |
|---|---|---|
| https://github.com/hesreallyhim/awesome-claude-code | ✅ useful | 42k stars, curated index of skills/hooks/agents — community directory |
| https://github.com/VoltAgent/awesome-claude-code-subagents | ✅ useful | 131+ subagents, frontmatter patterns, model routing strategy |
| https://github.com/disler/claude-code-hooks-mastery | ✅ useful | 13 hook implementations covering all lifecycle events |
| https://github.com/fcakyon/claude-codex-settings | ✅ useful | Battle-tested personal setup, 40+ plugins, observability hooks |
| https://github.com/shanraisshan/claude-code-best-practice | ✅ useful | 20k stars, 84 compiled practices |
| https://github.com/humanlayer/humanlayer | ✅ useful | Real CLAUDE.md example (88 lines, monorepo), priority-based TODO system |
| https://github.com/anthropics/claude-code-action | ✅ useful | Official v1 GitHub Action — replaces deprecated `npm install -g @anthropic-ai/claude-code` |
| https://code.claude.com/docs/en/best-practices | ✅ useful | Anthropic official best practices |
| https://code.claude.com/docs/en/sub-agents | ✅ useful | Sub-agent creation docs |
| https://code.claude.com/docs/en/github-actions | ✅ useful | GitHub Actions integration docs |
| https://code.claude.com/docs/en/code-review | ✅ useful | Code Review feature, REVIEW.md usage |
| https://www.humanlayer.dev/blog/writing-a-good-claude-md | ✅ useful | HumanLayer CLAUDE.md guide — under 60 lines benchmark |
| https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/ | ✅ useful | Claude Agent Skills deep dive |
| https://claudefa.st/blog/guide/settings-reference | ✅ useful | settings.json field reference |

## Key findings

> "`npm install -g @anthropic-ai/claude-code` is explicitly deprecated. Use `anthropics/claude-code-action@v1` instead."
— [Claude Code GitHub Actions docs](https://code.claude.com/docs/en/github-actions)

> "Skills were not invoked in 56% of test cases [in Vercel agent evaluations]. Write the pointer. Trust the pointer."
— Playbook / Vercel internal evals

> "HumanLayer keeps their CLAUDE.md under 60 lines. That's not minimalism as a philosophy. That's the math working correctly."
— [HumanLayer CLAUDE.md blog](https://www.humanlayer.dev/blog/writing-a-good-claude-md)

**Patterns confirmed correct in our setup:**
- CLAUDE.md under 50 lines ✅
- `.claude/agents/` for project-scoped agents ✅
- No `Write`/`Edit` tools on audit agents ✅
- Haiku for cheap repeatable skills, Sonnet for analysis agents ✅
- `autoCompactPercentageOverride: 75` ✅
- `fetch-depth: 0` on GitHub Actions checkout ✅

**Gaps found and fixed:**
- GitHub Actions: migrated to `anthropics/claude-code-action@v1`
- Model field: changed to aliases (`sonnet` not `claude-sonnet-4-6`)
- Added `permissionMode: plan` + `maxTurns: 20` to all agents
- Added `disable-model-invocation: true` to workflow skills
- Added `SessionStart` hook (session context injection)
- Added `PreToolUse` safety hook (block destructive commands)
- Created `REVIEW.md` (extracted from inline YAML string)
- Fixed `emoji-agent.md` missing frontmatter
- Raised `MAX_THINKING_TOKENS` from 8000 → 16000

## Decision made

Applied all 9 priority fixes to codebase. Full change log in conversation history.
