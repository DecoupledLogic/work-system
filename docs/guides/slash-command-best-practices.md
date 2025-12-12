# Reprogramming AgenticOps Operations with Claude Code Slash Commands

## Introduction to Claude Code and AgenticOps

Imagine writing your development workflow the same way you write code functions – in plain English. **Claude Code slash commands** make this possible[[1]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=What%20if%20you%20could%20write,in%20code%2C%20using%20plain%20English). They let you create **reusable prompt templates** (like functions) that can automate parts of your engineering, DevOps, design, or any operational workflow. Each command encapsulates a task or workflow in natural language, which Claude (the AI) will execute. This approach is **programmable prompting**: you codify how you work so that the AI can perform tasks consistently and at scale[[2]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=This%20is%20programmable%20prompting,quality%20analyst%2C%20even%20the%20CEO).

**AgenticOps** is an AI-driven operations methodology (as used in the “Value Train” framework) that emphasizes agent-based automation across the development pipeline. In AgenticOps, AI “agents” help carry out tasks in various roles (from coding and design to deployment and QA). Claude Code slash commands are a core enabler of AgenticOps because they allow you to define these agent behaviors and workflows as shareable command files. Essentially, you are “coding your value stream” – turning the end-to-end process (value delivery pipeline) into code that an AI can run. This means your personal or team workflows become reproducible **commands** that anyone on the team (or any AI agent) can invoke. Are you terrible at design? Run the designer’s prepared commands. Don’t know how to configure the cloud deployment? Use the DevOps commands. In this way, expertise is captured and **shared via slash commands**[[2]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=This%20is%20programmable%20prompting,quality%20analyst%2C%20even%20the%20CEO), enabling anyone (even non-specialists) to leverage that knowledge.

Think of it as building your own **terminal-native AI assistant** – one you can trust to follow your procedures, scale up your productivity, and improve over time with each iteration[[3]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=using%20shell%20commands%20and%20MCP). In the following sections, we’ll explore how to set up and use Claude Code slash commands to reprogram your AgenticOps operations. We’ll cover everything from command anatomy and argument handling to multi-agent design patterns, tool integration through Claude’s Model Context Protocol (MCP), and best practices for safe and effective command design. By the end of this guide, you should be ready to start automating your workflows and truly **code your value stream**.

## Setting Up Your Command Environment

Before creating commands, you need to set up the environment so Claude can recognize and run your slash commands. Claude Code looks for command files in a specific directory structure:

-   **Project-level commands**: a folder named `.claude/commands/` inside your project repository (these commands are scoped to that project)[[4]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=In%20Claude%20Code%2C%20slash%20commands,in%20a%20specific%20folder%20structure).
-   **Personal commands**: a global folder `~/.claude/commands/` on your machine (commands here are available across all projects in your Claude workspace)[[4]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=In%20Claude%20Code%2C%20slash%20commands,in%20a%20specific%20folder%20structure).

Each command is defined by a Markdown file (`.md`) in one of those directories. The **file name** (and path) determines the command name. For example, a file `.claude/commands/fix-bug.md` becomes the command `/fix-bug`, and a nested file `.claude/commands/frontend/component.md` becomes `/frontend:component` (folder name acts like a namespace)[[5]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Each%20command%20is%20a%20,The%20filename%20becomes%20the%20command)[[6]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=).

**Install and Access Claude Code**: Ensure you have access to Claude Code (for instance via the Claude AI interface or Claude Desktop app). On Claude Desktop (or similar local setup), you might need to configure it to load your command files. Claude Code may use local MCP servers to interface with your filesystem and tools[[7]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,or%20run%20local%20commands%20securely). In practice, this means you might provide a configuration (via a JSON file and a `--mcp-config` flag) to allow Claude to securely access local resources and run shell commands[[8]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Connecting%20MCP%20Servers). Setting up these integrations is optional for basic usage, but required if you want Claude to read/write files or execute local commands as part of your slash commands.

**Initialize the folder**: Create the `.claude/commands/` directory in your project (and/or the global commands directory). Make sure your command files are stored in Git just like any code – version control helps you track changes and collaborate on command development[[9]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI). If your project has a `settings.json` for Claude, you can also configure things like command hooks (we’ll discuss hooks later).

Once your environment is set up and Claude Code is running, it will automatically detect the Markdown files in these command directories. Now you’re ready to define commands and have them become part of your AI assistant’s repertoire[[10]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,on%20your%20local%20machine).

## Understanding Slash Command Anatomy

A Claude slash command is essentially a **Markdown-based prompt template**. Knowing the anatomy of a command file will help you design effective ones:

-   **Filename = Command Name**: The name of the `.md` file (and any parent folder as namespace) becomes the trigger text. For example, `frontend/component.md` is invoked with `/frontend:component`[[6]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=). Use clear, descriptive names so the command’s purpose is obvious (e.g. `design:lint` instead of something vague)[[11]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%BE%20Use%20Descriptive%2C%20Intuitive%20Names,data%3Amigrate).
-   **Frontmatter (Metadata)**: At the top of the file, you can include a YAML frontmatter section delineated by `---`. This is optional but highly recommended. In frontmatter, you describe the command and specify metadata such as:
-   `description`: A one-line summary of what the command does.
-   `command-type`: Is this an `action` (deterministic helper) or an `agent` (orchestrator)? We’ll discuss this distinction next.
-   `argument-hint`: Hint text for what argument the command expects (helps users with auto-completion and clarity).
-   `allowed-tools`: A list of tools the command is permitted to use (e.g. `"Read"`, `"Write"`, `"Bash"`, `"MultiEdit"`). This acts as a security control and capability descriptor.
-   `version`: (Optional) version number of the command template.
-   `source`: e.g. `internal` or other tag for origin.

For example, a frontmatter for an action command might look like:

```
---
description: Generate OKLCH token CSS from brand colors  
command-type: action  
argument-hint: color list  
allowed-tools: ["Write","Bash"]  
version: 1.0.0  
source: internal  
---
```

And an agent command’s frontmatter might allow more tools and describe a broader workflow:

```
---
description: Orchestrate design system initialization (tokens, audits, linting)  
command-type: agent  
argument-hint: optional project path  
allowed-tools: ["Read","Write","Bash","MultiEdit"]  
version: 1.0.0  
source: internal  
---
```

Including clear metadata helps both humans and the AI quickly understand the command’s role[[12]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Metadata%3A%20How%20to%20Signal%20Agent,vs%20Action)[[13]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,).

-   **Prompt Content**: After the frontmatter, the rest of the file is the **prompt that Claude will follow** when the command is executed. This can include plain language instructions, references to files or other commands, and even tool invocations. Essentially, this is where you script the steps or logic of the task in Markdown format.

You can use special variables and syntax in the content: - Use `$ARGUMENTS` to include whatever the user types after the command (more on arguments in the next section). You can also use placeholders like `$1`, `$2` etc. if you want to treat parts of the input separately (though Claude currently treats the whole input as one string unless you parse it)[[14]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20reasoning%2C%20not%20for%20logic). - Reference files or resources by path using `@resource:` syntax. For example, `@src/utils/index.ts` can refer to a file in your project, and Claude can fetch its content if needed (via the `Read` tool)[[15]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20,read%2Fwrite%20network). - Use **built-in tools** in fenced code blocks prefixed with `!`. Claude Code supports directives like `!Read` (to read a file’s content), `!Write` (to write content to a file or apply edits), `!Bash` (to run shell commands), and others, by leveraging the Model Context Protocol (MCP) integration. These allow you to perform deterministic operations as part of the command[[15]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20,read%2Fwrite%20network). - Write the prompt in a structured, step-by-step manner. You can use headings, lists, or comments to guide Claude’s reasoning. For example, you might break the prompt into sections: **Objective**, **Steps**, **Criteria**, etc. (We’ll cover a recommended template structure later in the guide).

In short, a slash command file looks like a combination of a config (frontmatter) and a thoughtfully written prompt script. When you trigger `/your-command`, Claude loads this file, reads the frontmatter to set the context (tools allowed, etc.), then executes the prompt content. The result is that the AI will perform the defined workflow or task as if it were following a playbook you wrote.

## Agents vs Actions: Roles and Design

Not all commands are created equal – some are **agents** and some are **actions**, and it’s important to design each appropriately. This agent/action split is fundamental in AgenticOps design.

**Action Commands** are **focused, deterministic helper tasks**. They do one thing and do it well[[16]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint). Think of an action as a single step in a workflow – e.g., generating a set of design tokens, running a linter, formatting code, querying a dataset, etc. Characteristics of actions:

-   They have a **single responsibility** and predictable outcomes[[17]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint).
-   Minimal branching or decision-making internally – they take input, perform a procedure, and produce output.
-   They can be run on their own (e.g. you can call `/workflow:design:lint` directly to lint a file) **or** be invoked by agent commands as part of a larger workflow.
-   They typically use only the tools necessary for the task. For example, an action that just reads and analyzes a file might only need `Read` access, or an action that transforms data might just use `Bash` for a script. Keeping allowed tools limited makes actions safer and more focused[[18]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,clearly%20show%20action%20invocations%20and).

**Agent Commands** are **high-level orchestrators or coordinators**[[19]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test). An agent command strings together multiple actions (and possibly user interactions) to accomplish a complex goal. For example, an agent command `/workflow:design:init` might coordinate several steps: generate a theme, run audits, then lint files, then run tests – possibly delegating each step to an action command like `/workflow:design:generate-theme`, `/workflow:design:lint`, etc.[[20]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test). Characteristics of agents:

-   They handle the **workflow logic**: sequencing tasks, branching based on outcomes, prompting the user for input if needed, and verifying that the overall goal is achieved[[19]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test)[[20]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test).
-   They often have access to broader tools since they may perform varied tasks (read/write files, run multiple shell commands, even edit code). For instance, an agent might allow `MultiEdit` or combine `Read`/`Write`/`Bash` capabilities[[21]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Include%20these%20fields%20in%20frontmatter%3A).
-   They maintain the **high-level context** and pass relevant information to subcommands. Agents can call actions and **isolate context** for each sub-task to keep focus. (Claude can manage separate contexts for sub-agents so that each action gets just the relevant info, and the main agent retains the big picture)[[22]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=logic%20modular%20%26%20reusable,may%20require%20broader%20tool%20access)[[23]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%E2%80%99s%20slash%20command%20system%20and,window%20for%20clarity%20and%20performance).
-   They are responsible for **completion criteria** – e.g., an agent might include checks at the end (like running a final test or verifying certain conditions) to decide if the workflow succeeded[[24]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test).
-   Essentially, the agent is like a project manager or a conductor in the workflow, whereas actions are the specialists performing specific jobs.

**Why distinguish Agents vs Actions?**  
Marking a command as an `agent` or `action` (via frontmatter) and following the corresponding design principles brings several benefits:

-   **Clarity**: Just by looking at the command or its logs, you can tell if it’s orchestrating a process or doing a single task. This removes ambiguity when reading code or debugging[[25]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=1.%20%20,actions%20remain%20limited).
-   **Separation of Concerns**: Agents delegate work; actions carry out the work. This modularity makes commands reusable and easier to maintain[[26]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=is%20orchestration%20or%20a%20helper,isolated%20contexts%20to%20preserve%20focus). An action can be reused in different workflows, and an agent can swap out or add steps without each step being overly complex.
-   **Context Management**: Since agents break down the problem, each action can run with a clean context focused only on its job. The main agent collects results and maintains the overall state[[22]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=logic%20modular%20%26%20reusable,may%20require%20broader%20tool%20access). This avoids one giant prompt trying to do everything at once, which could confuse the model or hit context limits.
-   **Tool Security**: By design, you allow broad tools only in agents that truly need them, and keep actions more sandboxed. For example, an action that just formats text might not need internet access or multi-file editing – so don’t give it those. Agents, which supervise, might need a bit more leeway to orchestrate. This containment reduces risk of misuse[[18]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,clearly%20show%20action%20invocations%20and).
-   **Easier Debugging**: Logs and outputs can be clearly segmented. You can see in the logs something like `[design:init][AGENT] → Starting action /workflow:design:generate-theme` or `[design:lint][ACTION] → Found 3 issues` which instantly tells you what happened where[[27]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60%20,PASS%20%E2%80%94%20agent%20completed). If something fails, you know which action to fix. The agent’s summary log versus action-specific logs help pinpoint issues.

**Implementing the Distinction**: Use frontmatter to explicitly label and constrain each type:

```
command-type: agent      # or "action"
allowed-tools: ["Read","Write","Bash","MultiEdit"]  # for agent, possibly more tools
```

For an action you might do:

```
command-type: action
allowed-tools: ["Read","Write"]  # minimal required tools
```

Claude’s execution environment can enforce these (so an action won’t accidentally run a tool it’s not allowed to, for instance).

Also follow **naming conventions** to signal roles. Often, agent commands are named as high-level intents (e.g. `init`, `deploy`, `update-all`) and might reside in a root namespace or a broad category. Actions tend to have more specific names, often verbs or single-purpose nouns (e.g. `generate-theme`, `lint`, `query-db`). In practice you might see an agent `project:update-deps` calling actions like `project:get-current-deps` and `project:write-deps-file`. The naming pattern `namespace:verb-noun` is common, where some commands in that namespace are orchestrators and others are workers[[28]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20,theme%60%2C%20%60lint%60).

**Logging conventions**: As mentioned, adopting a log format that includes the command name and type is very helpful. By prefixing log lines, you know which command (and whether it’s an agent or action) produced each output. For example:

