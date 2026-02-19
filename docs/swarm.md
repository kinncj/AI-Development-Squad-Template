# Swarm Mode

Swarm mode runs multiple specialist Claude Code agents in parallel, each in its own isolated git worktree and Zellij tab. A live dashboard shows real-time status; when all agents finish, the orchestrator automatically resumes for validation, documentation, and PR creation.

## Architecture

```
┌─ Zellij Session ──────────────────────────────────────────────┐
│                                                                │
│  Tab 1: DASHBOARD / orchestrator (always-visible control panel)│
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  AI Squad — swarm-1739847123                            │  │
│  │  Feature: user auth with OAuth                          │  │
│  │                                                         │  │
│  │  TAB  AGENT                    STATUS   ELAPSED  NAV    │  │
│  │  2    architect-1              done     00:42    Alt-2  │  │
│  │  3    typescript-2             running  03:15    Alt-3  │  │
│  │  4    qa-3                     pending  --:--    Alt-4  │  │
│  │                                                         │  │
│  │  1/3 done · 1 running · 1 pending                      │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
│  Tab 2: architect-1   ← done ✓                                │
│  Tab 3: typescript-2  ← running ↻                             │
│  Tab 4: qa-3          ← pending                               │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Flow

```
ai-squad swarm feature "..."
        │
        ├─ creates .swarm/{session}/
        │
        └─ Zellij ──────────────────────────────────────────┐
                                                             │
           Tab 1: orchestrator pane  ←─ Phase 1-3 ─► plan.md
                  dashboard pane     ←─ detects plan.md
                                     ├─ creates git worktrees
                                     ├─ launches agent tabs
                                     └─ monitors live TUI
                                                             │
           Tab 2: swarm-agent-wrapper (agent 1, worktree 1) │
           Tab 3: swarm-agent-wrapper (agent 2, worktree 2) │
           Tab N: swarm-agent-wrapper (agent N, worktree N) │
                                                             │
                  all agents complete                        │
                        │                                    │
                        └─ dashboard resumes orchestrator    │
                                 Phase 6: validate           │
                                 Phase 7: document           │
                                 Phase 8: PR                 │
```

### `.swarm/` Protocol

All coordination happens via plain text files in `.swarm/{session}/`:

```
.swarm/
└── swarm-1739847123/
    ├── session.json              # session metadata
    ├── sentinel                  # timestamp file for plan.md detection
    ├── resume-command.txt        # Phase 6 resume command (written on completion)
    └── agents/
        ├── typescript-1/
        │   ├── task.md           # the agent's prompt
        │   ├── branch            # git branch name
        │   ├── started_at        # ISO8601 timestamp
        │   ├── finished_at       # ISO8601 timestamp (after completion)
        │   ├── status            # pending | running | done | error
        │   ├── exit_code         # 0 or non-zero
        │   └── result.md         # git diff --stat + git log summary
        └── qa-2/
            └── ...
```

Status files are written atomically (write to `.tmp`, then `mv`) to prevent partial reads by the dashboard.

### Git Worktree Isolation

Each agent runs in its own git worktree on a dedicated branch:

```
Branch: swarm/{session}/{agent}-{num}
Path:   .swarm/{session}/agents/{agent}-{num}/worktree/
```

This means:
- Agents never conflict with each other's file changes during implementation
- Each agent starts from the same commit on the main branch
- After all agents complete, `swarm merge` cleanly integrates each branch

## Prerequisites

- [Zellij](https://zellij.dev/) >= 0.41.0 — `brew install zellij`
- [Claude Code](https://claude.ai/code) — `claude` in PATH
- Not already inside a Zellij session (`ZELLIJ` env var must be unset)
- A git repository with at least one commit

## Commands

### `swarm feature "<description>"` — Full Pipeline

The main command. Runs the complete 8-phase pipeline:

```bash
ai-squad swarm feature "add user authentication with OAuth"
```

**What happens:**
1. Creates `.swarm/{session}/` coordination directory
2. Launches Zellij with two panes in Tab 1:
   - **Orchestrator pane** — runs Claude Code phases 1-3 (Discover, Architect, Plan)
   - **Dashboard pane** — waits for `plan.md`, then auto-launches agent tabs
3. Orchestrator writes `docs/specs/<feature-slug>/plan.md` and stops
4. Dashboard detects `plan.md`, prompts for confirmation (10s auto-launch), creates worktrees, launches agent tabs
5. Live TUI shows agent status, elapsed time, exit codes
6. When all agents finish, dashboard auto-resumes orchestrator for phases 6-8

### `swarm full` — Run All Plan Tasks

When you already have a `plan.md`, launch all unchecked tasks with the dashboard:

```bash
ai-squad swarm full
```

Reads tasks from `$PLAN_FILE` (default: `docs/specs/current/plan.md`).
Override: `PLAN_FILE=docs/specs/my-feature/plan.md ai-squad swarm full`

**What happens:**
1. Creates `.swarm/{session}/` with pre-initialised agent dirs (`status=pending`)
2. Launches Zellij with:
   - **Tab 1**: dashboard (monitor mode — sees pre-created agent dirs, skips plan.md wait)
   - **Tabs 2+**: one agent wrapper per task running in an isolated git worktree

### `swarm tasks <n> [n...]` — Selected Tasks

Cherry-pick specific task numbers from the plan:

```bash
ai-squad swarm tasks 1 3 5
```

### `swarm agent <@name> "<prompt>"` — Single Agent

Run one agent directly without a plan file:

```bash
ai-squad swarm agent @dotnet "make OrderTests.cs pass"
```

### `swarm status [session-id]` — View Agent Status

Show the status table for the latest (or named) swarm session:

```bash
ai-squad swarm status
ai-squad swarm status swarm-1739847123
```

Output:
```
  AGENT                      STATUS     EXIT   BRANCH
  ────────────────────────── ────────── ────── ──────
  typescript-1               done       0      swarm/swarm-.../typescript-1
  qa-2                       error      1      swarm/swarm-.../qa-2

  2 total  ·  1 done  ·  0 running  ·  1 error  ·  0 pending
