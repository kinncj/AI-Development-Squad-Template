```

   ▄▄▄▄   ▄▄▄▄▄    ▄▄▄▄▄▄▄   ▄▄▄▄▄   ▄▄▄  ▄▄▄   ▄▄▄▄   ▄▄▄▄▄▄
  ▄██▀▀██▄  ███    █████▀▀▀ ▄███████▄ ███  ███ ▄██▀▀██▄ ███▀▀██▄
  ███  ███  ███     ▀████▄  ███   ███ ███  ███ ███  ███ ███  ███
  ███▀▀███  ███       ▀████ ███▄█▄███ ███▄▄███ ███▀▀███ ███  ███
  ███  ███ ▄███▄   ███████▀  ▀█████▀  ▀██████▀ ███  ███ ██████▀
                          ▀▀

```

[![CI](https://github.com/kinncj/AI-Development-Squad-Template/actions/workflows/ci.yml/badge.svg)](https://github.com/kinncj/AI-Development-Squad-Template/actions/workflows/ci.yml)
[![Integration Validation](https://github.com/kinncj/AI-Development-Squad-Template/actions/workflows/validate-integrations.yml/badge.svg)](https://github.com/kinncj/AI-Development-Squad-Template/actions/workflows/validate-integrations.yml)

A production-ready template for running an **orchestrated, phase-gated, TDD-enforced** development pipeline with **27 specialist AI agents**. Runs on two platforms simultaneously: **Claude Code** (Claude Code Max) and **OpenCode** (GitHub Copilot Enterprise).

> Based on: [Building an AI Development Squad: Orchestrated Multi-Agent Systems with Claude Code and OpenCode](./ARTICLE.md)

<div align="center">
  <img src="./demo.gif" alt="AI Squad demo — ai-squad init scaffolding a project" width="860">
  <br/>
  <sub><code>ai-squad init</code> — scaffolding a new project from the CLI</sub>
</div>

---

## What This Is

Single-agent AI coding breaks down at scale. Context gets polluted, tests get skipped, implementations diverge from requirements. The fix is structural: split the work across agents with **enforced boundaries**, just like a real engineering team.

- **27 specialist agents** — each with a defined role, restricted tools, and a specific model assignment
- **8-phase pipeline** — DISCOVER → ARCHITECT → PLAN → INFRA → IMPLEMENT → VALIDATE → DOCUMENT → FINAL GATE
- **TDD enforced** — QA writes failing tests first; implementation agents make them pass
- **GitHub integration** — every feature tracked via `gh` CLI, no browser required
- **17 reusable skills** — token-efficient CLI wrappers for Playwright, Docker, kubectl, Stripe, Supabase, and more
- **Dual platform** — identical agent prompts, platform-specific frontmatter for Claude Code and OpenCode

---

## Quick Start

Pick your platform:

| Platform | Guide |
|---|---|
| **Claude Code** (Claude Code Max) | [docs/quickstart-claude-code.md](./docs/quickstart-claude-code.md) |
| **OpenCode** (GitHub Copilot Enterprise) | [docs/quickstart-opencode.md](./docs/quickstart-opencode.md) |

**One-minute version (Claude Code):**

```bash
# Install the CLI globally
git clone https://github.com/kinncj/AI-Development-Squad-Template.git ~/.ai-squad
echo 'export PATH="$HOME/.ai-squad/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Scaffold a new project
mkdir my-project && cd my-project
ai-squad init

# Start a feature (inside Claude Code)
/feature "user registration with email and OAuth"
```

---

## Commands

| Command | Platform | What it does |
|---|---|---|
| `/feature "description"` | Both | Full 8-phase pipeline |
| `/build-feature "description"` | Both | Alias for `/feature` |
| `/bugfix "description"` | Both | Reproduce → fix → validate → CHANGELOG |
| `/validate` | Both | Run full test suite (no discovery/architecture) |
| `/tdd "requirement"` | Both | Single RED → GREEN → REFACTOR cycle |
| `ai-squad swarm feature "..."` | Claude Code | Parallel agents in Zellij tabs |

---

## Documentation

| Doc | Contents |
|---|---|
| [Quickstart — Claude Code](./docs/quickstart-claude-code.md) | Install, scaffold, run your first feature, swarm mode |
| [Quickstart — OpenCode](./docs/quickstart-opencode.md) | Install, configure providers, run your first feature |
| [The 8-Phase Pipeline](./docs/pipeline.md) | Phase details, TDD loop, Makefile contract, escalation policy |
| [The 27 Agents](./docs/agents.md) | Agent roster, model routing, 17 skills, adding custom agents |
| [Swarm Mode](./docs/swarm.md) | Parallel agents, Zellij navigation, all swarm commands |
| [Customization Guide](./docs/customization.md) | Add agents, change models, restrict permissions, extend skills |
| [Architecture Article](./ARTICLE.md) | Design decisions, why specialist agents, CLI vs MCP |

---

## Prerequisites

| Tool | Purpose | Install |
|---|---|---|
| [Claude Code](https://claude.ai/claude-code) | Primary platform | `npm install -g @anthropic-ai/claude-code` |
| [OpenCode](https://opencode.ai) | Alternate platform | See opencode.ai |
| [GitHub CLI](https://cli.github.com) | Issue and PR management | `brew install gh` |
| [Docker](https://docker.com) | Test infrastructure | docker.com |
| [Node.js](https://nodejs.org) | Playwright E2E tests | nodejs.org |
| [Zellij](https://zellij.dev) | Swarm mode (Claude Code only, >= 0.41.0) | `brew install zellij` |

---

## License

AGPLv3 — see [LICENSE](./LICENSE) for details.

Copyright (C) 2025 Kinn Coelho Juliao <kinncj@protonmail.com>