```
[design:init][AGENT] → Starting theme generation...
[design:generate-theme][ACTION] → Generated token variables.
[design:init][AGENT] → Completed theme generation.
[design:init][AGENT] → Running design lint...
[design:lint][ACTION] → Found 2 issues in CSS.
[design:init][AGENT] → Final test PASSED – workflow complete.
```

This structured logging is not automatic; you’d incorporate such logging messages in your command prompts. But doing so consistently provides a clear trace of execution[[29]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Log%20Prefixing%3A%20Verbal%20Signaling%20of,Role)[[30]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60%20%5Bdesign%3Agenerate,ACTION%5D%20Completed). It’s especially useful when a complex agent runs, so you can follow along or review what happened after the fact.

In summary, **design agents to orchestrate and decide, and design actions to execute and deliver**. This division of labor will make your slash command library easier to scale and reason about.

## Argument Handling and Dynamic Input Patterns

Most commands will need to accept some input to be flexible – that’s where **arguments** come in. Claude Code supports passing a single free-form argument string to your commands, accessible via the special variable `$ARGUMENTS`[[31]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Claude%20Code%20supports%20a%20,not%20named%2C%20and%20not%20typed). Understanding how to define and use this argument effectively is key to writing reusable commands.

**Basics of** `$ARGUMENTS`**:** When a user types text after the command name, Claude will inject that text into the command prompt wherever `$ARGUMENTS` appears. Importantly, this is treated as a raw string; the system does **not** automatically parse it into multiple parameters or types[[32]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Claude%20Code%20supports%20a%20,not%20named%2C%20and%20not%20typed). This means you have full control to interpret the argument as needed (and Claude won’t assume structure unless you tell it).

For example, consider a simple command file:

```
# /fix-issue  
Please fix the following issue:  
$ARGUMENTS
```

If a user runs:

```
/fix-issue The submit button doesn’t work on mobile.
```

Claude will replace `$ARGUMENTS` with *"The submit button doesn’t work on mobile."* inside the prompt, so the prompt becomes a request to fix that specific issue[[33]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60md%20%2Ffix,following%20issue%3A%20%24ARGUMENTS). This saves you from writing a custom prompt every time – you have a template and just plug in the new issue description.

**Defining expected arguments (hints):** You can document what kind of input a command expects using the `argument-hint` field in frontmatter. This is purely for the user’s benefit (and tooling like auto-complete); it doesn’t enforce anything. For instance:

```
argument-hint: path to lint (e.g., src/components or app/page.tsx)
```

This hint might appear in the UI or help text when someone tries to use `/workflow:design:lint`, reminding them to provide a file path or directory[[34]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Add%20the%20%60argument,to%20describe%20the%20expected%20input). Always provide a helpful hint for complex commands. It improves usability and reduces errors.

**Multi-part arguments:** Since `$ARGUMENTS` is one string, how do you handle cases where you need multiple pieces of input? There are a few patterns:

-   **Space-delimited segments:** The user can type multiple words or paths separated by spaces. Your command’s logic can then treat them as separate items. For example, if someone runs:

```
/workflow:design:lint src/components app/page.tsx
```

Here `$ARGUMENTS` would be `"src/components app/page.tsx"`. You can instruct Claude (or use a shell script) to split on spaces into a list of files. In a shell snippet, `$ARGUMENTS` will come through as words separated by space, so something like:

```
!bash for file in $ARGUMENTS; do 
  echo "Linting $file"; 
  # ... perform lint on $file 
done
```

would iterate over each provided path[[35]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=). This approach is simple but note that spaces in paths can break this (since spaces are the delimiter). In such cases, the user could quote a path with spaces, or you might use a different delimiter.

-   **Comma-delimited list:** The user separates parts of the input with commas. Example:

```
/workflow:design:deploy staging,hotfix
```

Now `$ARGUMENTS` is the string `"staging,hotfix"`. In your prompt or code, you can say: *"Split* `$ARGUMENTS` *by comma. The first part is the environment, second is the branch."*[[36]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) Claude will then know to break it apart. Or you can handle it in a shell script by replacing commas with space and then iterating similarly.

-   **Key-value pairs:** This is a powerful pattern to simulate multiple named parameters. The user provides inputs like `key1=value1 key2=value2`. For example:

```
/deploy:build env=staging version=1.2.3
```

Here `$ARGUMENTS` will be the string `"env=staging version=1.2.3"`[[37]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=). Claude won’t automatically assign “env” or “version”, but you can parse it. A common approach is to use a shell block in your command to extract these into variables:

```
!bash <<'EOF'
# Parse key=value pairs into shell variables
for pair in $ARGUMENTS; do
  key="${pair%%=*}"
  value="${pair#*=}"
  export "$key"="$value"
done

# Validate that required keys are present
if [ -z "$env" ]; then echo "Missing env"; exit 1; fi
if [ -z "$version" ]; then echo "Missing version"; exit 1; fi

# Use the variables (example: call a deploy script)
./scripts/deploy.sh --env "$env" --version "$version"
EOF
```

This snippet will loop through each chunk in the argument string (which are separated by spaces, hence `env=staging` and `version=1.2.3` are separate in `$ARGUMENTS`), split at the `=` into a key and value, and export them as environment variables (`$env` and `$version` in this case)[[38]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60bash%20%21bash%20,value%3D%22%24%7Bpair%23%2A%3D%7D%22%20export%20%22%24key%22%3D%22%24value%22%20done)[[39]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=if%20%5B%20,exit%201%3B%20fi). After this, you can use `$env` and `$version` in subsequent shell commands or even in the AI prompt text. By doing the parsing in `!bash`, you ensure it’s deterministic and not left to the model’s guesswork.

Claude now effectively has named parameters to work with, because your command created them. It’s a bit of boilerplate, but you can reuse this pattern in many commands that need flexible input. (In fact, consider abstracting it by having a short command or script that does the parsing, if you use it frequently.)

**Important:** Claude will only parse or split the input if you explicitly tell it how. If you just drop `$ARGUMENTS` into the prompt without explanation, it treats it as a single blob of text[[40]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=). So always make it clear in your prompt if the input has structure. For instance, you might write instructions in the prompt like: *“The user input will contain two paths separated by a space. Split* `$ARGUMENTS` *on the first space into two parts, using the first as source and second as destination.”* – then Claude will follow that. Or use the shell method as above for reliability.

**Using arguments inside prompts:** You can put `$ARGUMENTS` anywhere in the prompt content where you need that user input. It could be in a shell command (`!bash tailwindcss -i $ARGUMENTS -o out.css` – which runs a tool on the given input file[[41]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60bash%20%21bash%20tailwindcss%20,css)), or in prose (e.g. “Please analyze the text: `$ARGUMENTS`”). Claude will substitute the literal text provided when the command runs[[41]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60bash%20%21bash%20tailwindcss%20,css). This makes commands like templates with fill-in-the-blank.

**Advanced patterns: Argument forwarding and processing** – In agent commands, you might accept an argument and then **forward** it to sub-commands. For example, if `/workflow:design:init` takes a project path as argument, internally it may call `/workflow:design:generate-theme $ARGUMENTS` and then `/workflow:design:lint $ARGUMENTS`[[42]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Agent%20commands%20can%20forward%20,to%20actions), so that the sub-actions each get the same project path as their input. This means your actions should be designed to handle the argument appropriately (one might expect a directory path to generate theme for, the other to lint that directory). Ensure consistency in how the argument is interpreted at each step, or do any necessary transformation before passing it along.

**Dynamic inputs with lists or multiple values** – If you expect a list of items, decide on a delimiter and document it in the `argument-hint`. For example, `"files (space-separated)"` or `"modes (comma-separated list)"`. Then handle it accordingly. In some cases, you might even allow different formats – for instance, the command could detect if there’s an `=` in the input to decide if it should use key-value parsing or treat it as a single string. But that can add complexity – often it’s better to keep each command’s expected format simple and clear.

**Best practices for arguments:**

-   Use `argument-hint` to guide users on input format[[43]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Add%20the%20%60argument,to%20describe%20the%20expected%20input).
-   If the argument is meant to be a file or folder, consider using tab-completion (if your environment supports it) to avoid typos. Claude Code often can auto-complete file paths when you start typing after a slash command.
-   Always validate critical inputs. If your command *requires* something (like the `env` and `version` example above), include checks and fail early with a clear message if they’re missing or malformed. This prevents the AI from proceeding in a confused state.
-   Where possible, offload parsing to deterministic shell or code (as shown) rather than asking Claude to parse purely in natural language. This avoids misinterpretation and makes the command outcome more reliable.
-   If a command needs many different inputs, consider whether it should be broken into multiple commands (with an agent coordinating), or whether an interactive approach might be better (Claude asking the user for inputs step by step). Remember, slash commands are one-shot by design – they run from start to finish with the given input, no back-and-forth unless you explicitly script such interaction.

By handling arguments carefully, you enable your slash commands to be dynamic and adaptable, which is essential for covering real-world use cases where each run may operate on different targets or parameters.

## Embedding Shell Logic for Deterministic Execution

One of the most powerful features of Claude Code is the ability to embed actual **shell commands or scripts** inside your prompt via the `!bash` tool (and similarly, to read and write files with `!Read`/`!Write`). This allows you to carry out concrete operations as part of the AI's workflow. The benefit is twofold: you get **deterministic execution** of certain steps, and you free the AI from having to "imagine" the result of things that a computer can just do.

**Why embed shell commands?** Because you want to use the right tool for the job: - Use natural language instructions to harness Claude’s reasoning, creativity, and understanding. - Use shell/CLI commands to handle exact, repetitive, or computational tasks (like running tests, formatting code, querying a database, etc.) where you need a reliable result[[44]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI).

For example, if your command involves checking code formatting, you could have Claude *describe* how to format code – but it’s much more reliable to just call your formatter (e.g. run `prettier` or `eslint`) via `!bash` and let Claude incorporate the output or confirm success. Similarly, if you need to retrieve data from a file, using `!Read file.txt` ensures you get the actual file content rather than relying on Claude’s memory or a possibly outdated summary of it.

**How to use** `!bash` **in commands:** Inside your command’s Markdown, you can include a fenced code block that begins with `!bash`. For example:

```
Please run the tests to ensure nothing is broken.

```bash
!bash npm run test
When Claude executes this command, it will recognize the `!bash` directive and actually run `npm run test` in a sandboxed shell environment (with the permissions allowed). The output of that command (e.g. test results) will be captured and can be used by Claude in the conversation/log. Essentially, the AI pauses, the command runs, and the results are inserted back into Claude’s context so it can decide the next steps or report the results. This makes your workflow far more **deterministic and reproducible**.

**Example – Embedding a script snippet:** In the previous section, we showed a shell snippet to parse key=value arguments. We used a heredoc syntax (`<<'EOF' ... EOF`) inside `!bash` to run a multi-line script. That `'EOF'` (quoted EOF) is important – it tells Claude **not** to try to substitute variables or interpret content within; it passes the raw script to the shell. This prevents the AI or the environment from messing with your script (for example, trying to replace `$env` with something before the script runs)[45]. Always use a quoted heredoc if your script is more than one line or contains special characters, to ensure it runs exactly as written. 

**Make shell actions safe and clear:**
- Always **quote your variables** in shell scripts (`"$var"`), especially when they come from `$ARGUMENTS`. This prevents word-splitting issues or globbing surprises[45].
- Avoid using dangerous shell constructs like `eval` with untrusted input[46]. In most cases, you can achieve what you need with explicit parsing (as we did) rather than eval.
- If the command could be destructive (e.g. it has power to delete files), build in confirmations or checks. But as a rule of thumb, **do not include truly destructive commands** in your slash commands, especially not as something that could run automatically. For instance, a slash command should never run `rm -rf /` or drop a production database unless a human explicitly intends it. Keep the automations safe by design.
- Use `allowed-tools` in frontmatter to **limit what each command can do**. For example, if your command only needs to run a local script and maybe read a file, it shouldn’t have internet or broader system access. By listing only `"Bash","Read"` as allowed tools, you ensure that even if the AI tried to do something else, the system wouldn’t permit it[47].
- Consider output formatting: when a shell command produces output, think about how Claude should use it. Often, you’ll follow a `!bash` block with instructions like “If tests failed, show the failures and suggest fixes” or “Output the result above and then continue.” Be explicit so Claude knows what to do with the result. If the output is large, you might summarize or filter it.

**Combining AI reasoning with shell results:** A great pattern is to have Claude plan or reason about the task, then confirm steps by running shell commands:
1. *Prompt Claude to outline a solution approach (pure reasoning).*
2. *Have Claude execute a `!bash` command to perform a step or gather data.*
3. *Use the result to decide the next step (the prompt can instruct how to evaluate the shell output).*
4. *Repeat as needed.*

For example, your command might say: “Think through the steps needed to migrate the database. List the SQL changes you expect to make. **Then** run the migration script to apply changes. **After execution, check** the script’s output for errors and verify success.” This way, you engage Claude’s reasoning (“think through the steps”) but also ensure the actual migration is done via script (not just imaginary). Always explicitly prompt Claude to reason or verify if needed – e.g., phrases like "Reflect on the desired output before proceeding" or "Review the plan before executing" can nudge the model to double-check itself[48].

**Example of blending logic:**

```markdown
1. Plan the changes needed for the API update.
2. Use the build tool to compile the project:
```bash
!bash npm run build
```

3\. If the build fails, analyze the errors and suggest fixes. 4. If the build succeeds, output a confirmation message.

```
Here, step 1 is AI reasoning (Claude will list the changes or plan them). Step 2 runs the actual build. Steps 3 and 4 tell Claude how to proceed depending on the deterministic outcome. This merges flexible reasoning with concrete actions, leading to a robust command.

