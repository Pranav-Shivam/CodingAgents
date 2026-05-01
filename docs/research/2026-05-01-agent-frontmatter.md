# Research: Claude Code Agent Frontmatter — Model Aliases and permissionMode

**Date:** 2026-05-01
**Question:** Does `model: sonnet` (alias) work in `.claude/agents/*.md` frontmatter, or does it require full model IDs like `model: claude-sonnet-4-6`? Is `permissionMode: plan` a valid field?

## Sources visited

| URL | Status | Content summary |
|---|---|---|
| https://code.claude.com/docs/en/sub-agents | ✅ useful | Official frontmatter fields table, model alias docs, permissionMode values |
| https://code.claude.com/docs/en/model-config | ✅ useful | Full alias table with resolution targets per provider |
| https://github.com/affaan-m/everything-claude-code/issues/173 | ✅ useful | Known bug: model field not honored in some versions — fixed by `claude update` |
| https://github.com/anthropics/claude-code/issues/8501 | ✅ useful | YAML frontmatter authoritative documentation discussion |

## Key findings

> "model — Model to use: `sonnet`, `opus`, `haiku`, a full model ID (for example, `claude-opus-4-7`), or `inherit`. Defaults to `inherit`"
— [Create custom subagents](https://code.claude.com/docs/en/sub-agents)

> "permissionMode — Permission mode: `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. Ignored for plugin subagents."
— [Create custom subagents](https://code.claude.com/docs/en/sub-agents)

> "On the Anthropic API, `opus` resolves to Opus 4.7 and `sonnet` resolves to Sonnet 4.6."
— [Model configuration](https://code.claude.com/docs/en/model-config)

**Additional aliases documented:**

| Alias | Behavior |
|---|---|
| `sonnet` | Latest Sonnet (daily coding tasks) |
| `haiku` | Latest Haiku (fast, simple tasks) |
| `opus` | Latest Opus (complex reasoning) |
| `opusplan` | Opus during plan mode → Sonnet for execution |
| `sonnet[1m]` | Sonnet with 1M token context |
| `opus[1m]` | Opus with 1M token context |
| `best` | Most capable model (= Opus currently) |
| `inherit` | Same model as parent conversation (default) |

## Decision made

Changed all 10 security agents from `model: claude-sonnet-4-6` → `model: sonnet`. Aliases are the canonical form — full model IDs go stale silently when new model versions release. Also confirmed `permissionMode: plan` is valid and kept it on all security agents (enforces read-only at permission layer, defense-in-depth beyond the tools list).
