#!/usr/bin/env bash
# tests/template/test_commands.sh — command file validation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="$REPO_ROOT/template"
PASS=0
FAIL=0

# ─── helpers ──────────────────────────────────────────────────────────────────
ok()   { printf "  \033[1;32m✓\033[0m  %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "  \033[1;31m✗\033[0m  %s\n" "$1"; FAIL=$((FAIL + 1)); }

# ─── required commands ────────────────────────────────────────────────────────
REQUIRED_COMMANDS=(
  feature.md
  build-feature.md
  bugfix.md
  tdd.md
  validate.md
)

# ─── Claude Code commands ─────────────────────────────────────────────────────
printf "\n\033[1m  Claude Code Commands\033[0m\n\n"

for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if [[ -f "$TEMPLATE/.claude/commands/$cmd" ]]; then
    ok ".claude/commands/$cmd"
  else
    fail ".claude/commands/$cmd missing"
  fi
done

CLAUDE_CMD_COUNT=$(find "$TEMPLATE/.claude/commands" -name "*.md" | wc -l | tr -d ' ')
if [[ "$CLAUDE_CMD_COUNT" -ge 5 ]]; then
  ok "Claude Code: $CLAUDE_CMD_COUNT commands (min 5)"
else
  fail "Claude Code: $CLAUDE_CMD_COUNT commands (min 5 required)"
fi

# ─── OpenCode commands ────────────────────────────────────────────────────────
printf "\n\033[1m  OpenCode Commands\033[0m\n\n"

for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if [[ -f "$TEMPLATE/.opencode/commands/$cmd" ]]; then
    ok ".opencode/commands/$cmd"
  else
    fail ".opencode/commands/$cmd missing"
  fi
done

OC_CMD_COUNT=$(find "$TEMPLATE/.opencode/commands" -name "*.md" | wc -l | tr -d ' ')
if [[ "$OC_CMD_COUNT" -ge 5 ]]; then
  ok "OpenCode: $OC_CMD_COUNT commands (min 5)"
else
  fail "OpenCode: $OC_CMD_COUNT commands (min 5 required)"
fi

# ─── Parity check ─────────────────────────────────────────────────────────────
printf "\n\033[1m  Command Parity\033[0m\n\n"

if [[ "$CLAUDE_CMD_COUNT" -eq "$OC_CMD_COUNT" ]]; then
  ok "Command counts are mirrored: $CLAUDE_CMD_COUNT each"
else
  fail "Command count mismatch: Claude Code=$CLAUDE_CMD_COUNT OpenCode=$OC_CMD_COUNT"
fi

# ─── Content sanity checks ────────────────────────────────────────────────────
printf "\n\033[1m  Command Content\033[0m\n\n"

# /feature must reference the 8-phase pipeline
if grep -qi "phase" "$TEMPLATE/.claude/commands/feature.md" 2>/dev/null; then
  ok "feature.md references phases"
else
  fail "feature.md should reference phases"
fi

# /tdd must mention RED / GREEN
if grep -qi "red\|green" "$TEMPLATE/.claude/commands/tdd.md" 2>/dev/null; then
  ok "tdd.md references RED/GREEN"
else
  fail "tdd.md should reference RED/GREEN TDD cycle"
fi

# ─── summary ──────────────────────────────────────────────────────────────────
printf "\n  ────────────────────────────────────────\n"
printf "  \033[1;32m%d passed\033[0m  ·  " "$PASS"
if [[ "$FAIL" -gt 0 ]]; then
  printf "\033[1;31m%d failed\033[0m\n\n" "$FAIL"
  exit 1
else
  printf "\033[2m0 failed\033[0m\n\n"
fi
