#!/usr/bin/env bash
# scripts/swarm-dashboard.sh — Live TUI dashboard for Swarm v2
#
# Usage: swarm-dashboard.sh SESSION_ID SWARM_DIR PROJECT_DIR [FEATURE_DESC]
#
# Modes (auto-detected):
#   feature mode — SWARM_DIR/agents/ is empty: wait for plan.md, launch agents
#   monitor mode — SWARM_DIR/agents/ is pre-populated: go straight to live TUI
set -euo pipefail

SESSION="${1:-}"
SWARM_DIR="${2:-}"
PROJECT_DIR="${3:-}"
FEATURE_DESC="${4:-}"

[[ -z "$SESSION" ]]     && { printf 'Usage: swarm-dashboard.sh SESSION SWARM_DIR PROJECT_DIR [FEATURE]\n' >&2; exit 1; }
[[ -z "$SWARM_DIR" ]]   && { printf 'Usage: swarm-dashboard.sh SESSION SWARM_DIR PROJECT_DIR [FEATURE]\n' >&2; exit 1; }
[[ -z "$PROJECT_DIR" ]] && { printf 'Usage: swarm-dashboard.sh SESSION SWARM_DIR PROJECT_DIR [FEATURE]\n' >&2; exit 1; }

AGENTS_DIR="$SWARM_DIR/agents"
mkdir -p "$AGENTS_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="$SCRIPT_DIR/swarm-agent-wrapper.sh"

# ── terminal capabilities ─────────────────────────────────────────────────────
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
  BOLD='\033[1m'  DIM='\033[2m'   RED='\033[1;31m' GRN='\033[1;32m'
  YEL='\033[1;33m' CYN='\033[1;36m' R='\033[0m'   BLINK='\033[5m'
  CLR='\033[H\033[2J'
else
  BOLD='' DIM='' RED='' GRN='' YEL='' CYN='' R='' BLINK='' CLR=''
fi

# ── helpers ───────────────────────────────────────────────────────────────────
_elapsed() {
  local start="$1"
  local now; now=$(date -u +%s)
  local start_epoch
  # BSD date (macOS): -j -f format; GNU date (Linux): -d
  if start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$start" +%s 2>/dev/null); then
    : # macOS
  elif start_epoch=$(date -d "$start" +%s 2>/dev/null); then
    : # Linux
  else
    start_epoch="$now"
  fi
  local secs=$(( now - start_epoch ))
  printf '%02d:%02d' $(( secs / 60 )) $(( secs % 60 ))
}

_spinner() {
  local frame
  frame=$(( $(date +%s) % 4 ))
  case "$frame" in
    0) printf '|' ;;
    1) printf '/' ;;
    2) printf '-' ;;
    *) printf '%c' 92 ;;   # 92 = ASCII backslash
  esac
}

# ── detect mode ───────────────────────────────────────────────────────────────
AGENT_NAMES=()
EXISTING_COUNT=0
for _d in "$AGENTS_DIR"/*/; do
  [[ -d "$_d" ]] && EXISTING_COUNT=$((EXISTING_COUNT + 1))
done

if [[ "$EXISTING_COUNT" -gt 0 ]]; then
  # Monitor mode: agents already launched by swarm full/tasks
  for _d in "$AGENTS_DIR"/*/; do
    [[ -d "$_d" ]] && AGENT_NAMES+=("$(basename "$_d")")
  done
  printf '\n  %bAI Squad  —  %s%b  (monitor mode)\n' "$BOLD" "$SESSION" "$R"
  printf '  %d agents pre-launched — monitoring...\n\n' "${#AGENT_NAMES[@]}"
  PLAN_FILE=""