```

### `swarm merge [session-id]` — Merge Completed Branches

Merge all `status=done, exit_code=0` agent branches into the current branch:

```bash
ai-squad swarm merge
ai-squad swarm merge swarm-1739847123
```

For each agent:
- Checks branch has new commits beyond the merge base
- Runs `git merge --no-ff` with a conventional commit message
- Removes the worktree and deletes the agent branch
- On conflict: aborts the merge, writes a `merge-conflict` marker, continues others
- Reports `N merged · N skipped · N conflicted` at the end

## Navigation

Inside the Zellij session:

| Keys | Action |
|------|--------|
| `Alt-1` | Dashboard / orchestrator tab |
| `Alt-2`, `Alt-3`, ... | Jump to agent tab N |
| `Alt-n` / `Alt-p` | Next / previous tab |
| `Ctrl-o d` | Detach from session (session keeps running) |

To reattach later:
```bash
zellij attach          # most recent session
zellij attach <name>   # by name
zellij list-sessions   # show all sessions
```

## Dashboard TUI

The dashboard (`scripts/swarm-dashboard.sh`) auto-detects its mode:

- **Feature mode** (empty `agents/` dir): waits for `plan.md`, then launches agent tabs
- **Monitor mode** (pre-populated `agents/` dir): goes straight to live status display

Status indicators:
- `[ ]` pending (not started yet)
- `[↻]` running
- `[⚠]` possibly stalled (running > 90s with no worktree file changes)
- `[✓]` done (exit 0)
- `[✗]` error (non-zero exit)

The dashboard respects `$NO_COLOR` and degrades gracefully on dumb terminals.

## Troubleshooting

### "Already inside Zellij. Detach first."

You're running `ai-squad swarm` from within an existing Zellij session. Detach first:
```bash
Ctrl-o d   # detach (session keeps running in background)
```

### "zellij >= 0.41.0 required"

Upgrade:
```bash
brew upgrade zellij
```

### Dashboard shows `[⚠]` for a running agent

The agent has been running for > 90 seconds with no file changes in its worktree. This may be normal (agent is thinking) or the agent may be waiting for input. Jump to that agent's tab with the `Alt-N` shortcut shown in the dashboard.

### Worktree creation fails

If a branch already exists from a previous interrupted run, the wrapper tries to reuse it. If the worktree directory also exists, git will refuse to create another. Fix:
```bash
git worktree remove .swarm/{session}/agents/{agent}/worktree --force
git worktree prune
```

### Merge conflicts after `swarm merge`

If agents modified the same files, you'll get conflicts. The merge script aborts conflicting merges and continues others. To resolve a conflict manually:
```bash
git merge --no-ff swarm/{session}/{agent}-{N}
# resolve conflicts in editor
git add .
git merge --continue
```

### `plan.md` not detected by dashboard

The dashboard looks for `docs/specs/**/plan.md` files **newer** than the session sentinel. If the orchestrator wrote `plan.md` before the session started, it won't be detected automatically. Workaround: press `Ctrl-C` to exit the dashboard, then run `ai-squad swarm full` which reads the existing plan directly.

### Phase 6 resume not triggered automatically

If the dashboard exits before auto-resuming, the resume command is saved to `.swarm/{session}/resume-command.txt`. Copy and run it in the orchestrator pane (Tab 1).
