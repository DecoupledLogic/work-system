# Improving Sub-Agent Prompts

## Stop Context Bleeding

What’s happening

Agents occasionally absorb each other’s goals/tools and start freelancing outside their lane (exactly what the article noted: context pollution, unreliable auto-invocation). ([*Medium*](https://medium.com/%40cheemabyren/how-i-turned-claude-code-into-my-own-dev-team-with-subagents-bbbdf8a9aef8))

Fixes that work together

-   Per-agent contracts (system prompts): declare mission, inputs, outputs, forbidden topics, and escalation rules. Keep them small and *hard-fenced*.
-   Task tags → agent routing: treat tags as a deterministic switch, not vibes. Route by `domain`, `artifact`, and `verb` (e.g., `domain:frontend, artifact:component, verb:implement`). If multiple match, prefer the most specific.
-   Thread isolation: run each agent in a separate thread/session. Never broadcast user history globally; *pull* only what’s relevant per task.
-   Retrieval budget: inject at most N chunks (e.g., 8) per step; summarize spillover. This limits accidental leakage.

Minimal subagent front-matter (works for Claude Code + your stack):

```yaml
---
name: frontend-implementer
description: Implement React components from approved specs only
tags:
  domain: frontend
  artifact: component
  verb: implement
inputs:
  - spec.md
  - design-tokens.md
forbidden:
  - api-design
  - auth-flows
handoff:
  - security-reviewer
  - backend-architect
constraints:
  - Only modify files under /ui/components/**
  - Decline tasks missing spec.md
success_criteria:
  - Builds pass, storybook story present, snapshot tests updated
---
```

Anthropic’s own subagent docs explicitly encourage separate prompts and context windows; leverage that as the conceptual backbone. ([*Anthropic*](https://docs.anthropic.com/en/docs/claude-code/sub-agents?utm_source=chatgpt.com))

If you prefer graph orchestration: use LangGraph state channels per agent node so messages don’t mix; it gives you scoped state + checkpointers. (*LangChain AI*)

## Shared Memory

Goal: a “memory bus” that’s queryable, typed, and *policy-controlled*.

Three tiers (read/write rules differ):

1.  Facts (immutable): decisions, env vars, API base URLs, design tokens.
2.  Logs (append-only): commits, ADRs, test runs, deploys.
3.  Plans (mutable): current milestone, task DAG, owners.

Storage pattern (C\# / Semantic Kernel)

-   KV store for small, authoritative facts (`project:koala:api.base_url`).
-   Vector store for chunky docs (CLAUDE.md, specs, ADRs) with strict metadata filters (project/feature/task).
-   Checkpointer for per-thread short-term state.

SK has native concepts for agents + memories and vector connectors you can start with and later swap (pgvector). ([*Microsoft Learn*](https://learn.microsoft.com/en-us/semantic-kernel/overview/?utm_source=chatgpt.com)) If you do go graph-first, LangGraph’s checkpointers give persistent thread memory without global bleed. (*LangChain AI*)

Read policy example (enforced in the router):

-   Query only `docs` where `project==X AND feature==Y AND role in (owner,shared)`; hard-cap 8 chunks; summarize to ≤1k tokens.
-   Always include the Fact Pack (tiny KV snapshot) first.
-   Deny cross-project reads unless task label includes `cross_project:true`.

## Reliable and Auditable Auto-Invocation

What breaks: the model sometimes handles tasks itself instead of calling the right subagent—exact complaint from the post. ([*Medium*](https://medium.com/%40cheemabyren/how-i-turned-claude-code-into-my-own-dev-team-with-subagents-bbbdf8a9aef8))

Practical router pattern (two stages):

1.  Classifier → route: small model or rules maps `(tags, text)` → `agent_id`.
2.  Tool call → invoke: use function/tool calling to *require* the handoff.

Docs you can lean on for tool calls and multi-tool routing: OpenAI Function Calling (patterns generalize; any SDK), and similar API guides. ([*OpenAI Platform*](https://platform.openai.com/docs/guides/function-calling?utm_source=chatgpt.com), [*OpenAI Cookbook*](https://cookbook.openai.com/examples/reasoning_function_calls?utm_source=chatgpt.com), [*Together.ai Docs*](https://docs.together.ai/docs/function-calling?utm_source=chatgpt.com))

Routing rules (deterministic first, model second):

-   If task has `agent:` tag → invoke that agent directly.
-   Else if `(domain, artifact, verb)` exactly matches an agent → invoke.
-   Else call a small LLM “Router” that returns `{agent, confidence}`; require `confidence ≥ 0.7` or escalate for human pick.

Handoff contract (prevents bleed):

-   Router attaches a work order: `{objective, inputs, constraints, needed_outputs}`.
-   Receiving agent must reply with a one-shot plan and ask for missing inputs *before* doing work.

## Context Markdown

The Medium piece highlights nested `CLAUDE.md` files yielding better context efficiency. Keep them, but normalize structure so your router can target sections precisely. ([*Medium*](https://medium.com/%40cheemabyren/how-i-turned-claude-code-into-my-own-dev-team-with-subagents-bbbdf8a9aef8))

Suggested repo files:

-   `CLAUDE.md` (project overview: scope, architecture sketch, glossary)
-   `agents/<role>.md` (role contract—same schema as front-matter)
-   `specs/<feature>/spec.md` (source of truth)
-   `adr/adr-####.md` (immutable decisions; feed into Facts)

Add a tiny JSON Fact Pack the router can load in \<5ms:

```json
{
  "project":"Koala",
  "services":{"api":"https://api.example.com"},
  "designTokensVersion":"2.3.1",
  "lint":"eslint@9",
  "test":"vitest"
}
```

## Guardrails & Ops

-   Token budgeter: centralize limits per agent; trim history with role-aware summarizers (LangGraph state reductions are common). ([*Reddit*](https://www.reddit.com/r/LangChain/comments/1ei7fvd/reducing_length_of_state_in_langgraph/?utm_source=chatgpt.com))
-   Escalation matrix: when constraints trip (missing spec, forbidden area), agents *must* return `BLOCKED(reason, needed_inputs)`.
-   Observability: log `task_id → agent_id → input_digest → output_digest → deltas`.
-   Evaluation: use your Nucleus evaluator to score *context isolation* (no off-domain suggestions) and *routing accuracy*. Track weekly.

## Quick Start Checklist

1.  Add front-matter contracts to each agent; enforce forbidden areas. ([*Anthropic*](https://docs.anthropic.com/en/docs/claude-code/sub-agents?utm_source=chatgpt.com))
2.  Implement a router: rules → small LLM fallback → function/tool call to subagent. ([*OpenAI Platform*](https://platform.openai.com/docs/guides/function-calling?utm_source=chatgpt.com), [*OpenAI Cookbook*](https://cookbook.openai.com/examples/reasoning_function_calls?utm_source=chatgpt.com))
3.  Stand up a memory bus (KV + vector + per-thread checkpoints) with SK / pgvector; filter by `project/feature/task`. ([*Microsoft Learn*](https://learn.microsoft.com/en-us/semantic-kernel/overview/?utm_source=chatgpt.com))
4.  Convert key docs to context markdown with consistent headings and metadata. The subagent article’s nested markdown practice supports this style. ([*Medium*](https://medium.com/%40cheemabyren/how-i-turned-claude-code-into-my-own-dev-team-with-subagents-bbbdf8a9aef8))
5.  Add eval hooks (routing accuracy, context bleed rate, rework %) and alert when thresholds slip.
