#!/usr/bin/env bash
# scripts/swarm-agent-wrapper.sh — Per-agent wrapper for Swarm v2
# Runs inside each Zellij tab: sets up a git worktree, runs claude, collects results.
#
# Usage:
#   swarm-agent-wrapper.sh \
#     --session  SESSION_ID \
#     --agent    AGENT_NAME \
#     --task-num N \
#     --prompt   "task description" \
#     --project-dir /path/to/project \
#     --swarm-dir   /path/to/.swarm/SESSION
set -euo pipefail

# ── argument parsing ──────────────────────────────────────────────────────────
SESSION="" AGENT="" TASK_NUM="" PROMPT="" PROJECT_DIR="" SWARM_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)     SESSION="$2";     shift 2 ;;
    --agent)       AGENT="$2";       shift 2 ;;
    --task-num)    TASK_NUM="$2";    shift 2 ;;
    --prompt)      PROMPT="$2";      shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --swarm-dir)   SWARM_DIR="$2";   shift 2 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
done

[[ -z "$SESSION" ]]     && { printf 'ERROR: --session required\n'     >&2; exit 1; }
[[ -z "$AGENT" ]]       && { printf 'ERROR: --agent required\n'       >&2; exit 1; }
[[ -z "$TASK_NUM" ]]    && { printf 'ERROR: --task-num required\n'    >&2; exit 1; }
[[ -z "$PROMPT" ]]      && { printf 'ERROR: --prompt required\n'      >&2; exit 1; }
[[ -z "$PROJECT_DIR" ]] && { printf 'ERROR: --project-dir required\n' >&2; exit 1; }
[[ -z "$SWARM_DIR" ]]   && { printf 'ERROR: --swarm-dir required\n'   >&2; exit 1; }

# ── derived paths ─────────────────────────────────────────────────────────────
AGENT_DIR="$SWARM_DIR/agents/${AGENT}-${TASK_NUM}"
WORKTREE_DIR="$AGENT_DIR/worktree"
BRANCH="swarm/${SESSION}/${AGENT}-${TASK_NUM}"

# ── helpers ───────────────────────────────────────────────────────────────────
_write_status() {
  # Atomic write: write to .tmp then rename to prevent partial reads
  local tmp="$AGENT_DIR/status.tmp"
  printf '%s\n' "$1" > "$tmp"
  mv "$tmp" "$AGENT_DIR/status"
}

_iso_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ── Phase 1: initialise agent directory ──────────────────────────────────────
mkdir -p "$AGENT_DIR"
printf '%s\n' "$PROMPT"      > "$AGENT_DIR/task.md"
printf '%s\n' "$BRANCH"      > "$AGENT_DIR/branch"
printf '%s\n' "$(_iso_now)"  > "$AGENT_DIR/started_at"
_write_status "pending"

printf '\n  Agent : %s\n'   "$AGENT"
printf '  Task  : %s\n'     "$TASK_NUM"
printf '  Branch: %s\n\n'   "$BRANCH"

# ── Phase 2: create git worktree ─────────────────────────────────────────────
cd "$PROJECT_DIR"
if git worktree list 2>/dev/null | grep -qF "$WORKTREE_DIR"; then
  printf '  Worktree already exists — reusing.\n'
else
  git worktree add "$WORKTREE_DIR" -b "$BRANCH" 2>&1 || \
  git worktree add "$WORKTREE_DIR" "$BRANCH"    2>&1 || {
    printf '  ERROR: could not create git worktree\n' >&2
    _write_status "error"
    exit 1
  }
fi
_write_status "running"

# ── Phase 3: run claude in the worktree ──────────────────────────────────────
cd "$WORKTREE_DIR"
EXIT_CODE=0
claude --agent "$AGENT" "$PROMPT" || EXIT_CODE=$?

# ── Phase 4: record outcome ──────────────────────────────────────────────────
printf '%s\n' "$EXIT_CODE"    > "$AGENT_DIR/exit_code"
printf '%s\n' "$(_iso_now)"   > "$AGENT_DIR/finished_at"
if [[ "$EXIT_CODE" -eq 0 ]]; then
  _write_status "done"
  TAB_LABEL="done ${AGENT}-${TASK_NUM}"
else
  _write_status "error"
  TAB_LABEL="ERR ${AGENT}-${TASK_NUM}"
fi

# ── Phase 5: generate result.md ──────────────────────────────────────────────
MERGE_BASE="$(git -C "$PROJECT_DIR" merge-base HEAD "$BRANCH" 2>/dev/null || printf 'HEAD')"
{
  printf '# Result: %s (Task %s)\n\n' "$AGENT" "$TASK_NUM"
  printf '- **status**: %s\n'     "$(cat "$AGENT_DIR/status")"
  printf '- **exit_code**: %d\n'  "$EXIT_CODE"
  # shellcheck disable=SC2016 # backticks are literal markdown, not bash expansions
  printf '- **branch**: `%s`\n'   "$BRANCH"
  printf '- **started**: %s\n'    "$(cat "$AGENT_DIR/started_at")"
  printf '- **finished**: %s\n\n' "$(_iso_now)"
  # shellcheck disable=SC2016 # backtick fences are literal markdown
  printf '## Changes\n\n```\n'
  git -C "$WORKTREE_DIR" diff --stat "$MERGE_BASE" 2>/dev/null || printf '(no diff available)\n'
  # shellcheck disable=SC2016 # backtick fences are literal markdown
  printf '```\n\n## Commits\n\n```\n'
  git -C "$WORKTREE_DIR" log --oneline "${MERGE_BASE}..HEAD" 2>/dev/null || printf '(no commits)\n'
  # shellcheck disable=SC2016 # backtick fence is literal markdown
  printf '```\n'
} > "$AGENT_DIR/result.md"

# ── Phase 6: rename Zellij tab ───────────────────────────────────────────────
if [[ -n "${ZELLIJ:-}" ]]; then
  zellij action rename-tab "$TAB_LABEL" 2>/dev/null || true
fi

printf '\n  ── %s ──\n' "$TAB_LABEL"
exit "$EXIT_CODE"