**Keep prompts for reasoning, not heavy logic.** A key mantra is: *Let Claude handle the “why” and “what,” but let code/commands handle the “how” where possible.* Use your prompts to describe logic, ask Claude to make decisions, or format output, **but do not rely on the AI for things better done by code** (like sorting a list or calculating a value)[49]. If you need to do a complex calculation or transform data, consider calling a script or using a programming snippet in a `!bash` block. This ensures correctness and saves token space.

By embedding shell logic smartly, your slash commands become far more **reliable and deterministic**. They harness the best of both worlds: the intelligence of the AI and the precision of actual code. As you design commands, continually ask, “Can a tool do this more deterministically?” If yes, use `!bash`/`!read`/etc., and let Claude focus on the creative and analytical parts around those results.

## Accessing Files and Context with Claude

Many operational workflows involve reading from or writing to files, or referencing existing project context. Claude Code provides mechanisms to safely access files and incorporate their content into the prompt context using the **Model Context Protocol (MCP)** and built-in tools.

**Resource references (`@resource:path`):** In your command prompts, you can refer to files by using the `@` notation. For example, writing `@src/utils/helpers.py` in the prompt signals to Claude that it should fetch the content of that file (if accessible) and consider it. These references are **fuzzy-searchable** and dynamic – meaning you don’t have to copy-paste code into your prompt; Claude will retrieve the latest content when needed[50]. This keeps your commands up-to-date with your codebase. You can use local file paths (for project files) or even remote references like `@github:owner/repo/path/to/file.ts` if you have an MCP GitHub integration configured[51].

For instance, an action command might say: *"Open the file @models/user.py and add the following function..."* or *"Check for any TODO comments by scanning @ for 'TODO'"*. Claude will resolve that reference and load the file content behind the scenes[52]. The result: you didn’t need to stuff the file text in your prompt; the system pulled it in when Claude needed it, courtesy of MCP.

**Using `!Read` and `!Write`:** Along with passive references, you have active commands:
- `!Read "<filepath>"`: explicitly fetches and prints the content of a file. This can be useful if you want the file’s content to show up in Claude’s working context or logs. For example, after some operation you might do `!Read "output.txt"` to show the results.
- `!Write "<filepath>" <<'EOF' ...`: writes content to a file. This is used to have Claude’s modifications or generated content saved back to your project files. Often, you will have Claude propose some changes and then use `!Write` to apply them.
- There are also variations like `!TodoWrite` which might stage changes (depending on environment) or interact with a to-do list, but the key ones are read/write.

These tools integrate with MCP and Claude’s sandbox. For example, if Claude has `allowed-tools: ["Read","Write"]` for a command, it can use those to actually edit your codebase in a controlled way[47].

**Context scoping and tab completion:** When referencing files, it’s best practice to be specific and use tab completion if available. In Claude’s interface, when you type `@` and start writing a path, it can often auto-complete existing filenames. This not only avoids typos but also ensures Claude can actually access the correct file[53]. For instance, typing `@src/uti` and pressing tab might complete to `@src/utils/helpers.py`. In your prompt text, that might appear as a link. Claude will then know exactly which file you mean. If you just said "open the utils file", the AI might not pick the right one – hence using explicit `@path` syntax is highly encouraged for **deterministic context**.

**Using `.claude/memory.md`:** In addition to code and data files, there’s a concept of a **memory file** for your project. If you create a file at `.claude/memory.md`, Claude will treat it as a persistent knowledge base for the project[54]. You can put project-specific information there: architecture notes, API keys (be cautious with secrets though), style guides, a glossary of terms, team contacts, etc. This memory file is automatically loaded into Claude’s context (usually in system instructions), meaning every command has access to it. This prevents you from repeating the same background info in every prompt and can guide the AI with project norms and facts. For example, memory.md might list: “Framework = Django 4.0, Primary language = Python, Code style = PEP8, Product name = MyApp,” etc. Then when you ask Claude to create a new module, it already knows those details.

Using memory wisely can greatly enhance the consistency of your agent's outputs. It’s like giving the AI a reference manual it always keeps open. Just keep it concise and relevant – memory isn’t infinite, and overly verbose memory files could consume the context budget needlessly[55].

**Example – Access and modify a file:** Suppose you have a command `/refactor:model` that should open a model file and apply some changes. The command content might be:
```markdown
Open the file @models/user.py and refactor the User class:
- Rename the method `full_name` to `get_full_name`
- Add error handling to `save()`.

After changes, format the file and show the diff.
```

Claude will retrieve `models/user.py` (via MCP) and include its content in context. It will then follow the instructions, likely by using the content and applying changes. The command might further include:

```
!Write "models/user.py" <<'EOF'
<updated file content here>
EOF

!bash black models/user.py
```

to write the changes and run a formatter (Black) on it. This way, the actual file is edited deterministically and formatted. Finally, it might use `!Read "models/user.py"` to show the final content or a diff generation step. All these ensure the file access and changes are concrete and not just mentioned abstractly.

**MCP Integration:** To use such features, make sure your Claude environment is configured with the appropriate MCP servers: - For local filesystem access, Claude Desktop or your Claude setup might run a local MCP server that grants safe file read/write and shell access[[7]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,or%20run%20local%20commands%20securely). - If you want to connect to external resources (like a database or remote API), you can set up an MCP endpoint for those. For example, an MCP server might expose a database connection so that when Claude sees `@postgres:mydb://SELECT * FROM users`, it knows to query that database. We’ll discuss more on MCP in the next section.

**Scope of access:** Always keep security in mind. Claude should only access what you allow. Use `allowed-tools` to restrict commands. If a command is only meant to read project files but not modify them, don’t include `Write` in allowed-tools[[47]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20%2A%2AUse%20built,). If it shouldn’t run arbitrary shell commands, omit `Bash`. This way even if the AI misinterprets or someone tries to misuse a command, the environment will prevent unauthorized operations.

In summary, **Claude Code commands can tap directly into your project’s context** – reading files, writing updates, running tools – through MCP and the special `@` references. This makes your AI truly integrated with your environment, not just a detached assistant. Use these capabilities to give your commands the information they need (like feeding in code or data on which to operate) and to effect real changes (like editing files as a result of the AI’s work). Just do so in a controlled, explicit manner for safety and clarity.

## Leveraging MCP (Model Context Protocol) for External Tooling

We’ve mentioned MCP a few times – let’s dive a bit deeper. **Model Context Protocol (MCP)** is a framework that allows Claude (or other AI assistants) to interface with external tools and data in a structured way. It’s like a bridge between the AI’s natural language world and the external world of files, databases, web services, etc., all mediated through defined protocols.

In practical terms, MCP lets you configure **“resource servers”** that Claude can communicate with. Each server can handle certain schemes or resource types. For example: - A file system MCP server that handles requests to `file://` paths (this might be built into Claude Desktop for local files). - A GitHub MCP server for `@github:` references, allowing read (and maybe write) access to your repos. - A database MCP server for something like `@postgres:mydb://...` queries. - A web API MCP server for fetching from certain websites or endpoints (if allowed).

When you use a reference like `@resource:...`, Claude delegates that to the appropriate MCP connection, which returns data or performs actions. This is more secure and structured than letting the AI call arbitrary APIs on its own.

**Setting up MCP:** Typically, you have a JSON configuration file where you specify the MCP servers and their connection info, then you start Claude with `--mcp-config path/to/config.json`. For example, you might configure a local server for files and a GitHub server with an API token. On Claude Desktop or cloud environments, some default MCP connections may exist (like local file access). The key is you control what tools are exposed.

Once configured, you can do things like: - In your prompt: “Fetch the user data from @postgres:reports_db://SELECT \* FROM users LIMIT 10” – Claude will recognize the `@postgres:` scheme and ask the MCP server for database `reports_db` to run that query, then return the results to the prompt. - Or use `!bash` combined with MCP: e.g., `!bash curl @secretmanager:prod/API_KEY` if you had a secret manager integration (this is hypothetical).

**Best practices when using MCP in commands:** - **Be explicit with resource usage**: Use the `@resource` syntax instead of vague references. This ensures Claude knows to invoke MCP. For instance, prefer `@docs/requirements.txt` over “the requirements file” so that it actually fetches it[[15]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20,read%2Fwrite%20network). - **Constrain with allowed-tools**: If a command uses MCP-heavy operations, ensure only the needed operations are allowed (e.g. `Read` for retrieving data, or maybe a custom tool for a database if needed). This is partly a security measure and partly documentation of intent[[56]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20%2A%2AUse%20built,). - **Log and trace**: It can be useful for an agent command to log what external actions it’s taking for transparency. For instance, an agent might output `\[db:query][ACTION] → Retrieved 100 rows from users table` after an MCP database call, which you could include as a logging step. - **Security considerations**: Realize that giving an AI access to external systems (even through MCP) carries risk. Anthropic has identified risks like tool spoofing (the AI might try to call a tool that’s not exactly what you intended), or the AI might retrieve sensitive info it shouldn’t[[57]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20access%20control). Mitigation includes: - Authentication: MCP servers should require proper credentials so only authorized queries succeed. - Sandboxing: e.g., a file server should maybe restrict access to only your project directory, not entire disk. - Auditing: Keep logs of MCP calls, so you can review what the AI accessed or did. - Using guardrails or an approval step for very sensitive operations. - Using frameworks or tools like “MCP Guardian” which was mentioned as a concept for access control policies[[57]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20access%20control).

-   **Use cases unlocked by MCP**: With MCP, your slash commands can become extremely powerful:
-   **Cross-repository coordination**: e.g. a command that opens issues on GitHub or creates PRs by writing to an MCP Git server (if permitted).
-   **Data science workflows**: pulling data from a database or data warehouse to analyze, then writing results out.
-   **Local system administration**: controlling local applications or reading system logs to troubleshoot (if you expose those via MCP).
-   **Chaining tools**: perhaps an agent that performs a sequence like running a local script, then fetching a web API, then updating a wiki – all via different MCP endpoints, orchestrated in one command.

For example, an “incident report” command might: use `@aws:cloudwatch://GetMetrics...` to fetch metrics, use `@file://logs/error.log` to read a log file, then have Claude analyze them and compile a summary, all in one go. The MCP connections to AWS and file system make the raw data accessible[[58]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,%2C%20%2C).

-   **Connecting remote systems**: You might have to run an MCP gateway on your machine or server for certain tasks. For instance, if you want Claude to run Docker commands, you could run a local HTTP server that accepts certain requests (like run a Docker container) and expose it to Claude as an MCP tool (though this is advanced and caution is needed).

The main point: **MCP extends Claude’s reach beyond the chatbox into your real tools and data** in a controlled manner. It turns slash commands into more than just prompt macros; they become a way to integrate AI with your toolchain.

When designing commands, think about what external data or actions would improve the workflow: - Do you need to pull the latest metrics? Use MCP to get them rather than relying on stale info. - Need to cross-check something from a knowledge base? Use an MCP connector to query it. - Want to enforce that all code mods go through version control? Perhaps use an MCP Git write to commit changes rather than writing directly to files.

Each integration will have its setup overhead, but once in place, your commands can leverage them seamlessly.

Finally, be mindful of **performance**: each MCP call might add latency (e.g., hitting a database could slow the command). Use them judiciously and perhaps batch operations when possible (for example, one SQL query that gets all needed data, instead of 10 small queries).

In conclusion, MCP is your gateway to making Claude a true **AI operator** in your environment – connecting to systems, running real operations, and bringing back results. Used wisely, it can automate complex multi-system workflows with a single slash command, truly streamlining AgenticOps processes.

## Agentic Design Patterns and Use Cases

With the building blocks established (commands, agents/actions, arguments, shell integration, MCP), let's discuss how to put them together into effective **AgenticOps workflows**. Here are some design patterns and real-world use cases to inspire you:

### 1. **Orchestrator Agent with Sequential Tasks**

**Pattern:** An agent command that breaks a complex workflow into a sequence of action commands, executing each in order and handling the flow logic.

**Use case:** *Design System Initialization* – e.g. a `/workflow:design:init` agent: - **Step 1:** Call `/workflow:design:generate-theme $ARGUMENTS` to generate design tokens (colors, typography) from a source (perhaps a brand spec or default). - **Step 2:** Then call `/workflow:design:lint $ARGUMENTS` to run a style lint on the project and catch any inconsistencies. - **Step 3:** If lint finds issues, maybe prompt the user or auto-fix them (could call another action like `/workflow:design:apply-fixes`). - **Step 4:** Finally, run a verification test suite (perhaps via a shell command or an action `/workflow:design:test`) to ensure everything passes.

The agent `/workflow:design:init` orchestrates these. It might pass the same argument (project path) to each subcommand[[42]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Agent%20commands%20can%20forward%20,to%20actions). It also decides what to do based on outcomes (e.g., if lint returns issues, fail or attempt fixes, etc.). This pattern is essentially a **pipeline** – one thing after another. Each action focuses on its task, and the agent is the glue.

**Benefit:** Clear separation – if the theme generation logic changes, you only update `/workflow:design:generate-theme`. If you want to add a new step (say accessibility audit), you slip in a new action call. The agent ensures all needed steps run to achieve the high-level goal.

### 2. **Master-Agent and Sub-Agent Hierarchy**

**Pattern:** A top-level agent delegates to other agents, forming a hierarchy of responsibilities. This is useful in large, multi-faceted processes.

