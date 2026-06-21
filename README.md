<div align="center">

# AgentCraft

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.11+-blue)](https://www.python.org/downloads/)
[![LangGraph](https://img.shields.io/badge/LangGraph-1.x-green)](https://langchain-ai.github.io/langgraph/)
[![LangChain](https://img.shields.io/badge/LangChain-Core_1.x-green)](https://python.langchain.com/)
[![DeepAgents](https://img.shields.io/badge/deepagents-0.5+-purple)](https://pypi.org/project/deepagents/)

</div>

Claude Code plugin for building production LangGraph agents with the full LangChain/LangGraph stack.

## Highlights

- **20 specialised skills** covering the complete agent development lifecycle — from Python project setup through multi-agent topology, Deep Agents harness, RAG pipelines, MCP tool integration, LLM evaluation, observability, and production deployment. Four skills accept focus arguments to scope the session to a specific provider or topic (e.g. `/agentcraft:langchain-providers bedrock`).
- **6 specialist agents** — `agent-architect`, `code-generator`, `code-reviewer`, `debugger`, `deployment-specialist`, and `evaluator` — each with the right skills pre-wired and the right model and effort budget. `code-generator` runs in an isolated git worktree so generated code never pollutes your working tree.
- **Automated developer environment** — a `PostToolUse` hook runs `ruff check --fix` automatically on every Python file Claude writes or edits.
- **Live code intelligence** — Pyright and Ruff language servers are bundled, giving Claude real-time type errors and lint feedback while editing agent code.
- **Background log streaming** — monitors activate when deployment or evaluation skills fire, tailing `logs/langgraph.log` and `logs/eval.log` so Claude sees server output in real time without manual log piping.
- **No deprecated patterns.** Skills enforce LangChain Core 1.x and LangGraph 1.x APIs: `create_agent`, `init_chat_model`, `PostgresSaver`, `InjectedStore`, `aindex()`. `AgentExecutor`, `LLMChain`, and `ConversationBufferMemory` are never suggested.
- **Evaluation-first.** `llm-evaluation` and `observability` are first-class concerns, not afterthoughts. Every project is expected to have evaluation datasets, LLM-as-judge evaluators, and tracing from day one.

## Table of Contents

- [Installation](#installation)
- [Skill Architecture](#skill-architecture)
  - [Skill Layers](#skill-layers)
  - [Skill Composition](#skill-composition)
- [Specialist Agents](#specialist-agents)
- [Usage](#usage)
  - [Auto-invocation](#auto-invocation)
  - [Explicit invocation](#explicit-invocation)
  - [Scoped invocation](#scoped-invocation)
  - [Using agents](#using-agents)
- [Automation](#automation)
  - [PostToolUse hook](#posttooluse-hook)
  - [Background monitors](#background-monitors)
- [LSP Prerequisites](#lsp-prerequisites)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)

## Installation

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v2.1.142 or later.

Clone the repository and install the plugin:

```bash
git clone https://github.com/josephsearle/agentcraft
cd agentcraft
claude plugin install .
```

To test without installing:

```bash
claude --plugin-dir .
```

Verify the plugin loaded:

```text
/plugin list
# agentcraft  1.0.0  enabled
```

## Skill Architecture

### Skill Layers

The 13 skills are organised into three layers. Each layer builds on the one below it.

**Layer 1 — Foundations**

| Skill | Governs |
|-------|---------|
| `developer-experience` | `uv`, Ruff, Pyright, pre-commit, detect-secrets, `src/` layout, Google docstrings. The Python baseline every other skill assumes. |
| `langchain-core` | LCEL pipe syntax, `init_chat_model`, `astream_events`, `with_structured_output`, `CacheBackedEmbeddings`. Every LangChain/LangGraph skill depends on this. |

**Layer 2 — Build**

| Skill | Governs |
|-------|---------|
| `langchain-providers` | Provider-specific config: `ChatBedrockConverse` for AWS, Responses API for OpenAI, extended thinking for Anthropic, `with_retry`, `with_fallbacks`. |
| `langchain-tools-mcp` | `@tool`, `BaseTool`, `InjectedToolCallId`, `MultiServerMCPClient`, server-side tools, `with_structured_output` strategy. |
| `langchain-rag` | Idempotent ingestion (`SQLRecordManager` + `aindex()`), vector store selection, hybrid search, `SemanticChunker`, retrieve-then-rerank. |
| `langgraph-core` | `StateGraph`, reducers, `PostgresSaver`, `interrupt()`, `Command(resume=)`, streaming modes, `RetryPolicy`, `CachePolicy`, time-travel. |
| `langgraph-memory` | Short-term context management (`trim_messages`, `SummarizationNode`) and long-term cross-thread memory (`PostgresStore`, `InjectedStore`, LangMem SDK). |
| `langgraph-multiagent` | Supervisor pattern (`Command(goto=...)`), swarm (`create_handoff_tool`), `RemoteGraph`, `langgraph-bigtool`, Deep Agents harness overview. |
| `deepagents-harness-and-claude` | `HarnessProfile`, `register_harness_profile`, prompt assembly order, `AnthropicPromptCachingMiddleware`, built-in Claude/Codex model profiles. |
| `deepagents-filesystem` | `FilesystemMiddleware`, `FilesystemPermission`, `virtual_mode` security model, file tools, large-result eviction, multimodal file reads. |
| `deepagents-sandbox` | `BaseSandbox`, `SandboxBackendProtocol`, Modal/Daytona/Runloop/AgentCore setup, sandbox lifecycle, TTL, secrets security model. |
| `deepagents-subagents-and-async` | `SubAgent` TypedDict, `CompiledSubAgent`, `task` tool, `AsyncSubAgent`, five async task tools, `async_tasks` channel, ASGI in-process transport. |
| `deepagents-skills-and-memory` | SKILL.md authoring, `SkillsMiddleware`, three-level progressive disclosure, AGENTS.md, `MemoryMiddleware`, source layering. |
| `deepagents-rubric-and-eval` | `RubricMiddleware`, LLM-as-judge runtime evaluation, grader subagent, per-criterion feedback, integration with observability. |
| `deepagents-codegen-dcode` | `dcode` CLI, headless/CI mode, `CodeInterpreterMiddleware`, QuickJS REPL, Terminal-Bench benchmarks. |
| `prompt-engineering` | System prompt design for every node archetype — planner, router, executor, critic, summariser, RAG retriever — matched to the right technique (Zero-Shot, CoT, ReAct, ToT, Reflexion). |
| `testing-foundations` | pytest, pytest-asyncio strict mode, LangChain mock objects, Hypothesis property-based testing, test layout conventions. |

**Layer 3 — Operate**

| Skill | Governs |
|-------|---------|
| `llm-evaluation` | DeepEval, RAGAS, eval-repo architecture, dataset management, LLM-as-judge evaluators, CI gating. |
| `observability` | MLflow 3.x tracing, Prompt Registry, experiment tracking, GenAI evaluation, trace instrumentation. |
| `langgraph-deployment` | `langgraph.json`, `langgraph dev/build/deploy`, Agent Server runtime (Assistant, Thread, Run, Cron), self-hosted Docker Compose, BYOC Helm, `RemoteGraph` client. |

### Skill Composition

A typical project uses skills in this order:

```text
developer-experience          ← pyproject.toml, uv, Ruff, pytest, pre-commit
  └─ langchain-core           ← init_chat_model, LCEL, streaming
       ├─ langchain-providers      ← tune the model provider
       ├─ langchain-tools-mcp      ← define tools + MCP client
       │    └─ langgraph-core      ← customise graph topology
       │         ├─ langgraph-memory    ← short/long-term memory
       │         └─ langgraph-multiagent  ← supervisor / swarm / RemoteGraph
       │              └─ deepagents-harness-and-claude  ← HarnessProfile, model profiles
       │                   ├─ deepagents-filesystem     ← file tools, permissions, eviction
       │                   ├─ deepagents-sandbox        ← Modal/Daytona/Runloop/AgentCore
       │                   ├─ deepagents-subagents-and-async  ← async tasks, ASGI transport
       │                   ├─ deepagents-skills-and-memory    ← SKILL.md, AGENTS.md
       │                   ├─ deepagents-rubric-and-eval      ← LLM-as-judge at runtime
       │                   └─ deepagents-codegen-dcode        ← dcode CLI, QuickJS REPL
       ├─ langchain-rag            ← document retrieval
       ├─ prompt-engineering       ← node system prompts
       ├─ testing-foundations      ← test suite
       └─ llm-evaluation           ← evaluation datasets + CI gating
            ├─ observability       ← tracing + experiment tracking
            └─ langgraph-deployment  ← production deployment
```

## Specialist Agents

Six agents are available via the `/agents` picker or are auto-delegated when Claude determines a task matches their scope.

| Agent | Model | Role | Notes |
|-------|-------|------|-------|
| `agent-architect` | Opus / high | Designs agent topologies, chooses between supervisor/swarm/pipeline patterns, plans checkpointing and memory strategy | — |
| `code-generator` | Sonnet / high | Implements `StateGraph`, tools, RAG pipelines, MCP clients, and memory setup from an architectural plan | Runs in an isolated git worktree |
| `code-reviewer` | Sonnet / high | Audits code for deprecated API patterns, missing type annotations, incorrect async usage, and absent observability | Read-only (cannot write files) |
| `debugger` | Sonnet / high | Diagnoses tool-not-called, stuck loops, missing traces, memory failures, and MCP connection errors | — |
| `deployment-specialist` | Sonnet / medium | Writes `langgraph.json`, configures Docker Compose and Postgres/Redis backends, wires `RemoteGraph` | — |
| `evaluator` | Sonnet / high | Designs DeepEval/RAGAS suites, creates synthetic datasets, sets up MLflow experiment tracking, gates CI pipelines | — |

## Usage

### Auto-invocation

Skills load automatically when Claude detects relevant context. Mentioning `StateGraph`, `PostgresSaver`, `create_agent`, `aindex()`, `MultiServerMCPClient`, `DeepEval`, or any trigger phrase from a skill description causes that skill to activate.

### Explicit invocation

Invoke any skill directly using the `agentcraft:` namespace:

```text
/agentcraft:langchain-core
/agentcraft:langgraph-core
/agentcraft:langchain-rag
/agentcraft:llm-evaluation
/agentcraft:langgraph-deployment
```

### Scoped invocation

Four skills accept an optional argument to focus the session on a specific area:

```text
/agentcraft:langchain-providers anthropic    # Anthropic extended thinking, ChatAnthropic
/agentcraft:langchain-providers openai       # Responses API, reasoning_effort, streaming
/agentcraft:langchain-providers bedrock      # ChatBedrockConverse, cross-region inference
/agentcraft:langchain-providers ollama       # Local model setup

/agentcraft:langchain-tools-mcp tools            # @tool, BaseTool, InjectedToolCallId
/agentcraft:langchain-tools-mcp mcp              # MultiServerMCPClient, StdioConnection
/agentcraft:langchain-tools-mcp structured-output

/agentcraft:langgraph-deployment dev         # Local langgraph dev server
/agentcraft:langgraph-deployment docker      # Docker Compose + Postgres + Redis
/agentcraft:langgraph-deployment scale       # Horizontal scaling, BYOC

/agentcraft:llm-evaluation deepeval
/agentcraft:llm-evaluation ragas
/agentcraft:llm-evaluation ci                # CI gating, pytest integration
```

### Using agents

Select an agent from the `/agents` picker or describe a task — Claude will delegate automatically when appropriate:

```text
/agents
# → agentcraft:agent-architect
# "Design a supervisor-style multi-agent system for customer support with
#  shared long-term memory and tool routing across three specialist sub-agents."

/agents
# → agentcraft:code-generator
# "Implement the supervisor graph from the architect's plan."

/agents
# → agentcraft:debugger
# "My execute_tool node isn't being called. Here is the graph and the MLflow trace."
```

## Automation

### PostToolUse hook

Every time Claude writes or edits a `.py` file, `ruff check --fix` runs automatically on that file. Requires `ruff` in `$PATH` or a project with `uv` and ruff in the dev dependencies.

### Background monitors

Two monitors activate lazily when their corresponding skills are first invoked in a session:

| Monitor | Activates on | Watches |
|---------|-------------|---------|
| `langgraph-server-log` | `langgraph-deployment` skill | `logs/langgraph.log` |
| `eval-output-log` | `llm-evaluation` skill | `logs/eval.log` |

Redirect your process output to the expected log path to activate the monitor:

```bash
mkdir -p logs

# LangGraph dev server
langgraph dev 2>&1 | tee logs/langgraph.log

# Evaluation run
uv run pytest evals/ -s 2>&1 | tee logs/eval.log
```

Each new log line is delivered to Claude as a notification, so it can diagnose issues without you copying logs manually.

## LSP Prerequisites

The plugin registers Pyright and Ruff as LSP servers, giving Claude real-time type errors and lint feedback while editing Python files. Install both tools before starting a session:

```bash
uv tool install pyright
uv tool install ruff
```

If either binary is absent, that server is silently skipped — the plugin functions normally without them.

## Support

- **Bug reports and feature requests:** [Open a GitHub Issue](https://github.com/josephsearle/agentcraft/issues/new/choose)
- **Questions:** [GitHub Discussions](https://github.com/josephsearle/agentcraft/discussions)

## Contributing

Contributions are welcome. The plugin is a collection of Markdown skill files — no build step required.

To add or improve a skill:

1. Fork the repository and create a branch from `main`.
2. Add or edit the skill at `skills/<skill-name>/SKILL.md`. Follow the frontmatter schema: `name`, `description` (with trigger phrases), and numbered steps.
3. If the skill loads reference files, add them to `skills/<skill-name>/references/`.
4. Validate the plugin structure before opening a pull request:

```bash
claude plugin validate .
claude plugin validate . --strict
```

5. Open a pull request with a clear description of what changed and why.

For significant changes — new skills, changes to the layer model, new agents — please open an issue first to discuss the approach.

## License

[MIT](LICENSE) © 2025 Joseph Searle
