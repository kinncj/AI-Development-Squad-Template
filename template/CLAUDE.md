# CLAUDE.md — Project Rules for Claude Code

## Agent System
This project uses an orchestrated multi-agent system.
Default agent: @orchestrator (never writes code, delegates everything).

## Commands
- `/feature {description}` — Full 8-phase pipeline
- `/build-feature {description}` — Alias for /feature
- `/bugfix {description}` — Reproduce → fix → validate → CHANGELOG
- `/validate` — Run full test suite
- `/tdd {requirement}` — Single RED → GREEN → REFACTOR cycle

## Rules
1. The Orchestrator NEVER writes code. It delegates to specialist agents.
2. Tests are written BEFORE implementation (TDD enforced).
3. QA writes failing tests. Implementation agents make them pass.
4. 3 consecutive failures on any task → escalate to human.
5. All phases produce artifacts in `docs/specs/{feature-slug}/`.
6. `make test-all` must pass before Phase 8 gate.
7. Every feature gets a GitHub issue. Agents update issues via `gh` CLI.
8. Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `infra:`.

## MCP Servers
- context7: Library documentation lookup (`use context7` in prompts)

## Skills
Read skills from `.claude/skills/` before executing tasks.
Key skills: tdd-workflow, playwright-cli, github-cli, mermaid-diagrams.