**Use case:** *Software Release Process* – Consider a master command `/release:publish` which covers everything from building to deployment: - It first calls an agent `/release:prepare` that might handle building the code, running tests, collecting artifacts. - Next, it calls an agent `/release:deploy` that handles pushing those artifacts to environments (which itself might call actions like `/deploy:kubernetes` or `/deploy:rollback` if needed). - Then maybe a `/release:notify` action to announce the release, etc.

Here, `/release:prepare` and `/release:deploy` could themselves be agent commands (with their own sub-steps). The master `/release:publish` just sequences those major phases. Each sub-agent could be maintained by different teams (e.g., QA team writes the prepare agent, DevOps team writes the deploy agent). This pattern mirrors a company’s structure in some ways – specialized agents for specialized departments, with a higher-level agent integrating them.

**Benefit:** **Modularity and parallel development.** Each agent can be developed and tested in isolation. Also, each sub-agent can have its own context window and tools[[23]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%E2%80%99s%20slash%20command%20system%20and,window%20for%20clarity%20and%20performance), which means, for example, the test-running agent can load a lot of test context, then flush and the deploy agent loads deployment context, without mixing them in one giant prompt.

### 3. **Interactive Agent (Human-in-the-loop)**

**Pattern:** An agent that pauses to ask the user for guidance or confirmation mid-way. This is more of a prompt strategy pattern, useful when some decisions can’t be fully automated.

**Use case:** *Architecture Decision Assistant* – A command like `/project:scaffold` that sets up a new project structure. Steps might include: - Ask the user (or project owner) a few questions: preferred language, use of database, target cloud provider, etc. The command can output these questions one by one and wait (depending on Claude’s interface capabilities, you might need to break it into multiple commands or simulate the Q&A in one prompt). - Based on answers, call relevant actions: e.g. `/project:init-django` or `/project:init-node` depending on language choice. - Then proceed with setting up environment config, and finally prompt user to review generated structure.

This pattern acknowledges that not everything should be blindly automated – sometimes human judgment is needed. To implement it in a single slash command prompt, you have to script a sort of internal Q&A. (In practice, Claude Code might not have an actual "pause and wait for answer" mechanism within one command; you might instead instruct it to output a question and then the user would answer by running the command again with the answer, or simply use separate specialized commands. But conceptually, it’s a design pattern to consider: breakpoint for human input.)

**Benefit:** **Safety and customization.** By involving a person at critical junctures, you avoid the AI making assumptions it shouldn’t. It also makes the command more flexible for scenarios where requirements vary.

### 4. **Watcher/Enforcer Agent**

**Pattern:** An agent that continuously or periodically runs to enforce certain rules or check for anomalies, using memory or hooks.

**Use case:** *Coding Standards Enforcement* – A `/code:lint-all` agent that might run on every git push (wired via a hook in `.claude/settings.json`) to ensure code style compliance: - It scans the repository (maybe splits by directories) using an action like `/code:lint $ARGUMENTS` on each module. - Aggregates the results. - Automatically creates a report or even fixes trivial issues with another command.

This could be set up via an **automation hook** so that it triggers without manual intervention (more on hooks soon). It essentially acts as a guardian agent that always runs to keep things in line.

Another example: a **monitoring agent** that checks system metrics or logs every hour via MCP calls and sends an alert (maybe integrating with email or chat via another command).

**Benefit:** **Continuous assurance.** The agent pattern here is like a cron job managed by AI – ensuring certain conditions remain true or tasks repeat. It offloads routine checks from humans to the AI.

### 5. **Multi-Modal Agent**

**Pattern:** An agent that uses different modes or contexts for different stages of a task, possibly by switching tools or roles mid-execution.

**Use case:** *Incident Response* – A complex scenario where the agent must: - Retrieve logs (requires reading large text, analyzing). - Summarize errors (pure reasoning on text). - Run a diagnostic script (shell command to gather system state). - Ask an external API for known issues (MCP web call). - Finally, compile a report.

This single agent is using different modalities: file reading, data analysis, external knowledge, and writing output. It might internally toggle between an “analysis mode” and an “action mode.” In practice, this can be done by structuring the prompt into sections or simply by sequential steps that use the appropriate tool at each point. The design pattern here is ensuring the agent remains focused by one sub-task at a time despite the varied nature of the job.

**Benefit:** **End-to-end automation of complex tasks.** The user triggers one command and gets a full multi-step outcome that would normally require gluing several tools and scripts together.

### Real-World Correspondence and Use Cases

To ground this in reality, consider some actual use cases you might implement with AgenticOps slash commands:

-   **Onboarding a New Service**: An agent that creates a boilerplate for a new microservice – sets up directories, populates config files, calls actions to create CI/CD pipeline files, etc. It could use templates (perhaps stored in a `.claude/templates/` or pulled via MCP from a template repo) and finalize with a test run.
-   **Data Pipeline Orchestration**: Agents that handle data ETL jobs. For instance, `/data:refresh-dataset` that calls actions to extract data (`/data:extract`), transform it (`/data:transform`), load it (`/data:load`) into a database, and then verify counts (`/data:verify`). Each step could involve real tools (SQL queries, Python scripts) invoked via shell or MCP, with Claude summarizing or adjusting parameters.
-   **Incident Triage**: A command like `/ops:triage-incident "$ARGUMENTS"` where the argument might be an incident ID or description. The agent could fetch relevant logs and metrics (MCP calls), run a diagnostic action, and then provide a summary of likely causes and next steps. Essentially acting like a Tier 1 support engineer.
-   **Code Review Assistant**: An agent that, given a PR URL or diff, will check out the branch (via MCP Git), run static analysis (`!bash` to run linters/tests), maybe compare it to coding standards (with an action), and then produce a review report (possibly even opening comments via GitHub API). This automates a lot of the mundane checks in code review so human reviewers can focus on logic.
-   **Knowledge Base Q&A**: For internal use, a slash command that answers questions by searching documentation. The command might take a query, use an MCP search on a docs repository or internal wiki, then have Claude summarize the findings. This is like a custom chatbot that knows your company's data. (One must ensure the memory or data access is properly set up and secure.)

The **agentic design philosophy** is: identify a workflow (especially those that span multiple steps or roles), break it into logical pieces (perhaps some already done manually or via scripts), then implement an AI agent to coordinate those pieces with minimal human intervention needed. Start with simpler cases to build trust, then expand to more complex or critical workflows as the system proves reliable[[59]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%8C%B1%20Start%20Simple%20,Refine%20through%20use%20before%20generalizing).

Remember, Anthropic’s own design of Claude encourages the use of **sub-agents** and hierarchical delegation[[23]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%E2%80%99s%20slash%20command%20system%20and,window%20for%20clarity%20and%20performance). By mirroring that, you utilize the AI’s strengths (managing context and sub-tasks) while respecting its limits (keeping each context focused). Over time, you’ll accumulate a library of actions and agents that handle the common scenarios in your operations – essentially encoding your organization’s “playbooks” into AI-executable form.

## Building and Structuring a Slash Command Library

As you develop more commands, it's important to structure and manage them like a proper codebase. Here are guidelines for building a maintainable slash command library:

**1. Organize with Namespaces (Folders):** Group related commands under folder namespaces for clarity[[60]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%93%81%20Organize%20with%20Folders%20and,project%3Acreate). For example: - `design/` for design-related commands (`design:init`, `design:lint`, `design:generate-theme`). - `dev/` for development tasks (`dev:test`, `dev:fixbug`, `dev:refactor`). - `data/` for data engineering or analysis commands (`data:query`, `data:clean`). - `project/` or `ops/` for project management or operational tasks (`project:create`, `ops:deploy`).

This way, commands read like `namespace:action` which is self-explanatory. It also prevents name collisions (you might have `deploy` in both `service:` and `data:` contexts doing different things, which is fine when namespaced).

**2. Descriptive Naming:** Name commands with clear verbs and nouns that indicate exactly what they do[[11]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%BE%20Use%20Descriptive%2C%20Intuitive%20Names,data%3Amigrate). Good names help discoverability. For instance, `lint` is okay, but `design:lint` is better if it's specific to design files. Similarly, prefer names like `update-dependencies` over something generic like `maintain` – the former tells you the outcome (dependencies updated).

**3. Start Simple and Specific:** Especially at the beginning, create narrowly scoped commands that solve a particular problem[[61]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%8C%B1%20Start%20Simple%20,Refine%20through%20use%20before%20generalizing). This allows you to test usage patterns and refine the approach. For example, instead of trying to build a single `build-project` command that handles every build scenario, start with a `build:docker-image` action that builds a Docker image given a path. Once it's working, you might integrate it into a larger agent or extend it to more use cases. Evolve commands iteratively based on real usage and feedback.

**4. Write Clear, Step-by-Step Prompts:** Within each command, break down the prompt into logical sections or steps[[62]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A0%20Break%20Prompts%20Into%20Steps,ended%20guidance). Use bullet points or numbered lists if appropriate to guide the AI through a sequence. If something is implicit, make it explicit. For example, instead of a vague instruction like "Optimize this code", say: - "Analyze the code for any inefficiencies. - Suggest specific changes to improve performance. - Apply the changes using `!Write` and then run the tests to verify improvement." Each bullet instructs a concrete step, leaving less room for confusion.

**5. Use Template Structure for Consistency:** It helps to have a standard structure for command content so that anyone writing a command in the team follows a similar format. The AgenticOps team, for instance, defined a **Slash Command Template Standard** that includes sections like: - **🎯 Objective:** A brief statement of what the command should accomplish[[63]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=1.%20%F0%9F%8E%AF%20Objective%20,to%20do%2C%20in%20one%20sentence). - **🛠️ Preconditions:** What needs to be true or available before running (e.g., "Requires an internet connection" or "Make sure `aws-cli` is installed"). - **📦 Dependencies:** External tools or libraries used (and their versions, if relevant)[[64]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,project%20state). - **📋 Implementation Plan:** Outline of steps the command will perform[[65]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=4.%20%F0%9F%93%8B%20Implementation%20Plan%20,Include%20shell%20commands%20if%20relevant). This often mirrors the actual bullet points/instructions the AI will follow. - **✅ Completion Criteria:** How do we know the command succeeded? E.g., "Build passes with 0 errors", or "File X is created", or "No TODOs remain"[[66]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=5.%20%E2%9C%85%20Completion%20Criteria%20,Output%3F%20File%20state%3F%20Git%20status). - **🧪 Final Test:** A quick way to verify the outcome, possibly an automated check or a command to run after to confirm setup[[67]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,describe%20to%20verify%20setup%20worked). - **📎 Rules & Guidelines:** Any specific rules the AI should keep in mind (coding standards, business rules). - **🔄 Updatability:** Notes on what might need changing when environment changes (e.g., if a library updates, or an API deprecates, which parts of the command to update).

You don’t always need every section, but including an **Objective** at top and **Completion Criteria** at minimum is very helpful (it frames the task and defines done). You can format these as comments or blockquotes in the prompt so Claude reads them but they don't appear in final output. For example:

```
### 🎯 Objective
> Set up a new React component with a given name and basic boilerplate.

### 📋 Implementation Plan
> 1. Create a new file in `src/components/` named `$ARGUMENTS.jsx`.
> 2. Write a functional React component skeleton in that file.
> 3. Export the component.
> 4. Update `src/components/index.js` to export this new component.

### ✅ Completion Criteria
> - A file `src/components/$ARGUMENTS.jsx` exists with a React component defined.
> - `src/components/index.js` has an export for the new component.
> - No ESLint errors in the project.
```

Then the actual instructions might follow (some of which likely mirror the plan above, potentially combined with `!Write` commands to create/edit files, etc.). The point is consistency: if every command in your repo follows a similar pattern, it’s easier for authors to write and for others to read and understand or modify them.

**6. Store Commands in Version Control:** This was mentioned, but treat your `.claude/commands` directory as you would `src/` code. That means: - Code reviews for new or changed commands (catch prompt issues or security concerns before they hit production). - Proper commit messages describing changes (helpful when someone wonders why a command is doing something, they can check history). - Possibly tests for commands (more on testing later, but you might have sample inputs and expected outputs to validate a command’s behavior). - When you bump versions of tools or change workflows, update the commands accordingly and track that.

**7. Encourage Reusability:** If you find yourself writing very similar prompts in multiple commands, consider abstracting that into a single command that others can call. For example, if several commands need to ensure that `npm install` has been run, you could have an action `/project:ensure-deps` that checks if `node_modules` exists and runs `npm install` if not, logging appropriately. Then all your relevant agents just call `/project:ensure-deps` at the start. This avoids duplicating logic in many prompts, just like you avoid duplicate code by refactoring into a function.

**8. Document Your Library:** Just as you might have a README for a code project, have documentation for your command library: - List available slash commands and short descriptions (so team members know what’s available). - Show example usage of complex commands. - Explain any setup required (like MCP config or environment variables needed). - If you have a lot of commands, consider categorizing them in the doc or even building a help command (like `/help` or `/help:design` to list design commands).

This documentation can live in your repo (`docs/claude-commands.md` or similar) or even within the commands (frontmatter `description` fields and hints often suffice for quick help).

