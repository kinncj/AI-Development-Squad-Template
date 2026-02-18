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

A production-ready template for running an **orchestrated, phase-gated, TDD-enforced** development pipeline with 27 specialist AI agents. Designed to work on two platforms simultaneously: **Claude Code** (Claude Code Max) and **OpenCode** (GitHub Copilot Enterprise).

> **Based on:** [Building an AI Development Squad: Orchestrated Multi-Agent Systems with Claude Code and OpenCode](./ARTICLE.md)
>
> The article walks through every design decision behind this system — why specialist agents, how the 8-phase pipeline works, why CLI beats MCP for token efficiency, and how to map your licenses to the right models. Read it before customizing the template.

<div align="center">
  <img src="./demo.gif" alt="AI Squad demo — ai-squad init scaffolding a project" width="860">
  <br/>
  <sub><code>ai-squad init</code> — scaffolding a new project from the CLI</sub>
</div>

---

## What This Is

Single-agent AI coding breaks down at scale. Context gets polluted, tests get skipped, implementations diverge from requirements. The fix is structural: split the work across agents with **enforced boundaries**, just like a real engineering team.

This template gives you:

- **27 specialist agents** — each with a defined role, restricted tools, and a specific model assignment
- **8-phase pipeline** — DISCOVER → ARCHITECT → PLAN → INFRA → IMPLEMENT → VALIDATE → DOCUMENT → FINAL GATE
- **TDD enforced** — QA writes failing tests first; implementation agents make them pass
- **GitHub issue integration** — every feature tracked via `gh` CLI, no browser required
- **17 reusable skills** — token-efficient CLI wrappers instead of MCP for most tooling
- **Dual platform** — identical agent prompts, different frontmatter for Claude Code and OpenCode

---

## Prerequisites