else
  # Feature mode: wait for plan.md, then launch agents
  SENTINEL="$SWARM_DIR/sentinel"
  printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$SENTINEL"
  PLAN_FILE=""

  printf '\n  %bAI Squad  —  %s%b\n' "$BOLD" "$SESSION" "$R"
  [[ -n "$FEATURE_DESC" ]] && printf '  %b%s%b\n' "$DIM" "$FEATURE_DESC" "$R"
  printf '\n  Watching for plan.md (from orchestrator)...\n'

  # Phase A: wait for plan.md newer than sentinel
  while [[ -z "$PLAN_FILE" ]]; do
    PLAN_FILE=$(find "$PROJECT_DIR/docs/specs" -name "plan.md" \
                     -newer "$SENTINEL" 2>/dev/null | head -1 || true)
    [[ -n "$PLAN_FILE" ]] && break
    sleep 3
    printf '.'
  done
  rm -f "$SENTINEL"

  printf '\n\n  Plan: %b%s%b\n' "$GRN" "$PLAN_FILE" "$R"
  printf '  Press Enter to launch agents now, or wait 10s for auto-launch.\n'
  printf '  (Ctrl+C cancels the swarm — orchestrator keeps running)\n'
  read -r -t 10 || true

  # Phase B: launch agents
  printf '\n  Launching swarm agents...\n\n'
  TAB_INDEX=2   # Tab 1 = orchestrator/dashboard; agents start at Tab 2

  # Parse tasks: primary format `- [ ] Task N: @agent desc`;
  # fallback: `### TASK-NNN — Title` + `**Agent:** \`agent\`` sections.
  _parse_plan_tasks() {
    local _pf="$1"
    if grep -qE '^\- \[ \] Task [0-9]+:' "$_pf" 2>/dev/null; then
      grep -E '^\- \[ \] Task [0-9]+:' "$_pf"
      return
    fi
    local _title="" _agent="" _tnum=0
    while IFS= read -r _pl; do
      if printf '%s' "$_pl" | grep -qE '^### TASK-[0-9]'; then
        _tnum=$((_tnum + 1))
        _title=$(printf '%s' "$_pl" | sed 's/^### TASK-[0-9][0-9]* \(— \)*//')
        _agent=""
      elif [[ -n "$_title" ]] && printf '%s' "$_pl" | grep -qE '^\*\*Agent:\*\*'; then
        _agent=$(printf '%s' "$_pl" | tr '`' '\n' | sed -n '2p')
        printf '- [ ] Task %d: @%s %s\n' "$_tnum" "$_agent" "$_title"
        _title=""
      fi
    done < "$_pf" || true
  }

  while IFS= read -r task_line; do
    _agent=$(printf '%s' "$task_line" | grep -oE '@[a-zA-Z0-9_-]+' | head -1)
    _desc=$(printf '%s' "$task_line" | sed "s/.*${_agent}//" | sed 's/^[[:space:]]*//')
    _agent_name="${_agent#@}"
    _task_num="${#AGENT_NAMES[@]}"
    _task_num=$((_task_num + 1))
    _tab_name="${_agent_name}-${_task_num}"
    AGENT_NAMES+=("${_agent_name}-${_task_num}")

    # Initialise agent dir so dashboard shows it immediately
    _local_agent_dir="$AGENTS_DIR/${_agent_name}-${_task_num}"
    mkdir -p "$_local_agent_dir"
    printf '%s\n' "$_desc"     > "$_local_agent_dir/task.md"
    printf 'pending\n'         > "$_local_agent_dir/status"
    printf 'swarm/%s/%s-%s\n' "$SESSION" "$_agent_name" "$_task_num" \
                               > "$_local_agent_dir/branch"

    # Launch new Zellij tab with wrapper
    if [[ -n "${ZELLIJ:-}" ]]; then
      zellij action new-tab --name "$_tab_name" --cwd "$PROJECT_DIR"
      sleep 0.3
      _cmd="bash \"$WRAPPER\" --session \"$SESSION\" --agent \"$_agent_name\""
      _cmd="$_cmd --task-num \"$_task_num\" --prompt \"$_desc\""
      _cmd="$_cmd --project-dir \"$PROJECT_DIR\" --swarm-dir \"$SWARM_DIR\""
      zellij action write-chars "$_cmd"
      sleep 0.1
      zellij action write 13
    else
      printf '  [NOT IN ZELLIJ] would launch: @%s task %s\n' \
        "$_agent_name" "$_task_num"
    fi

    printf '  Tab %-3s  %b@%s%b  %s\n' "$TAB_INDEX" "$CYN" "$_agent_name" "$R" "$_desc"
    TAB_INDEX=$((TAB_INDEX + 1))
  done < <(_parse_plan_tasks "$PLAN_FILE")

  TOTAL="${#AGENT_NAMES[@]}"
  if [[ "$TOTAL" -eq 0 ]]; then
    printf '  No tasks found in plan.md\n' >&2
    exit 1
  fi

  printf '\n  %d agents launched. Starting monitor...\n' "$TOTAL"
  sleep 2
fi

# ── Phase C: live dashboard loop ─────────────────────────────────────────────
TOTAL="${#AGENT_NAMES[@]}"
# Track previous status per agent via temp files (bash 3.2 compatible — no declare -A)
PREV_STATUS_DIR="$(mktemp -d)"
trap 'rm -rf "$PREV_STATUS_DIR"' EXIT