**9. Manage Dependencies and Updates:** Over time, the tools or patterns your commands use will evolve (new versions of linters, changed API endpoints, etc.). Plan for maintenance: - Keep track of external dependencies (maybe in a dedicated section in the repo docs, or a command like `/project:dependencies` that prints versions). - Use version pins in command content where possible (for example, if you're installing a tool via shell, specify the version). - When updates occur, test your commands and update them. You can even automate some of this: the guide references using commands like `/update-dependencies` or `/migrate-dependencies` to systematically update or refactor multiple commands[[68]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,running%20commands). That implies an agent that searches through the `.claude/commands` files and replaces old versions with new, etc. If you have many commands, investing in such meta-commands can save time.

**10. Avoid Overfitting a Command to One-Off Scenarios:** If a command is only ever used for a single very specific case, consider whether it should exist as a general command. Perhaps it belongs as a script or just an interactive one-time query. Every command you maintain has a cost. Aim for commands that will be reused or that encode knowledge worth preserving. If something was extremely one-time, maybe document it in a playbook instead of making a command. Or, if you do make a command for a one-time need (maybe to leverage the AI for that case), later refactor it into a more generic form or integrate it into another agent[[69]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A9%20Focus%20on%20Reusable%2C%20Composable,into%20a%20more%20general%20form)[[70]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A9%20Focus%20on%20Reusable%2C%20Composable,into%20a%20more%20general%20form). For example, you wrote `/project:backfill-db` for a specific incident – later you might generalize it into `/data:backfill <table>` so it’s reusable.

**11. Iterate and Evolve:** Building this library is an ongoing process. After initial creation, regularly **review and refactor** your commands: - Remove or consolidate duplicates. - Rename for clarity if needed. - Archive commands that are no longer useful (you can keep them in a deprecated folder or branch if you worry about needing them later, but removing clutter is good). - Solicit feedback from users of the commands – maybe some prompts are confusing or some tasks still need manual steps that could be automated. - Treat it as a living product: just like software goes through versions, your command library will too. Embrace improvement.

By following these structuring principles, you’ll maintain a **clean, scalable library of slash commands** that integrate well with each other and with your team’s workflows. New team members can quickly find what they need or add new commands without creating chaos. And as your operations grow, your AgenticOps command base can grow alongside in a manageable way.

## Best Practices and Anti-Patterns

In the journey of creating slash commands for AgenticOps, certain patterns emerge as universally good ideas, while others prove problematic. Let’s summarize key best practices to adopt, and highlight some anti-patterns to avoid.

### ✅ Best Practices

-   **Use Clear Namespaces and Naming:** Organize commands by domain and use intuitive names[[11]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%BE%20Use%20Descriptive%2C%20Intuitive%20Names,data%3Amigrate)[[60]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%93%81%20Organize%20with%20Folders%20and,project%3Acreate). E.g. `deploy:service` vs `deploy:database` to distinguish what’s being deployed. Clear naming reduces mistakes and speeds up discovery.
-   **One Command, One Purpose:** Keep each command focused on a single goal or cohesive set of tasks (especially for actions)[[17]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint). This makes it easier to predict what the command will do and to reuse it in different contexts.
-   **Write Step-by-Step Instructions:** Be explicit in prompt steps, and use sequences or lists where appropriate[[62]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A0%20Break%20Prompts%20Into%20Steps,ended%20guidance). Explicit guidance leads to more deterministic outcomes. For example, break a complex refactoring into “1) Identify spots to change, 2) Apply changes with !Write, 3) Run tests, 4) Confirm success.”
-   **Encourage AI Reasoning:** Within a command, prompt Claude to “think” before acting on irreversible steps[[48]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%94%8D%20Prompt%20Claude%20to%20Think,Reflect%20on%20the%20desired%20output). Phrases like "Let's consider the approach..." can be inserted to have Claude formulate a plan internally (it often does this anyway, but a nudge can help). This reduces mistakes where the AI might jump into an action without considering consequences.
-   **Delegate to Code for Deterministic Tasks:** Offload any exact or repetitive work to tools (shell commands, scripts) rather than having the AI freeform it[[44]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI). For instance, use `!bash make build` to compile rather than describing the build process, or `!bash flake8` to lint code rather than expecting the AI to catch every lint issue by itself.
-   **Validate and Verify Outcomes:** Include completion criteria and post-checks in your commands[[66]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=5.%20%E2%9C%85%20Completion%20Criteria%20,Output%3F%20File%20state%3F%20Git%20status). If a command is supposed to produce a file or pass tests, instruct Claude to verify that (and maybe show a snippet of the result or a success message). This way, if something went wrong, the command can catch it (and possibly even handle it, e.g., try a fallback or prompt the user).
-   **Use** `$ARGUMENTS` **Properly:** Use the argument to inject dynamic content and structure your commands to parse it if needed[[71]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=You%20can%20use%20this%20argument,to)[[72]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%23%23%20Patterns%20for%20Multi). Provide `argument-hint` for clarity. Always sanitize or validate the argument if it will be used in critical operations (especially shell commands, to avoid injection issues).
-   **Leverage Memory and Context Files:** Keep large reference info out of your immediate prompt by using `.claude/memory.md` and `@resource` references[[55]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%93%A6%20Limit%20Context%20Bloat%20,for%20persistent%20reference%20info)[[54]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%92%BE%20Memory%20Files%20for%20Persistent,rules%2C%20owners%2C%20or%20directory%20structure). This avoids bloating each command with the same background text. For example, if every design command needs the list of design tokens, put that in memory.md or a file that the commands reference.
-   **Iterative Development:** Start with a minimal version of a command, test it manually, and then refine[[61]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%8C%B1%20Start%20Simple%20,Refine%20through%20use%20before%20generalizing). It’s tempting to write a huge prompt script and assume it will work, but you’ll get better results by building in increments and observing how Claude behaves.
-   **Logging and Commenting:** Have your commands output logs or comments for important milestones (especially agents)[[29]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Log%20Prefixing%3A%20Verbal%20Signaling%20of,Role). Not only does this help you debug, it also can guide the AI – e.g., if you instruct it to output `[ACTION] Completed step X`, that confirms it knows step X is done and can proceed to Y. The logs also help teammates (or you in the future) understand what happened if you review a run.
-   **Keep Commands Short and Focused (re: token usage):** If a command requires an extremely lengthy prompt or output, consider alternatives like splitting into sub-commands or using reference files. Very verbose commands can hit context limits and are harder to maintain[[55]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%93%A6%20Limit%20Context%20Bloat%20,for%20persistent%20reference%20info). Use just enough detail for clarity, but not so much that it overwhelms the model with unnecessary info every time.
-   **Tool Access Hygiene:** Whitelist only the needed tools in `allowed-tools`[[47]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20%2A%2AUse%20built,). This principle cannot be overemphasized for safety. If a command doesn’t need the internet (and most don’t by default), don’t allow a `Network` tool. If it only reads files but never writes, allow `Read` but not `Write`. This confines any AI actions to expected boundaries.
-   **Security Checks:** When writing prompts that perform critical operations, insert checkpoints. For example, if a command manages deployments, you might have a step: “**Confirm** the target environment is correct and safe to deploy. If any doubt, STOP.” Claude will then double-check itself. Additionally, use hooks or external safeguards (like requiring a human review) for truly dangerous tasks.
-   **Consistent Formatting and Style:** Adhere to a uniform style for how you write prompts (e.g., always using certain headings or list markers). This consistency can subtly help the AI follow the pattern and also makes it easier for others to read your commands.
-   **Test Your Commands**: Develop a habit of running commands in a test environment or with dry-run modes if possible. Some commands can have a `--dry-run` flag in their logic (for instance, not actually writing files but showing what they *would* do), which you can trigger via an argument. Or maintain a set of sample scenarios (inputs) to try after changes. This ensures changes haven’t broken expected behavior.

### 🚫 Anti-Patterns to Avoid

-   **Ambiguous Commands:** Avoid commands that are too general or vague in purpose. For example, a command named `/do-all-the-things` is a bad idea. If it tries to cover too much, it will be hard to predict or might do unintended stuff. Each command should have a clear contract of what it does (this is where description and naming help).
-   **Overloading One Command:** Don’t cram multiple unrelated operations into one command “because you can.” For instance, a single command that builds code *and then* also posts to Twitter with release notes – break that into separate commands (one for build, one for posting, possibly orchestrated by an agent if needed). Overloaded commands are hard to maintain and secure.
-   **Letting AI “Wing It” for Precise Tasks:** An anti-pattern is to have the AI do something like *“Sort the following list alphabetically”* or *“Remove duplicates from this data”* using just reasoning. While it might manage small cases, it’s error-prone for larger or critical data. Use deterministic methods (like a small Python script via `!bash python -c "..."`) for such tasks. In general, **don’t rely on the AI for accuracy in areas where algorithms or tools are known to excel** (math, sorting, exhaustive searching, etc.) – use those algorithms/tools directly.
-   **Ignoring Errors or Edge Cases:** If a command might encounter errors (a file not found, a test failing, a network timeout), an anti-pattern is to ignore that possibility. Always assume the path might not be perfectly smooth. Incorporate error handling or at least error detection. E.g., if a `!bash` command returns a non-zero exit code (failure), have the next prompt step check that and handle it (Claude’s awareness of exit codes depends on implementation; you might need to catch error output or design the script to echo a sentinel on success). Writing commands that only work on the “happy path” without any checks can lead to confusion when something goes wrong.
-   **Hardcoding Sensitive Data:** Never hardcode passwords, API keys, or sensitive info in command prompts. That’s both a security risk and could accidentally leak if the output is shown. Instead, rely on MCP for secure retrieval of secrets (e.g., `@vault:secret-name`) or prompt the user to input them at runtime if needed (so they’re not stored in code).
-   **Destructive Actions Without Confirmation:** In general, do not let a command immediately perform a destructive operation (like deleting data, dropping a database, etc.) without some safeguard. Even if you *think* it’s safe (because you as the author know what you’re doing), consider future maintainers or an AI misinterpreting context. For example, writing a command that says `!bash rm -rf $ARGUMENTS` to delete a directory given by user input is very dangerous. If used wrong, it could wipe something important. If you absolutely need deletion, code in confirmations or safety checks (like require a specific keyword in the argument such as “CONFIRM DELETE /path”). A hook that runs automatically should **never** include something like this[[73]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,or%20anything%20destructive%20without%20validation).
-   **Lack of Tool Scope (Allowing Everything):** Marking `allowed-tools: ["*"]` or just broadly including tools you don’t need is risky. It’s an anti-pattern because you’re effectively disabling a key safety feature. Be deliberate and minimalistic in tool allowances. For instance, if a command doesn’t need `Bash`, don’t list it, because then even if the AI’s instruction tries to do a shell action, it will be blocked – which is what you want if it wasn’t intended.
-   **Cluttered or Noisy Commands:** If a command prints an excessive amount of intermediate data or dumps large contents blindly, it can overwhelm users or the model. E.g., a command that reads 1000 lines of logs and prints them in entirety for analysis may exceed context or just be unhelpful. A better approach is to have the AI summarize or filter. Avoid prompts that produce more output than needed for the decision at hand (this is more of an efficiency anti-pattern).
-   **Duplicated Logic Across Commands:** Copy-pasting the same prompt snippet in multiple places means when something changes, you’ll forget to update one of them. It also increases token usage and chance of divergence in behavior. Abstract repeated logic either into a single command or into a common resource. For example, if multiple commands need to ensure a user is logged in, perhaps have a small command `/user:check-login` that each agent can call at start, instead of writing those steps in each prompt.
-   **Treating AI as Magic**: It's an anti-pattern to trust Claude to handle something complex without proper guidance just because "the AI is smart." Always assume the AI is a junior assistant: it needs clear instructions, structure, and oversight (through tests/logs). If you ever find yourself writing a prompt like "Do X in the best way" as the only instruction, step back and add more structure. Otherwise, results will be inconsistent.

By following the best practices and steering clear of these anti-patterns, you increase the reliability and longevity of your command library. The goal is to make these commands robust (working correctly with minimal surprises) and maintainable (easy to update and reason about). In essence, treat prompt programming with the same rigor as software programming – design, readability, testing, and safety are key.

## Sample Templates and Walkthroughs

Let's cement these concepts with concrete examples. In this section, we’ll walk through sample command templates – one simple action and one more complex agent – to illustrate how all the pieces come together.

### Example 1: A Simple Action Command

Suppose we want a command to **format all code files in a project**. We'll create an action command `/code:format` that runs a formatter (say, Prettier for JS/TS or Black for Python, etc.) and reports the result.

**File:** `.claude/commands/code/format.md` → Command `/code:format`

**Frontmatter:**

```
---
description: Format all source files in the project using standard formatters
command-type: action
argument-hint: optional path or file pattern to format (defaults to whole project)
allowed-tools: ["Bash"]  # will run formatter commands
---
```

