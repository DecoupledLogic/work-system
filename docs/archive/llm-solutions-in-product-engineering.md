# LLM Solutions in AI Engineering

## Layer 1 - User Prompt (human-in-the-terminal)

This is the simplest approach where you directly prompt your agent, and it calls a service to generate an outcome (like generating a song or code). You're actively involved in each step of producing the output.

Select to build this solution when you're first encountering a new problem or exploring a solution. It's about understanding how to solve the problem yourself with your agent before scaling up. This helps produce output and also serves as a notebook to mine for scalable solutions.

-   Pros: Direct oversight, simplicity, high accuracy, high control.
-   Cons: Not scalable, human is the bottleneck.

## Layer 2 - System Prompt (slash command)

You codify a frequently used prompt into a reusable command or file (e.g., Claude Code's /command/name.md or Gemini's TOML files).

Select to build this solution when you spot a pattern and have done something three or more times. It's for formalizing and automating repetitive tasks and getting out of the manual loop. It’s also for sharing a solution. This helps improve solutions through peer review and user feedback.

-   Pros: Reusability (write once, use many times), version control, quick iteration.
-   Cons: Initial setup overhead, need to manage command locations, adds a thin abstraction layer.

## Layer 3 - Sub-Agent Prompts

Your primary agent spins up dedicated, specialized sub-agents to handle specific tasks, allowing for parallelization and specialization.

Select to build this solution only when you need specialization and parallelization. Sub-agents run in isolation and reduce context bloat in the primary agent. The primary agent gets to spread context across sub-agents. They are like a dynamic system prompt to system prompt workflow. If you don't need the complexity, a reusable prompt is sufficient.

-   Pros: Enables parallel execution, specialization of tasks, reusability.
-   Cons: Potential for lock-in (e.g., Claude Code), "gray box" problem (debugging is not simple), careful primary agent selection of sub-agents and management of information flow between primary agent and sub-agents, adherence to governance and safety policies and procedures.

## Layer 4 - Custom MCP

You build a dedicated server that acts as an interface layer for your agents. It calls external APIs or custom services directly, exposing them to your agents through custom tools and prompts.

Select to build this solution when a CLI tool or direct API call isn't enough, when you need more specific functionality, or when integrating with multiple external services or proprietary internal assets. It provides a concrete agent layer.

-   Pros: Single integration point for all agents, full control and customizability over how services are exposed, ability to define custom workflows and tools.
-   Cons: Requires maintenance, integrations need to be built (or explicitly defined for the agent), built for agents, not humans.

## Layer 5 - LLM App

This is the highest level, involving building a complete application with its own CLI, MCP server, UI, and API. Your agents can interact with this application on multiple dimensions.

Select to build this solution when you have a long-term vision for a solution, are building a product, or need to expose the tool to non-engineering teams through various interfaces.

-   Pros: Full control, infinitely extensible, multiple access patterns (CLI, MCP, UI, API).
-   Cons: Highest cost in terms of complexity, time, and resources.

## ADR

Start at the lowest complexity level and only scale up to more complex patterns when absolutely necessary, based on the problem's need for compute, reusability, specialization, or integration. If you haven’t found a solution at Level 1, you obviously shouldn’t be building at Level 5.

Thanks to [*IndyDevDan*](https://www.youtube.com/@indydevdan) for lighting this up in my neural network.