| Tool | Purpose | Install |
|---|---|---|
| [Claude Code](https://claude.ai/claude-code) | Primary platform (Claude Code Max) | `npm install -g @anthropic-ai/claude-code` |
| [OpenCode](https://opencode.ai) | Alternate platform (GitHub Copilot Enterprise) | See opencode.ai |
| [Docker](https://docker.com) | Test infrastructure | docker.com |
| [GitHub CLI](https://cli.github.com) | Issue and PR management | `brew install gh` |
| [Node.js](https://nodejs.org) | Playwright E2E tests | nodejs.org |
| [tmux](https://github.com/tmux/tmux) | Swarm mode (Claude Code only) | `brew install tmux` |

**License requirements:**
- Claude Code Max subscription (includes `claude-opus-4-6` and `claude-sonnet-4-6`)
- GitHub Copilot Enterprise subscription (for `copilot/` model routing in OpenCode)
- Anthropic API key (for `anthropic/claude-opus-4-6` in OpenCode's orchestrator and architect)

---

## Quick Start

### Option A: Install globally, scaffold anywhere (recommended)

```bash
# 1. Install the squad CLI globally
git clone https://github.com/kinncj/AI-Development-Squad-Template.git ~/.ai-squad
echo 'export PATH="$HOME/.ai-squad/scripts:$PATH"' >> ~/.zshrc  # or ~/.bashrc
source ~/.zshrc

# 2. Scaffold a new project
mkdir my-project && cd my-project
ai-squad init

# 3. Authenticate platforms
gh auth login
export ANTHROPIC_API_KEY=your_key_here  # for OpenCode

# 4. Start a feature
claude /feature "user registration with email and OAuth"
```

The `ai-squad init` command copies the template, initializes git, installs npm dependencies, and optionally bootstraps GitHub labels — all in one step.

### Option B: Copy into an existing repo

```bash
# Copy .claude/ and .opencode/ directories into your repo root
cp -r ~/.ai-squad/.claude/ ~/.ai-squad/.opencode/ /path/to/your-repo/

# Copy infrastructure files
cp ~/.ai-squad/Makefile ~/.ai-squad/docker-compose.test.yml \
   ~/.ai-squad/playwright.config.ts /path/to/your-repo/
cp ~/.ai-squad/CLAUDE.md ~/.ai-squad/AGENTS.md ~/.ai-squad/opencode.json /path/to/your-repo/
cp -r ~/.ai-squad/scripts/ /path/to/your-repo/scripts/

# Bootstrap labels
cd /path/to/your-repo
ai-squad labels
```

---

## The 27 Agents

| # | Agent | Role | Claude Code model | OpenCode model |
|---|---|---|---|---|
| 1 | `orchestrator` | Pipeline control — never writes code | `claude-opus-4-6` | `anthropic/claude-opus-4-6` |
| 2 | `product-owner` | User stories, acceptance criteria | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 3 | `architect` | ADR, contracts, threat models | `claude-opus-4-6` | `anthropic/claude-opus-4-6` |
| 4 | `qa` | Write failing tests (RED) + validate (GREEN) | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 5 | `dotnet` | .NET backend | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 6 | `javascript` | Node.js / vanilla JS | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 7 | `typescript` | TypeScript backend/libraries | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 8 | `react-vite` | React + Vite SPA | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 9 | `nextjs` | Next.js full-stack | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 10 | `java` | Java backend (non-Spring) | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 11 | `springboot` | Spring Boot | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 12 | `kubernetes` | K8s manifests, Kustomize, Helm | `claude-sonnet-4-6` | `copilot/gpt-4.1` |
| 13 | `terraform` | Terraform IaC | `claude-sonnet-4-6` | `copilot/gpt-4.1` |
| 14 | `docker` | Dockerfiles, Compose | `claude-sonnet-4-6` | `copilot/gpt-4.1` |
| 15 | `postgresql` | Schema, migrations, RLS | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 16 | `redis` | Caching, pub/sub, streams | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 17 | `supabase` | Auth, RLS, Edge Functions | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 18 | `vercel` | Deployment, edge config | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 19 | `stripe` | Payments, webhooks, billing | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 20 | `data-science` | EDA, stats, visualization | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 21 | `data-engineer` | Pipelines, ETL, orchestration | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 22 | `tensorflow` | TF/Keras models | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 23 | `pytorch` | PyTorch models | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 24 | `pandas-numpy` | Data manipulation, arrays | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 25 | `scikit` | Classical ML, pipelines | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 26 | `jupyter` | Notebooks, papermill | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |
| 27 | `docs` | Feature docs, CHANGELOG, Mermaid | `claude-sonnet-4-6` | `github-copilot/claude-sonnet-4.6` |

**Model routing rationale:**
- Orchestrator and Architect use `anthropic/claude-opus-4-6` directly (Anthropic API) — highest reasoning, needed for coordination and design
- All implementation agents use `github-copilot/claude-sonnet-4.5` — fast, high-quality code generation via your GitHub Copilot Enterprise license
- Infrastructure agents (Kubernetes, Terraform, Docker) use `copilot/gpt-4.1` — strong at manifest and config generation
- Claude Code routes natively via subscription, no provider prefix needed

---

## The Commands

| Command | Platform | What it does |
|---|---|---|
| `/feature {description}` | Claude Code | Runs the full 8-phase pipeline |
| `/build-feature {description}` | Claude Code | Alias for `/feature` |
| `/bugfix {description}` | Both | Reproduce → fix → validate → CHANGELOG |
| `/validate` | Both | Run the full test suite without discovery/architecture |
| `/tdd {requirement}` | Both | Single RED → GREEN → REFACTOR cycle |

---

## The 8-Phase Pipeline

```
Phase 1: DISCOVER   → @product-owner writes stories + acceptance criteria → human gate
Phase 2: ARCHITECT  → @architect designs ADR, contracts, threat model → human gate
Phase 3: PLAN       → Orchestrator decomposes into tasks (tests precede implementation)
Phase 4: INFRA      → @docker, @kubernetes, @terraform, @postgresql spin up infra
Phase 5: IMPLEMENT  → TDD loop: @qa writes failing test → specialist makes it pass
Phase 6: VALIDATE   → @qa runs full suite (unit, integration, E2E, contract, smoke)
Phase 7: DOCUMENT   → @docs writes feature docs, CHANGELOG entry, runbooks
Phase 8: FINAL GATE → make test-all exits 0 → PR created
```

Every phase produces artifacts in `docs/specs/{feature-slug}/`. No phase can be skipped. 3 consecutive failures on any task escalate to a human.

---

## The Makefile Contract

All agents, CI/CD, and the orchestrator use the same `make` targets. The Makefile ships with stubs — **replace the recipe bodies with your stack's commands.**

```bash
make build           # Build all artifacts
make test            # Unit tests
make test-integration # Integration tests (starts containers automatically)
make test-e2e        # E2E tests via Playwright
make test-contract   # Contract/schema tests
make test-all        # Full suite — Phase 8 gate
make lint            # Lint
make security-scan   # Security scanning
make fmt             # Format code
make containers-up   # Start test containers (PostgreSQL + Redis)
make containers-down # Stop and remove test containers
make seed-test       # Seed test database
make migrate         # Run database migrations
```

---

## The 17 Skills

Skills are markdown files agents read before executing tasks. They teach CLI patterns, workflows, and tool usage — loaded on demand, not injected on every turn.

| Category | Skills |
|---|---|
| Process | `tdd-workflow`, `rfc-adr`, `threat-modeling` |
| Output | `mermaid-diagrams`, `finops-review`, `sre-review` |
| Tool/CLI | `playwright-cli`, `github-cli`, `docker-patterns`, `kubernetes-patterns`, `terraform-patterns`, `supabase-patterns`, `stripe-patterns`, `vercel-patterns`, `postgresql-patterns`, `redis-patterns`, `jupyter-patterns` |

Skills live in `.claude/skills/` and `.opencode/skills/`. Both directories are populated and synchronized.

---

## File Structure

```
.
├── CLAUDE.md                    # Claude Code project rules
├── AGENTS.md                    # Agent roster quick reference
├── opencode.json                # OpenCode project config
├── Makefile                     # 13-target build/test contract
├── docker-compose.test.yml      # Test infrastructure (PostgreSQL + Redis)
├── playwright.config.ts         # E2E test configuration
├── CHANGELOG.md
│
├── .claude/
│   ├── agents/                  # 27 agent definitions (Claude Code format)
│   ├── commands/                # 5 commands: feature, build-feature, bugfix, validate, tdd
│   └── skills/                  # 17 skills
│
├── .opencode/
│   ├── agents/                  # 27 agent definitions (OpenCode format with tools/permission)
│   ├── commands/                # 5 commands
│   └── skills/                  # 17 skills (mirrored)
│
├── app/
│   ├── backend/                 # Your backend code goes here
│   └── frontend/                # Your frontend code goes here
├── common/                      # Shared code
├── infra/
│   └── scripts/
│       └── seed-test.sh         # Seed test database (called by make seed-test)
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── e2e/
│   ├── contract/
│   └── smoke/
├── docs/
│   ├── specs/current/contracts/ # Phase 2 artifact output
│   ├── features/                # Phase 7 artifact output
│   ├── architecture/
│   └── runbooks/
└── scripts/
    └── ai-squad                 # Global CLI: init · labels · swarm
```

---

## Customizing for Your Stack

### 1. Update the Makefile

Replace the stub recipe bodies with your stack's actual commands:

```makefile
test:
    dotnet test --filter "Category=Unit"  # .NET
    # or: pytest tests/unit -v             # Python
    # or: npx vitest run tests/unit        # Node.js
```

### 2. Configure test infrastructure

`docker-compose.test.yml` ships with PostgreSQL and Redis. Add, remove, or configure services to match your stack. LocalStack and Wiremock stubs are included as comments.

### 3. Adjust model IDs

The template ships with current model IDs (`claude-opus-4-6`, `claude-sonnet-4-6`, `copilot/gpt-4.1`). When new model versions are released:

- **Claude Code agents** (`.claude/agents/*.md`): update the `model:` field
- **OpenCode agents** (`.opencode/agents/*.md`): update the `model:` field using `provider/model-id` format
- **`opencode.json`**: update `model.default`

### 4. Add or remove agents

Each agent is a single markdown file. To add a specialist:
1. Create `.claude/agents/{name}.md` with `name`, `description`, `model` frontmatter
2. Create `.opencode/agents/{name}.md` with full frontmatter including `tools` and `permission`
3. Add the agent to the `permission.task` list in `.opencode/agents/orchestrator.md`
4. Update `AGENTS.md`

### 5. Populate skills

Skills ship with content but you can extend them. Each `SKILL.md` teaches agents how to use a specific tool or follow a process. Agents read skills before executing tasks — keep them concise and CLI-focused.

---

## Swarm Mode (Claude Code only)

Run multiple agents in parallel on independent tasks using tmux. The orchestrator produces `plan.md` during Phase 3; `ai-squad swarm` reads it and spawns one tmux pane per task.

```bash
# Run all tasks from docs/specs/current/plan.md in parallel
ai-squad swarm full

# Run specific task numbers
ai-squad swarm tasks 3 5 7

# Run a single agent with a specific prompt
ai-squad swarm agent @dotnet "make the test at tests/unit/OrderTests.cs pass"
```

---

## MCP Configuration

This template uses **one MCP server**: [Context7](https://context7.com) for library documentation lookup. All other tooling (Playwright, Docker, kubectl, terraform, stripe, etc.) runs via CLI skills — significantly more token-efficient than MCP equivalents.

Context7 is pre-configured in `opencode.json`. For Claude Code:

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
```

Agents use it by appending `use context7` to prompts, or referencing a library directly: `use library /supabase/supabase`.

---

## License

AGPLv3 — see [LICENSE](./LICENSE) for details.

Copyright (C) 2025 Kinn Coelho Juliao <kinncj@protonmail.com>