while true; do
  printf '%b' "$CLR"
  printf '  %bAI Squad  —  %s%b\n' "$BOLD" "$SESSION" "$R"
  [[ -n "$FEATURE_DESC" ]] && printf '  %b%s%b\n' "$DIM" "$FEATURE_DESC" "$R"
  [[ -n "$PLAN_FILE" ]]    && printf '  %bPlan: %s%b\n' "$DIM" "$PLAN_FILE" "$R"
  printf '\n'
  printf '  %-4s %-24s %-8s %-8s %-6s %s\n' \
    "TAB" "AGENT" "STATUS" "ELAPSED" "EXIT" "NAV"
  printf '  ──── ──────────────────────── ──────── ──────── ────── ──────\n'

  DONE_COUNT=0 RUNNING_COUNT=0 ERROR_COUNT=0 PENDING_COUNT=0
  IDX=2
  for _agent_key in "${AGENT_NAMES[@]}"; do
    _agent_dir="$AGENTS_DIR/$_agent_key"
    _status="pending"
    _elapsed_str="--:--"
    _exit_code="---"

    [[ -f "$_agent_dir/status" ]]     && _status="$(cat "$_agent_dir/status")"
    [[ -f "$_agent_dir/started_at" ]] && _elapsed_str="$(_elapsed "$(cat "$_agent_dir/started_at")")"
    [[ -f "$_agent_dir/exit_code" ]]  && _exit_code="$(cat "$_agent_dir/exit_code")"

    case "$_status" in
      done)    _icon="${GRN}[✓]${R}" _color="$GRN"; DONE_COUNT=$((DONE_COUNT+1)) ;;
      running) _icon="${YEL}[$(_spinner)]${R}" _color="$YEL"; RUNNING_COUNT=$((RUNNING_COUNT+1)) ;;
      error)   _icon="${RED}[✗]${R}" _color="$RED"; ERROR_COUNT=$((ERROR_COUNT+1)) ;;
      *)       _icon="${DIM}[ ]${R}" _color="$DIM"; PENDING_COUNT=$((PENDING_COUNT+1)) ;;
    esac

    # Detect stalled agents: running > 90s with no worktree file changes
    if [[ "$_status" == "running" ]]; then
      _worktree="$_agent_dir/worktree"
      if [[ -d "$_worktree" ]]; then
        _recent=$(find "$_worktree" -newer "$_agent_dir/started_at" \
                       -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$_recent" -eq 0 ]]; then
          _icon="${BLINK}${YEL}[⚠]${R}"
        fi
      fi
    fi

    _nav="Alt-${IDX}"
    printf '  %b%-24s%b %-8s %-8s %-6s %s\n' \
      "$_color" "$_agent_key" "$R" "$_status" "$_elapsed_str" "$_exit_code" "$_nav"

    # Rename Zellij tab when status changes (file-based tracking, bash 3.2 safe)
    _prev_file="$PREV_STATUS_DIR/${_agent_key}"
    _prev="$(cat "$_prev_file" 2>/dev/null || printf '')"
    if [[ "$_prev" != "$_status" && -n "${ZELLIJ:-}" ]]; then
      case "$_status" in
        done)    zellij action rename-tab "✓ $_agent_key" 2>/dev/null || true ;;
        error)   zellij action rename-tab "✗ $_agent_key" 2>/dev/null || true ;;
        running) zellij action rename-tab "↻ $_agent_key" 2>/dev/null || true ;;
      esac
    fi
    printf '%s' "$_status" > "$_prev_file"

    IDX=$((IDX + 1))
  done

  printf '\n  ────────────────────────────────────────\n'
  printf '  %b%d/%d done%b  ·  %d running  ·  %d error  ·  %d pending\n' \
    "$GRN" "$DONE_COUNT" "$TOTAL" "$R" "$RUNNING_COUNT" "$ERROR_COUNT" "$PENDING_COUNT"
  printf '  %bAlt-1%b = dashboard  %bAlt-2+%b = agents  %bCtrl-o d%b = detach\n' \
    "$DIM" "$R" "$DIM" "$R" "$DIM" "$R"

  # Check if all agents are complete
  COMPLETE_COUNT=$((DONE_COUNT + ERROR_COUNT))
  if [[ "$COMPLETE_COUNT" -eq "$TOTAL" && "$TOTAL" -gt 0 ]]; then
    printf '\n  %bAll %d agents complete.%b\n' "$BOLD" "$TOTAL" "$R"
    break
  fi

  sleep 2
done

# ── Phase D: all complete — resume orchestrator for Phase 6 ──────────────────
printf '\n  %bPhase 6: resuming orchestrator for merge + validate...%b\n\n' \
  "$BOLD" "$R"

RESUME_PROMPT="Swarm Mode Phase 6 Resume. Session: ${SESSION}."
RESUME_PROMPT="$RESUME_PROMPT Swarm dir: ${SWARM_DIR}."
RESUME_PROMPT="$RESUME_PROMPT All agents have completed."
RESUME_PROMPT="$RESUME_PROMPT Read .swarm/${SESSION}/agents/*/result.md for agent results"
RESUME_PROMPT="$RESUME_PROMPT and .swarm/${SESSION}/agents/*/status to identify errors."
RESUME_PROMPT="$RESUME_PROMPT Run: bash scripts/swarm-merge.sh ${SESSION} ${SWARM_DIR} ${PROJECT_DIR}"
RESUME_PROMPT="$RESUME_PROMPT Then continue to Phase 6 (validate), Phase 7 (document), Phase 8 (PR)."

# Save resume command to a file for reliable handoff
printf 'claude --agent orchestrator "%s"\n' "$RESUME_PROMPT" \
  > "$SWARM_DIR/resume-command.txt"

sleep 2

# Try to auto-resume in Tab 1 (best effort — only works if orchestrator pane is focused)
if [[ -n "${ZELLIJ:-}" ]]; then
  zellij action go-to-tab 1 2>/dev/null || true
  sleep 0.5
  zellij action write-chars "claude --agent orchestrator \"$RESUME_PROMPT\"" 2>/dev/null || true
  sleep 0.1
  zellij action write 13 2>/dev/null || true
fi

printf '  Resume command saved to: %s/resume-command.txt\n\n' "$SWARM_DIR"
