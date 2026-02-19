#!/usr/bin/env bash
# scripts/swarm-merge.sh — Merge completed swarm agent branches into the current branch
#
# Usage: swarm-merge.sh SESSION_ID SWARM_DIR PROJECT_DIR
set -euo pipefail

SESSION="${1:-}"
SWARM_DIR="${2:-}"
PROJECT_DIR="${3:-}"

[[ -z "$SESSION" ]]     && { printf 'Usage: swarm-merge.sh SESSION SWARM_DIR PROJECT_DIR\n' >&2; exit 1; }
[[ -z "$SWARM_DIR" ]]   && { printf 'Usage: swarm-merge.sh SESSION SWARM_DIR PROJECT_DIR\n' >&2; exit 1; }
[[ -z "$PROJECT_DIR" ]] && { printf 'Usage: swarm-merge.sh SESSION SWARM_DIR PROJECT_DIR\n' >&2; exit 1; }

AGENTS_DIR="$SWARM_DIR/agents"
[[ -d "$AGENTS_DIR" ]] || { printf 'No agents dir: %s\n' "$AGENTS_DIR" >&2; exit 1; }

cd "$PROJECT_DIR"

MERGED=0 SKIPPED=0 CONFLICTED=0

printf '\n  Merging swarm session: %s\n\n' "$SESSION"

for AGENT_DIR in "$AGENTS_DIR"/*/; do
  [[ -d "$AGENT_DIR" ]] || continue
  AGENT_NAME="$(basename "$AGENT_DIR")"
  STATUS_FILE="$AGENT_DIR/status"
  EXIT_FILE="$AGENT_DIR/exit_code"
  BRANCH_FILE="$AGENT_DIR/branch"

  if [[ ! -f "$STATUS_FILE" ]]; then
    printf '  [skip]  %-30s — no status file\n' "$AGENT_NAME"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  STATUS="$(cat "$STATUS_FILE")"
  if [[ "$STATUS" != "done" ]]; then
    printf '  [skip]  %-30s — status: %s\n' "$AGENT_NAME" "$STATUS"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  EXIT_CODE="0"
  [[ -f "$EXIT_FILE" ]] && EXIT_CODE="$(cat "$EXIT_FILE")"
  if [[ "$EXIT_CODE" != "0" ]]; then
    printf '  [skip]  %-30s — exit code: %s\n' "$AGENT_NAME" "$EXIT_CODE"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  BRANCH=""
  [[ -f "$BRANCH_FILE" ]] && BRANCH="$(cat "$BRANCH_FILE")"
  if [[ -z "$BRANCH" ]]; then
    printf '  [skip]  %-30s — no branch file\n' "$AGENT_NAME"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Check branch exists
  if ! git rev-parse --verify "$BRANCH" &>/dev/null; then
    printf '  [skip]  %-30s — branch not found: %s\n' "$AGENT_NAME" "$BRANCH"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Check branch has commits beyond merge base
  MERGE_BASE="$(git merge-base HEAD "$BRANCH" 2>/dev/null || true)"
  BRANCH_TIP="$(git rev-parse "$BRANCH")"
  if [[ -n "$MERGE_BASE" && "$MERGE_BASE" = "$BRANCH_TIP" ]]; then
    printf '  [skip]  %-30s — no new commits\n' "$AGENT_NAME"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Attempt merge
  if git merge --no-ff "$BRANCH" \
       -m "feat: merge swarm agent ${AGENT_NAME} (session ${SESSION})" 2>/dev/null; then
    printf '  [merge] %-30s — %s\n' "$AGENT_NAME" "$BRANCH"
    MERGED=$((MERGED + 1))
    # Clean up worktree and branch
    WORKTREE_DIR="$AGENT_DIR/worktree"
    if [[ -d "$WORKTREE_DIR" ]]; then
      git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    fi
    git branch -d "$BRANCH" 2>/dev/null || true
  else
    git merge --abort 2>/dev/null || true
    printf '  [conflict] %-27s — merge conflict, skipped\n' "$AGENT_NAME"
    printf 'merge-conflict' > "$AGENT_DIR/merge-conflict"
    CONFLICTED=$((CONFLICTED + 1))
  fi
done

printf '\n  ────────────────────────────────────────\n'
printf '  %d merged  ·  %d skipped  ·  %d conflicted\n\n' \
  "$MERGED" "$SKIPPED" "$CONFLICTED"

if [[ "$CONFLICTED" -gt 0 ]]; then
  printf '  Resolve conflicts manually then run:\n'
  for AGENT_DIR in "$AGENTS_DIR"/*/; do
    [[ -f "$AGENT_DIR/merge-conflict" ]] || continue
    BRANCH=""
    [[ -f "$AGENT_DIR/branch" ]] && BRANCH="$(cat "$AGENT_DIR/branch")"
    printf '    git merge --no-ff %s\n' "$BRANCH"
  done
  printf '\n'
  exit 1
fi