-   We mark it as an `action` because it’s a deterministic task. We only allow `Bash` since we plan to call external formatting tools; we don’t need read/write separately because the formatter itself will handle modifications in place (alternatively, we might allow `Read` to confirm file contents, but let's keep it simple).

**Prompt Content (Markdown):**

```
# 📦 Code Formatter

**Objective:** Format the codebase (or specified part) according to coding standards.

**Steps:**
1. If an `$ARGUMENTS` path is provided, target that; otherwise target the entire project.
2. Run the appropriate formatting tools for the project.
3. Report what files were changed, if any.

### 🛠️ Detect Project Type
Determine which formatter to use based on project files (e.g., if `package.json` exists, use Prettier for JS/TS; if `pyproject.toml` exists, use Black for Python).

```bash
!bash <<'EOF'
if [ -f "package.json" ]; then
  formatter="prettier"
  target="${ARGUMENTS:-"."}"
  npx prettier --write "$target"
elif [ -f "pyproject.toml" ]; then
  formatter="black"
  target="${ARGUMENTS:-"."}"
  black "$target"
else
  echo "No recognized project config (package.json or pyproject.toml) found."
  exit 1
fi
EOF
```

### ✅ Completion Criteria

-   Formatting command runs without errors.
-   Output lists any files that were changed.

### ✅ Final Log

If the formatter made changes, list the files changed. If everything was already formatted, say "No changes needed."

```
A few things to note in this example:
- We included an **Objective** and **Steps** section in comments to guide Claude (and document for users)[74].
- The actual logic: we used a `!bash` block to decide which formatter to run. We check for a `package.json` or `pyproject.toml` to pick a tool. This is deterministic and ensures we don't ask Claude to guess the project type.
- We use `${ARGUMENTS:-"."}` which in bash means "use $ARGUMENTS if provided, otherwise use '.' (current directory)". This handles optional argument gracefully – if user supplies a subfolder or file, only format that, otherwise format whole project.
- Allowed-tools was just Bash, so this is fine.
- We included completion criteria and an instruction for final output logs: telling Claude to list changed files or say no changes. We could have captured the output of the formatter in the bash script and then processed it, but here I rely on the fact that Prettier/Black usually output which files they formatted. Claude can read that from the `!bash` result and then decide what to print as a final message (our instructions in the markdown tell it what to do).
- This command can be tested by running `/code:format` in a project with either JS or Python config, and seeing if it formats and reports properly.

This example shows a fairly minimal action command that uses shell commands for heavy lifting and provides structure around it.

### Example 2: A Multi-Step Agent Command

Now, a more complex scenario: **Initialize a New Feature Module**. Let's say in our project we often create new feature modules with some boilerplate. We want an agent that, given a feature name, sets up the structure, creates some template files, and runs tests.

**File:** `.claude/commands/project/create-module.md` → Command `/project:create-module`

**Frontmatter:**
```yaml
---
description: Create a new feature module with boilerplate code and tests
command-type: agent
argument-hint: module name (e.g., "user-profile" or "analytics-dashboard")
allowed-tools: ["Read", "Write", "Bash"]
---
```

\- We choose `agent` because it will orchestrate multiple actions and steps. - Allowed tools: likely need `Write` to create files, `Read` maybe to check or template files, and `Bash` to run tests or install dependencies.

**Prompt Content Outline:**

```
# 🏗️ Create Module Agent

**Objective:** Create a new module named `$ARGUMENTS` with a standard folder structure, initial code, and tests.

**Plan:**
1. **Scaffold Files:** Create a folder `src/modules/$ARGUMENTS/` with `index.ts` and `README.md`.
2. **Add Boilerplate:** Populate `index.ts` with a template (exporting a placeholder function or component named after the module).
3. **Add to Registry:** If there's a central registry file (like `src/modules/index.ts`), add an export for the new module.
4. **Generate Test:** Create `src/modules/$ARGUMENTS/$ARGUMENTS.test.ts` with a basic test skeleton.
5. **Run Tests:** Run `npm run test` to ensure everything passes.
6. **Git Status:** Show `git status` to the user so they see new files ready to commit.

### 🔨 Scaffold Files
Create the directory and files for the module.

```bash
!bash mkdir -p "src/modules/$ARGUMENTS"
!bash touch "src/modules/$ARGUMENTS/index.ts" "src/modules/$ARGUMENTS/README.md" "src/modules/$ARGUMENTS/$ARGUMENTS.test.ts"
```

### ✍️ Write Boilerplate Code

Add a basic content to the files.

```
@resource:templates/module-index.txt -> src/modules/$ARGUMENTS/index.ts
```

(Use a template for index file if available)

```
!Write "src/modules/$ARGUMENTS/index.ts" <<'EOF'
// $ARGUMENTS module - generated by Claude
export function ${{CamelCase $ARGUMENTS}}() {
  console.log("Hello from $ARGUMENTS");
}
EOF
!Write "src/modules/$ARGUMENTS/README.md" <<'EOF'
# $ARGUMENTS Module

This module was created via /project:create-module. It contains the core logic for $ARGUMENTS features.

EOF
!Write "src/modules/$ARGUMENTS/$ARGUMENTS.test.ts" <<'EOF'
import { ${{CamelCase $ARGUMENTS}} } from './index';

test('basic functionality of $ARGUMENTS module', () => {
  expect(${{CamelCase $ARGUMENTS}}()).toBeUndefined();
});
EOF
```

(Here, assume we have a way to transform `$ARGUMENTS` into CamelCase for function name, shown as pseudo-code \${{CamelCase ...}} for illustration.)

### 🔗 Register Module

Update the central modules index to export this module.

```
!bash echo "export * from './$ARGUMENTS';" >> src/modules/index.ts
```

### ✅ Run Tests

```
!bash npm run test
```

If tests fail, output the failures. If tests pass, confirm success.

### 📄 Git Status

```
!bash git status -u
Let's analyze this:
- We structured the plan and then implemented each step. This makes it easier for us to reason and helps Claude follow.
- We used `mkdir -p` and `touch` via Bash to ensure the file structure exists before writing.
- We attempted to use a template for the index file: `@resource:templates/module-index.txt -> src/modules/$ARGUMENTS/index.ts` is pseudo-syntax to indicate maybe copying from a template file (assuming one is available in a templates directory). Alternatively, we directly write content with `!Write` which we did right after. One could also have Claude write the content from scratch, but providing a template or at least a partial skeleton reduces guesswork.
- We invented a placeholder `${{CamelCase $ARGUMENTS}}` to indicate we want the function name in CamelCase. Claude can do this transformation in text if prompted properly (we might have needed to write an instruction above like "Assume a function CamelCase(input) transforms hyphen or space separated words into PascalCase/CamelCase." Alternatively, just instruct it to make the function name a CamelCase version of the module name).
- We appended an export to a central index file using Bash echo (a quick and dirty method; in practice, you might want to ensure idempotency – i.e., not to add it twice if run again, but let's assume single run).
- We run tests and plan to have Claude handle the output: if tests fail, it should show the failure output and maybe hint at next steps; if pass, just say success.
- Finally, we show `git status` to list new files (with `-u` to show untracked files). This gives the user feedback on what was created, ready to be git-added.

As an agent, this command calls no subcommands but uses multiple shell and write operations – mixing deterministic file ops with AI-generated content (function code). It’s orchestrating a mini-workflow: create, populate, verify.

A real run of this command would result in new files and likely some test output. The logs might look like:
```

[project:create-module][AGENT] → Created folder src/modules/analytics-dashboard [project:create-module][AGENT] → Scaffolded files index.ts, README.md, analytics-dashboard.test.ts [project:create-module][AGENT] → Wrote boilerplate code in index.ts [project:create-module][AGENT] → Wrote README.md [project:create-module][AGENT] → Wrote test file [project:create-module][AGENT] → Added module to src/modules/index.ts [project:create-module][AGENT] → Running tests... Test Suites: 1 passed, 1 total Tests: 1 passed, 1 total ... (jest output) ... [project:create-module][AGENT] → All tests passed. [project:create-module][AGENT] → New module created successfully.

# On Git status step:

[project:create-module][AGENT] → Git status: ?? src/modules/analytics-dashboard/

```
(This is an imagined log combining what we instructed; the actual might differ, but you get the idea.)

This example demonstrates an agent with several steps and touches on many aspects: using arguments, writing files, using resource templates, running shell commands, and verifying results.

**Walkthrough Recap:** When you trigger `/project:create-module feature-name`, Claude will:
1. Read the command file, see it’s an agent with those allowed tools.
2. Follow the steps: create folder and files (shell commands).
3. Write content to those files (using Write tool).
4. Append to index (shell echo).
5. Run tests (shell).
6. Show git status (shell).
7. Throughout, it’s guided to output logs or at least proceed sequentially.
8. The end result: new module skeleton in your project, tests run, user sees confirmation.

By examining these templates, you can adapt similar structures to your own needs:
- If you need an agent to do X, break X into steps and decide which are best done with AI vs tools.
- Provide templates or examples for content generation to keep output consistent.
- Always do some final verification (like tests or at least printing a success message).
- Ensure the user gets feedback (like our git status or logs) so they trust that something happened.

## Debugging, Logging, and Testing Workflows

As you develop your library of commands, you’ll inevitably need to debug when things go wrong, ensure the commands do what’s expected, and maintain confidence through changes. Let’s discuss strategies for debugging and testing, as well as how logging fits in.

**1. Logging within Commands:** We touched on this earlier: by including explicit logging outputs in your prompts (e.g., with a consistent prefix like `[command-name][ACTION]` or `[AGENT]`), you make it much easier to follow what happened during execution[27][30]. During development, you might want even more verbose logs. You can instruct the command to output the state of variables or intermediate results. For example, after a shell command, you could have Claude print, “Output of XYZ command above indicates success/failure” or log the number of items processed.

When debugging, it might be useful to temporarily add steps that dump context. For instance, you could have an agent echo the content of a file it just wrote (using `!Read`) to verify that the write was correct. Or have it print out the parsed arguments to ensure your parsing logic worked.

If you adopt the convention of log prefixes, stick to it. It will help you scan long outputs. You can even write a separate script to parse these logs if needed for analysis (though usually reading them is enough).

**2. Interactive Debugging:** If a command isn’t working correctly, run it in a controlled way:
- Try it with a simple scenario or in a test repository to isolate issues.
- Use the argument to limit scope (e.g., test on a small subset of files rather than the whole project).
- If it’s an agent calling subcommands, try running those subcommands individually to ensure they work on their own.
- Use an iterative approach: you might temporarily break one complex command into two steps for debugging. For example, first run a command that only generates a plan (not executing it), examine if the plan makes sense, then run the part that executes.

**3. Testing Commands:** It might sound meta, but you can write tests for your prompts. One way is to have **expected outcomes** documented in the command itself or in a separate file. The example earlier showed a snippet under "Test Template" with expected logs[75]. While that was likely for the AI’s own verification, you can use a similar approach for actual testing:
   - For critical commands, record an example run (input and output) when the command is known to be working. Store that output as the “golden” result.
   - After making changes to the command, run it again on the same input and diff the outputs. Some differences (like timestamps or random IDs) you might ignore, but the core behavior should remain consistent or improve.
   - If you have commands producing artifacts (files, etc.), you can write a shell test that after running the command, checks for the presence or content of those artifacts.
   - For instance, to test our `/project:create-module` command, you could have a script:
     ```bash
     # Setup: maybe initialize a temp git repo
     claude_cli "/project:create-module test-feature"
     # (assuming claude_cli is a way to run commands headlessly)
     test -d src/modules/test-feature && echo "Directory created"
     grep -q "function TestFeature" src/modules/test-feature/index.ts && echo "Index content ok"
     npm test -- grep="test-feature"  # run only tests related to that module
     ```
     This would validate that after the command, the structure is there and tests pass.

   - This kind of automated testing might not be straightforward without a CLI interface to Claude, but if you have one (or if using Claude in a CI context), it’s very powerful. Alternatively, manual testing for each release of commands might suffice if it’s a small team.

**4. Debugging Failures:** When a command doesn’t do what you expect:
   - Check the **Claude conversation logs** if available. Sometimes the AI might have decided something that isn’t obvious from the final output. If your environment allows viewing the chain-of-thought or intermediate reasoning, that can be enlightening. (Anthropic’s Claude might not show raw chain-of-thought by default, but well-placed reasoning prompts as we mentioned can cause it to output its plan which you can see.)
   - Verify tool outputs. Perhaps the AI misread the result of a shell command or a file content. If you suspect that, maybe adjust the prompt to explicitly capture needed info. For example, if a `!bash` command returns a complex output, instruct Claude to focus on a specific line or summary.
   - Reproduce outside Claude if possible. If `!bash npm run build` failed, try running `npm run build` yourself in the terminal to see the error. It might be easier to fix the underlying issue (like a missing dependency) and then rerun the command.
   - Add more logging or break the command into smaller steps to isolate where it’s going wrong. If an agent is failing at step 4, try running steps 1-3 and skip 4 to see if those were fine.

**5. Continuous Logging/Monitoring:** In a team setting, it might be useful to log command usage and outcomes to a file or system. For instance, you could have Claude always append results to a `commands.log` via a logging command or a hook. This way, if someone reports “the deploy command messed up at 3pm yesterday,” you have a record to review. Ensure that sensitive info is handled appropriately in such logs (maybe sanitize them if they might contain secrets). This is an advanced practice and might require hooking into the tool’s backend; not all setups allow it.

**6. Hooks for Testing:** You can utilize hooks in the Claude config (if available) to automatically run certain commands in response to events, which can be a form of continuous testing. For example, perhaps in `.claude/settings.json` you set a hook so that whenever `.claude/commands/` files change, it runs a `/commands:validate` command that lint-checks all command files for certain patterns (like missing frontmatter or forbidden phrases). Or a hook to run `/project:lint` on every file save as immediate feedback. Use hooks carefully (they execute immediately, as noted, so they should be non-destructive and fast)[73].

**7. Using Memory for Debugging:** Sometimes, you might add debug info to your `.claude/memory.md` that all commands can see. For instance, if you set a flag in memory like `DEBUG_MODE = true`, and then in your commands’ prompts, you check that and output extra info. This is a creative use of the memory file. Alternatively, an environment variable could serve a similar function if the Claude environment supports passing env vars to `!bash`.

**8. Finally, Human Review:** Despite automation, for critical workflows it’s wise to have a human in the loop at least at the verification stage. For example, even if your command does everything for a deployment, you might still have a human glance at the logs or diff. Encouraging a culture where team members review each other’s new commands (like code reviews) is important. A poorly written prompt could cause as much trouble as a bug in code – so treat them with the same seriousness.

In summary, debugging and testing in the world of slash commands involves a mix of traditional techniques (logging, incremental testing, validation scripts) and AI-specific considerations (observing model reasoning, adjusting prompts). By building robust logging into your commands and having some processes to verify their behavior, you ensure that your AgenticOps automations remain trustworthy. This is crucial as the usage grows – you want confidence that when you run a command, it will do exactly what it says on the tin, or at least clearly inform you if it couldn’t.

## Operationalizing with Automation Hooks and Memory

After creating reliable commands, the next step is **operationalizing** them – integrating them into your day-to-day workflows and automation pipelines. Two key aspects of this are **hooks** (which allow commands to run automatically on certain triggers) and **memory/context persistence** (which we partially covered, but let’s expand in an operational context).

**Automation Hooks:** Many AI coding environments (Claude Code included) allow you to define hooks in a config file (like `.claude/settings.json`). These hooks can automatically execute commands or actions in response to certain events. For example:
- Running a specific slash command every time you open the project.
- Running checks every time you save a file, or when you commit/push code.
- Triggering alerts or updates when a certain condition is met during a session.

In `.claude/settings.json`, hooks might look like:
```json
{
  "hooks": [
    { "event": "onFileOpen", "path": "src/.*\\.ts", "command": "/code:lint $filePath" },
    { "event": "onProjectOpen", "command": "/project:status" }
  ]
}
```

(This is a hypothetical structure; actual syntax may vary.)

A concrete example: You could add a hook so that whenever you open a design file, Claude automatically runs `/workflow:design:lint` on it and perhaps comments on any issues. Or a hook on project open to run `/project:lint-all` to give you an overview of code quality.

**Be Cautious with Hooks:** Hooks run without explicit user invocation, so **safety is paramount**. They should be idempotent and quick. Do not include destructive operations in hooks (like deleting things) since they will execute unprompted[[73]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,or%20anything%20destructive%20without%20validation). Also, ensure they won’t spam you (e.g., if a hook runs on every file save and prints a full report each time, that might be too much). Possibly provide a way to disable certain hooks if needed (maybe via a config flag).

A good practice is to use hooks for **enforcement and reminders**: - Ensuring everyone’s environment runs the same checks (so you can’t forget to run them). - Lightweight actions like keeping a table of contents updated, or checking for TODO comments on commit, etc.[[76]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,reviewed%20compliance%20checks).

For instance, a hook might automatically run `/docs:update-toc` whenever markdown docs change, to keep the table of contents in sync. Or run a security scan command on push.

**Integration with CI/CD:** Apart from local hooks, consider integrating slash commands into your CI pipelines. If you have a CI server, you could call some commands via a CLI interface in your pipeline scripts. For example, as a test step: run the slash command for running tests (`/dev:test`) instead of directly calling `npm test`, if the slash command does extra setup. Or use a slash command in CI to deploy (though for safety, one might keep CI using standard scripts and let slash commands be more for developer productivity – depends on trust level).

**Memory for Operational Context:** We talked about `.claude/memory.md` for persistent knowledge. In operation, you can use it to maintain state or context between commands: - **Project Constants:** You can store things like current version number, last deployment date, key stakeholders, etc. Commands can read these from memory and update if needed. For example, a `/project:release` command could update a "Last release: 2025-07-27" line in memory.md. - **Shared Facts:** If multiple commands need to know something (like the name of the project lead or an architectural decision), put it in memory so you update in one place. It’s like a mini database the AI consults every time. - **Rules and Policies:** Memory is a good place to put organization-wide guidelines (coding standards, security policies) so that all commands inherently are aware of them. For instance, “All production passwords must be rotated every 90 days” if relevant to ops tasks – then any command involved in password management will have that context. - **Session Data:** If you’re in a long AI session doing a series of tasks, memory can be a way to persist data from one command to the next. For example, if you run a command to start an incident response, it could log some info in memory.md (like incident ID, root cause found, etc.), and a subsequent command could pick that up. However, because memory.md is more meant for static info, for truly dynamic run-to-run data, a better approach might be writing to a file or using an external state (like a small database or file).

**Extending Memory – Multi-Project or Personal Memory:** If you have multiple projects, each has its own `.claude/memory.md`. Additionally, you might have a global memory (maybe `~/.claude/memory.md` or similar) for things relevant to all projects (like your personal preferences or company-wide info). Keep these updated. For example, global memory might contain your company’s mission or high-level principles that you want the AI to always consider. Project memory is more specific.

**Combining Memory with Hooks:** You could have a hook that updates memory. For instance, a hook could run on project open to update a timestamp in memory “Project last accessed at ...”, though that’s a trivial example. More practically, an agent might write certain results to memory, and then a hook could trigger another action if memory changed in a certain way – though that gets complex.

**Governance in Ops with AI:** Operationalizing also means thinking about how to govern the use of these commands: - Who can run which commands? (If using within a team, maybe some dangerous commands are restricted to certain users or require a confirmation step.) - Do you want an audit trail? (If Claude triggers deployments, you may need logs for compliance – integrating with existing logging systems might be necessary.) - Version control for prompts we covered – just ensure that when commands update, your team knows (maybe send a Slack message "Commands updated to v1.2: changed deploy process" or similar). - Rollback plan: If a new version of a command misbehaves, be ready to revert to a previous version (keeping history in Git helps with that).

**Using Agents for Memory and Continuity:** You can create special commands to handle memory or context tasks. For example, an agent `/project:status` that compiles a quick overview using memory and current state: - It could read memory.md, maybe check git status or open PRs (via MCP), and produce a status report. This could even be run as a hook on project open, to give you an immediate briefing.

Another idea: an agent that periodically cleans up memory or ensures it’s up to date (removing obsolete info, adding new key points). Possibly manual maintenance is fine, but if some info can be auto-updated (like list of recent contributors, etc.), you could script that.

**Example Operational Flow:** Let’s illustrate a scenario where automation hooks and memory work together: - You open the repo in the morning. A hook triggers `/project:status`. Claude outputs a summary: “Good morning! There are 2 open PRs, 1 failing test in CI, and the last deployment was 3 days ago. Your memory file notes the next release is scheduled for Aug 1.” This is pulling from memory and live data (via MCP to CI perhaps). - You start coding on a feature. On saving a file, a hook triggers `/code:lint` on just that file. If an issue is found, Claude might inline a comment or output a warning. - You commit and push. As part of pre-push, a git hook could invoke `claude_cli "/project:ensure-quality"` which perhaps runs tests and lint on changed modules with AI assistance. Only if it returns success does the push proceed (or it could just warn). - That command might update memory if, say, it bumps a version number or notes something for the next person. - Later, you run `/project:release` to deploy. It performs steps and updates `.claude/memory.md` with "Last release: Jul 27, 2025, by Alice". This persists for future queries. - The cycle repeats.

In essence, you weave the slash commands into the fabric of your development lifecycle, augmenting existing automation (like traditional CI) with AI-driven automation (like dynamic checks, documentation, or coordination tasks).

**Memory as Organizational Memory:** Over time, the memory file can become a rich source of context. Just ensure it stays relevant: remove things that are no longer true (e.g., if a policy changed, update it). Also be mindful of not including sensitive data in memory if your environment is not 100% secure or if the AI model might leak it inadvertently. For example, instead of storing actual secrets, store references or hashes.

**Scaling Up Automation:** As you get confident, you could let agents run overnight jobs or manage routine tasks entirely. This is where AgenticOps really pays off – the AI can maintain systems while you’re not actively there. Always have safeguards though: monitoring that can alert a human if the AI does something unexpected or if a process fails. The AI is powerful but not infallible, so treat it as a very skilled but somewhat unpredictable team member who needs oversight, especially for crucial ops.

To sum up, operationalizing means making these commands not just ad-hoc tools you run manually, but integral parts of the workflow through hooks and persistent context: - **Hooks** automate the trigger of commands at the right times without you typing them. - **Memory** ensures the AI always has the necessary background and can maintain state between tasks. - Combined, they enable a more continuous and context-aware assistance, pushing your development process closer to an autonomous (but still human-directed) pipeline.

## Governance, Security, and Updating Strategies

As your use of Claude Code slash commands grows, it’s important to establish governance and security practices, as well as plan for keeping the system up-to-date. This ensures that the power of these commands is used responsibly and continues to evolve with your needs.

**Governance and Policy:** - **Establish a Code Standard for Commands:** Much like coding standards for software, define a style guide for writing commands (which you’ve effectively done by following the template and best practices in this guide). This includes naming conventions, when to use agents vs actions, how to format prompts, and how to document them. By having a standard, all team members will create commands that are consistent in quality and style[[77]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=This%20document%20defines%20a%20structured,consistency%2C%20and%20updatability%20across%20projects). - **Command Reviews:** Consider a process where new or modified commands undergo peer review. Since these commands can execute powerful actions, having another set of eyes can catch potential issues – whether it’s a logical bug or a dangerous operation. Code review policies should apply to `.claude/commands/` as they do to source code. - **Access Control:** Think about who can run what. Out-of-the-box, any developer with the repo can usually run all commands defined. If that’s a concern (e.g., you might not want junior devs running the production deployment command), you might need to implement an approval step or use environment-based restrictions. For instance, perhaps the actual secret or token for deploying is only available on a lead’s machine, so even if someone runs the command, the deploy step fails for them. Alternatively, integrate with a permissions system – though Claude Code itself might not have user roles, you can design your environment such that sensitive MCP endpoints (like production DB or deploy scripts) require certain credentials that not everyone has. - **Logging and Audit Trails:** Enable logging of command usage if possible. You might route logs to a monitoring system (say, shipping Claude’s outputs to a logging service) especially for critical commands like those that affect production. If something goes wrong, you want to be able to trace: who ran what, when, and what exactly happened. If direct logging of AI operations is hard, at least rely on your agent logs which you embedded (they will be in the conversation history that a user can save or copy). - **Versioning of Commands:** Use the `version` field in frontmatter to keep track of changes[[78]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=command,)[[13]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,). You might adopt semantic versioning for commands if they change significantly. For instance, if you completely overhaul how `/data:import` works, bump its version and communicate it. You could even have a command `/commands:changelog` that reads all commands and finds version changes to produce a summary for the team. - **Deprecation Policy:** If you need to retire a command, you can mark it in its description or memory. Perhaps prefix its description with “[DEPRECATED]” and in memory.md maintain a list of deprecated commands with their replacements. Then if someone tries to use it, the AI might warn them (because it sees the deprecated note). You could also eventually remove it from the codebase after a certain time.

**Security Considerations:** - **Tool Spoofing and Validation:** The doc mentioned a safety audit found risks like tool spoofing[[57]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20access%20control). For example, an AI might try to call a tool not allowed by masquerading the output as if it did something. Ensure the environment truly enforces allowed-tools (this is more on Anthropic’s side to implement, but being aware means you trust but verify tool actions). If you suspect the AI did something it shouldn’t, double-check system logs or actual outcomes. - **MCP Security:** Only connect Claude to systems you’re comfortable with it accessing. If you hook it to a production database, you could potentially have an AI running `DROP TABLE` if mis-prompted. That’s why limiting allowed queries or providing read-only credentials to certain MCP integrations is wise. Use something like an *MCP Guardian* or custom proxy that can filter dangerous commands[[57]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20access%20control). For instance, an MCP server for a database might explicitly disallow `DELETE` or `DROP` statements unless a special override token is present. - **Network Access:** By default, consider not granting general internet access to Claude in this setting (unless needed). That avoids any possibility of it calling external APIs unpredictably. If needed for specific tasks, limit it to specific endpoints via MCP. - **Secrets Management:** If Claude needs to use secrets (API keys, etc.), use secure methods (MCP vault or similar). And ensure those secrets are not echoed in outputs. One precaution: if the AI does inadvertently output a secret (from memory or from reading a config file), treat it like any leak – rotate that secret. You can reduce this risk by instructing in memory or prompt: “Never print the actual API keys” and by not storing them in plaintext where the AI can see them (maybe the MCP server handles them without revealing to AI). - **Rate Limiting and Abuse:** If some commands can trigger heavy usage of resources (like hitting an API or starting many processes), consider putting limits. For example, have the command check that it’s not going to run more than X instances or not fetch more than Y MB of data, etc., or at least warn. This prevents an AI loop from unexpectedly racking up cloud costs or spamming a service due to a bug.

**Updating Strategies:** - **Regular Audits:** Periodically review your commands for relevance and security. Are there new tools or features from Claude that you could use to improve them? Are any commands obsolete because processes changed? This is like code maintenance – schedule a review maybe every few sprints. - **Dependency Updates:** If your commands rely on external tools (like specific CLI versions), keep an eye on those. For instance, if Prettier releases a new major version that changes formatting, update your formatting command accordingly (and test it)[[68]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,running%20commands). If you pinned a version in the prompt, make sure to bump it after evaluating the new version. - **Bulk Updates:** The guide hinted at commands to update others (like `/update-dependencies` which likely scans command files to update versions mentioned, and `/migrate-dependencies` to update code examples)[[79]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,running%20commands). You can build such meta-commands for your environment: - `/commands:update-all` could find and replace certain strings in the .claude folder (with caution). - Or simpler, use shell scripts or editor tools to do find-replace across the command files, then quickly verify via tests. - **Testing Before Production Use:** If you treat some commands as “production” (like deploy, migrations, etc.), test them in a staging environment first after any significant change. You can, for example, have a staging project or dummy project where you simulate the actions. Or add a `--dry-run` flag that causes it to do everything except the final step (like outputting the shell commands it *would* run without actually running them). - **Communication of Changes:** If you have multiple users of the commands, communicate updates. This could be via a changelog as mentioned, or an announcement in team chat. Surprising people with changed automation can be as bad as surprising them with changed APIs. For example, if `/deploy` now requires an extra argument or behaves differently, let everyone know to avoid confusion or mistakes. - **Fallbacks and Manual Overrides:** In case the AI part fails, ensure there’s a manual way to do critical tasks. E.g., if `/deploy` breaks on release day, engineers should be able to deploy via standard scripts or tools. Document those backup procedures. The slash commands should augment and streamline, but not hold you hostage.

Finally, always keep an eye on the **Anthropic Claude updates and best practices**. The field is evolving; new features or changes in the AI’s behavior could affect your commands. For example, if Anthropic updates how `$ARGUMENTS` parsing works (maybe introducing multiple args officially), you might adapt to use that simpler approach. The reference to best practices from Anthropic[[80]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%27s%20MCP%20equips%20Claude%20Code,not%20just%20conversational%2C%20but%20operational) suggests reading their engineering blog or docs periodically, as they might introduce new patterns or warn against some.

**Cultural Aspect:** Encourage a culture where the team treats the AI as a partner but one that needs guidance. Empower team members to suggest improvements to commands just as they would suggest code improvements. Maybe hold a demo or training so everyone knows how to write and modify commands themselves – this distributes knowledge and prevents one person from being a bottleneck for AI operations.

In conclusion, govern your AI command ecosystem with the same diligence as any critical system: - Set rules and standards. - Secure what it can do. - Keep it current and relevant. - Educate the users (your team) about how to use it safely and effectively. By doing so, you ensure that “coding your value stream” with Claude remains a boon and not a risk. As you update your approach, you might very well feed those learnings back into the commands themselves, continually leveling up your AgenticOps practice.

## Conclusion and Next Steps

We’ve covered a lot of ground – from the basic concept of slash commands in Claude Code to advanced operationalization and governance. By now, you should have a solid understanding of how to **reprogram your workflows** using Claude as a collaborative AI agent, through well-structured slash commands.

**Key takeaways:** - **Claude Code slash commands** let you turn repetitive or complex tasks into shareable prompt-based tools, effectively *coding your value stream* in natural language[[1]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=What%20if%20you%20could%20write,in%20code%2C%20using%20plain%20English). - Using the **agents and actions pattern** keeps your automations organized: high-level agents coordinate, while actions do the deterministic work[[19]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test)[[16]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint). - **Arguments and dynamic prompts** provide flexibility, allowing one command to handle many scenarios, especially when combined with robust parsing strategies[[31]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Claude%20Code%20supports%20a%20,not%20named%2C%20and%20not%20typed)[[72]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%23%23%20Patterns%20for%20Multi). - **Integrating shell commands and tools** (via `!bash`, `!Read`, etc.) gives your AI workflows deterministic power and access to real systems[[44]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI) – bridging the gap between conversational AI and actual DevOps. - **MCP (Model Context Protocol)** extends this power to external systems securely, so Claude can fetch data or trigger actions outside its initial sandbox when configured[[58]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,%2C%20%2C)[[81]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%27s%20MCP%20equips%20Claude%20Code,not%20just%20conversational%2C%20but%20operational). - Following **best practices** (clear naming, modular design, prompting the AI to reason, limiting tools, etc.) ensures your commands are reliable and maintainable, while avoiding anti-patterns prevents common pitfalls (like ambiguous prompts or unsafe operations). - **Testing and logging** are your friends – treat commands like code by debugging and verifying them regularly. Use logs to trace what the AI does for easier troubleshooting[[27]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60%20,PASS%20%E2%80%94%20agent%20completed). - **Automation hooks and memory** allow these AI-driven workflows to become a seamless part of your environment, running at the right times and always informed by the latest context[[76]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,reviewed%20compliance%20checks)[[54]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%92%BE%20Memory%20Files%20for%20Persistent,rules%2C%20owners%2C%20or%20directory%20structure). - A focus on **security and governance** keeps the system safe – controlling access, reviewing changes, and updating processes as your needs evolve ensures that you can trust this AI augmentation in critical operations[[82]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60,)[[57]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20access%20control).

Now, what are the next steps for you?

1.  **Set Up Claude Code**: If you haven’t already, get Claude Code (or Claude in a code-integrated environment) running. Set up the `.claude/commands` directory in a test repository or your current project.
2.  **Start Small – Create a Simple Command**: Identify a small daily task you do (for example, generate a boilerplate for a new component, or fetch the latest log entries). Write a slash command for it using the guidelines here. Keep it simple and test it out. Iterate until it works well.
3.  **Gradually Add More Commands**: Think of other parts of your “value stream” that are codifiable:
4.  Coding tasks (linting, formatting, applying project conventions).
5.  DevOps tasks (deployments, environment setups, monitoring checks).
6.  Documentation tasks (updating changelogs, generating summaries).
7.  Cross-functional tasks (maybe something like analyzing JIRA tickets or prepping release notes from commit history – the sky’s the limit). Each time, apply the patterns: decide if it’s an action or agent, determine what tools are needed, structure the prompt, test, refine.
8.  **Implement Logging/Monitoring Early**: Establish your logging format (like the bracketed prefixes) from the get-go, so all new commands use it. Consider creating a command that aggregates logs or important outputs if that helps (or just rely on manual checking).
9.  **Integrate with Workflow**: Try adding one of your commands to a hook or CI process. For instance, maybe have a pre-commit hook that runs `claude_cli "/code:lint $changedFile"` for changed files. Start with non-intrusive integrations (ones that don’t block you but just warn or inform).
10. **Expand Memory.md**: Fill out the memory file for your project with details you think the AI should always remember. This might grow over time. Also, note in memory any special instructions or cautionary notes (for example, “This is a production repo – any destructive action must be confirmed by X.” Claude will see that and hopefully heed it).
11. **Team Onboarding**: If you work in a team, share what you’ve built. Show colleagues how to run the commands and how they work. Encourage them to contribute – maybe host a brown bag session on writing Claude commands. A collaborative approach will yield a richer command library.
12. **Feedback Loop**: Use the commands in real work and see how they perform. If the AI output is off in some edge case, refine the prompt. If something takes too long or fails often, consider redesign or splitting it differently. The beauty of this system is it’s quite malleable – prompts can be tweaked faster than traditional code in many cases. Just remember to keep changes versioned and reviewed.
13. **Stay Updated and Learn**: Follow Anthropic’s updates, read about how others might be using Claude or similar tools in operations. There might be new features like improved multi-command handling, better ways to manage memory, or community-shared command libraries. Incorporate useful new ideas into your practice.
14. **Scale Up**: As confidence grows, you can attempt more ambitious automations. Perhaps a full end-to-end pipeline where you just kick off an agent and it does from code checkout to deployment validation. Or autonomous monitoring agents that only alert you when truly needed, handling minor issues on their own (with guardrails).

By reprogramming your operations in this way, you’re essentially creating a living operations manual that executes itself. You’re capturing not only *what* needs to be done, but *how*, in a form that’s both human-readable and machine-executable. This is a powerful paradigm shift in how we approach DevOps and workflow automation.

In closing, the journey of AgenticOps with Claude is iterative and collaborative. Start building your library of slash commands, and treat it as a core part of your codebase. Encourage an *“AI-first” mindset* where, whenever you encounter a tedious or complex process, you ask: *“Can I delegate this to a Claude command?”* Very often, the answer will be yes – and if done following the best practices we’ve outlined, Claude will handle it in a reliable, repeatable way.

Now, the next step is yours: pick a task and code your first command. Welcome to the era of coding your value stream with AI – your terminal-native AI assistant awaits your instructions![[3]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=using%20shell%20commands%20and%20MCP)[[81]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%27s%20MCP%20equips%20Claude%20Code,not%20just%20conversational%2C%20but%20operational)

[1] [[2]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=This%20is%20programmable%20prompting,quality%20analyst%2C%20even%20the%20CEO) [[3]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=using%20shell%20commands%20and%20MCP) [[4]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=In%20Claude%20Code%2C%20slash%20commands,in%20a%20specific%20folder%20structure) [[5]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Each%20command%20is%20a%20,The%20filename%20becomes%20the%20command) [[6]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) [[7]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,or%20run%20local%20commands%20securely) [[8]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Connecting%20MCP%20Servers) [[9]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI) [[10]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,on%20your%20local%20machine) [[11]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%BE%20Use%20Descriptive%2C%20Intuitive%20Names,data%3Amigrate) [[12]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Metadata%3A%20How%20to%20Signal%20Agent,vs%20Action) [[13]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,) [[14]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20reasoning%2C%20not%20for%20logic) [[15]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20,read%2Fwrite%20network) [[16]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint) [[17]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint) [[18]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,clearly%20show%20action%20invocations%20and) [[19]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test) [[20]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test) [[21]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Include%20these%20fields%20in%20frontmatter%3A) [[22]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=logic%20modular%20%26%20reusable,may%20require%20broader%20tool%20access) [[23]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%E2%80%99s%20slash%20command%20system%20and,window%20for%20clarity%20and%20performance) [[24]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,theme%60%2C%20%60%2Fdesign%3Alint%60%2C%20runs%20final%20test) [[25]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=1.%20%20,actions%20remain%20limited) [[26]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=is%20orchestration%20or%20a%20helper,isolated%20contexts%20to%20preserve%20focus) [[27]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60%20,PASS%20%E2%80%94%20agent%20completed) [[28]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20,theme%60%2C%20%60lint%60) [[29]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Log%20Prefixing%3A%20Verbal%20Signaling%20of,Role) [[30]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60%20%5Bdesign%3Agenerate,ACTION%5D%20Completed) [[31]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Claude%20Code%20supports%20a%20,not%20named%2C%20and%20not%20typed) [[32]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Claude%20Code%20supports%20a%20,not%20named%2C%20and%20not%20typed) [[33]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60md%20%2Ffix,following%20issue%3A%20%24ARGUMENTS) [[34]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Add%20the%20%60argument,to%20describe%20the%20expected%20input) [[35]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) [[36]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) [[37]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) [[38]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60bash%20%21bash%20,value%3D%22%24%7Bpair%23%2A%3D%7D%22%20export%20%22%24key%22%3D%22%24value%22%20done) [[39]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=if%20%5B%20,exit%201%3B%20fi) [[40]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) [[41]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60bash%20%21bash%20tailwindcss%20,css) [[42]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Agent%20commands%20can%20forward%20,to%20actions) [[43]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Add%20the%20%60argument,to%20describe%20the%20expected%20input) [[44]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI) [[45]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=) [[46]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,%E2%80%94%20use%20structured%20parsing%20only) [[47]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20%2A%2AUse%20built,) [[48]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%94%8D%20Prompt%20Claude%20to%20Think,Reflect%20on%20the%20desired%20output) [[49]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,tasks%20to%20Bash%20or%20CLI) [[50]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=built,load%20dynamically%2C%20no%20hardcoding%20required) [[51]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Read%20content%20from%20,Read) [[52]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Claude%20will%20resolve%20the%20MCP,reference%20and%20return%20file%20contents) [[53]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%AA%20Confirm%20File%20Paths%20with,src%2Futils%2Findex.ts) [[54]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%92%BE%20Memory%20Files%20for%20Persistent,rules%2C%20owners%2C%20or%20directory%20structure) [[55]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%93%A6%20Limit%20Context%20Bloat%20,for%20persistent%20reference%20info) [[56]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%7C%20%2A%2AUse%20built,) [[57]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,for%20access%20control) [[58]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,%2C%20%2C) [[59]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%8C%B1%20Start%20Simple%20,Refine%20through%20use%20before%20generalizing) [[60]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%93%81%20Organize%20with%20Folders%20and,project%3Acreate) [[61]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%8C%B1%20Start%20Simple%20,Refine%20through%20use%20before%20generalizing) [[62]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A0%20Break%20Prompts%20Into%20Steps,ended%20guidance) [[63]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=1.%20%F0%9F%8E%AF%20Objective%20,to%20do%2C%20in%20one%20sentence) [[64]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,project%20state) [[65]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=4.%20%F0%9F%93%8B%20Implementation%20Plan%20,Include%20shell%20commands%20if%20relevant) [[66]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=5.%20%E2%9C%85%20Completion%20Criteria%20,Output%3F%20File%20state%3F%20Git%20status) [[67]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,describe%20to%20verify%20setup%20worked) [[68]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,running%20commands) [[69]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A9%20Focus%20on%20Reusable%2C%20Composable,into%20a%20more%20general%20form) [[70]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%F0%9F%A7%A9%20Focus%20on%20Reusable%2C%20Composable,into%20a%20more%20general%20form) [[71]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=You%20can%20use%20this%20argument,to) [[72]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%23%23%20Patterns%20for%20Multi) [[73]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,or%20anything%20destructive%20without%20validation) [[74]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=1.%20%F0%9F%8E%AF%20Objective%20,to%20do%2C%20in%20one%20sentence) [[75]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60%60%60markdown%20%E2%9C%85%20Completion%20Criteria%20,is%20called%20with%20correct%20flags) [[76]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,reviewed%20compliance%20checks) [[77]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=This%20document%20defines%20a%20structured,consistency%2C%20and%20updatability%20across%20projects) [[78]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=command,) [[79]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=,running%20commands) [[80]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%27s%20MCP%20equips%20Claude%20Code,not%20just%20conversational%2C%20but%20operational) [[81]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=Anthropic%27s%20MCP%20equips%20Claude%20Code,not%20just%20conversational%2C%20but%20operational) [[82]](file://file-4cLdrYxvYDGBGZRS3CYF8f#:~:text=%60,) 1CC58C17EAF14395!se181918cca334e478b518ad046874076

<file://file-4cLdrYxvYDGBGZRS3CYF8f>
