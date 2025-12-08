# Programming in Natural Language

## The Honesty

Let's be honest about what "natural language programming" usually means:

```bash
# This is NOT natural language
/work-item assign WI-042 @cbryant
```

That's a DSL. It's more readable than an API call, but nobody talks like that.

**Natural language** is what rolls off your tongue:

```text
assign issue 42 to charles
```

Or even more naturally:

```text
give the login bug to charles, it's urgent
```

## The Gap

There's a gap between how we talk and how computers listen:

| How You Say It | What Systems Expect |
|----------------|---------------------|
| "issue 42" | `WI-042` |
| "charles" | `@cbryant` |
| "the login bug" | `WI-042` (from context) |
| "give it to" | `assign` |
| "it's urgent" | `route ... urgent` |

Traditionally, programmers bridge this gap by learning the syntax. But why should they?

## The AI Bridge

With an AI agent in the conversation, **you don't need rigid syntax**. The AI understands context and translates intent to operations:

```text
You: give the safari login bug to charles, mark it urgent

Claude: I'll assign that to Charles and escalate it.

[Internally resolves:]
  - "safari login bug" → searches, finds issue #42
  - "charles" → looks up team, finds Charles Bryant
  - "mark it urgent" → route to urgent queue

[Executes the operations]

Done. Assigned issue #42 to Charles and routed to urgent queue.
```

You spoke in your words. The system understood.

## Ubiquitous Language

Your team has its own vocabulary:

| Your Team Says | Generic Term |
|----------------|--------------|
| "issue" | work item |
| "ticket" | work item |
| "card" | work item |
| "bug" | defect |
| "charles" | @cbryant |
| "the portal project" | PRJ-001 |

True natural language respects **your** ubiquitous language, not some generic schema.

```text
# If your team uses GitHub
"assign issue 42 to charles"

# If your team uses Jira
"assign ticket ABC-123 to charles"

# If your team uses Trello
"move the login card to charles"
```

Same intent. Different vocabulary. All valid.

## Context Awareness

Natural language relies on context:

```text
You: what's charles working on?
Claude: Charles has 3 active issues...

You: give him the safari bug too
Claude: Assigned issue #42 to Charles.
```

Notice:

- "him" → resolved from previous mention of Charles
- "the safari bug" → resolved from known issues
- "too" → implies addition to existing work

No IDs. No handles. Just conversation.

## The Real Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Human Language                              │
│        "give the login bug to charles, it's urgent"            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     AI Understanding                            │
│  Intent: assign + route                                         │
│  Subject: "login bug" → search → issue #42                     │
│  Target: "charles" → lookup → Charles Bryant                   │
│  Urgency: "urgent" → urgent queue                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Domain Operations                           │
│  assign(issue: 42, to: "charles")                              │
│  route(issue: 42, queue: "urgent")                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     External Systems                            │
│  GitHub, Teamwork, Linear, JIRA...                             │
└─────────────────────────────────────────────────────────────────┘
```

The AI is the translator. You speak human. It speaks system.

## Examples of Real Natural Language

### Task Management

```text
You: what's in the urgent queue?
Claude: 3 issues in urgent:
  - #42 Safari login bug (unassigned)
  - #38 Payment timeout (Jane)
  - #51 Mobile crash (unassigned)

You: I'll take the safari one
Claude: Assigned #42 to you. Starting work?

You: yeah, and let the team know I'm on it
Claude: Done. Added comment: "Chris is investigating this issue."
```

### Status Updates

```text
You: I fixed the safari bug, took about 2 hours
Claude: Nice! Logged 2 hours to #42 and marked it resolved.
  Should I move it to done?

You: yes, and the root cause was webkit cookie handling
Claude: Got it. Added to the resolution notes:
  "Root cause: WebKit strict cookie handling. Fixed SameSite attribute."
```

### Planning

```text
You: we need to build user auth for the portal
Claude: Want me to create a feature for that?

You: yeah, break it into login, password reset, and oauth
Claude: Created:
  - Feature: User Authentication
    - Story: Login flow
    - Story: Password reset
    - Story: OAuth integration

  Assign to anyone?

You: give login to me, the rest can wait
Claude: Assigned "Login flow" to you. Others in backlog.
```

## The DSL Still Exists

Under the hood, there's still structure:

```yaml
# What the AI resolves your intent to:
operation: assign
subject:
  type: issue
  reference: "safari login bug"
  resolved_id: 42
target:
  type: agent
  reference: "charles"
  resolved_id: "cbryant"
```

But you never see it. You just talk.

## When Precision Matters

Sometimes you need to be explicit:

```text
You: assign issue 42 to user cbryant in project portal

Claude: Done. Assigned issue #42 to @cbryant in the Portal project.
```

Natural language doesn't mean imprecise. It means **flexible precision** - be specific when you need to, casual when you don't.

## The Insight

Programming in natural language isn't about:

- Readable DSLs (that's just better syntax)
- Voice interfaces (that's just different input)
- Code generation (that's just automation)

It's about **eliminating the translation burden**.

You think in concepts: "the login bug", "charles", "urgent"
Systems think in identifiers: `WI-042`, `@cbryant`, `queue:urgent`

The AI handles the translation. You stay in your mental model.

## Conclusion

True natural language programming means:

1. **Your vocabulary** - "issue" not "work-item", "charles" not "@cbryant"
2. **Your context** - "the login bug" not "WI-042"
3. **Your flow** - conversation, not commands
4. **Your intent** - "it's urgent" not "--queue urgent"

The best interface is no interface. Just say what you mean.

```text
give the login bug to charles, it's urgent
```

That's programming in natural language.
