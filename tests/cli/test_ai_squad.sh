#!/usr/bin/env bash
# tests/cli/test_ai_squad.sh — CLI smoke tests for ai-squad
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="$REPO_ROOT/scripts/ai-squad"
TEMPLATE_DIR="$REPO_ROOT/template"
PASS=0
FAIL=0

# ─── helpers ──────────────────────────────────────────────────────────────────
ok()   { printf "  \033[1;32m✓\033[0m  %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "  \033[1;31m✗\033[0m  %s\n" "$1"; FAIL=$((FAIL + 1)); }

assert_exit_ok() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label (expected exit 0, got $?)"
  fi
}

assert_exit_fail() {
  local label="$1"; shift
  if ! "$@" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "$label (expected non-zero exit, got 0)"
  fi
}

# ─── tests ────────────────────────────────────────────────────────────────────
printf "\n\033[1m  CLI Tests\033[0m  →  %s\n\n" "$CLI"

# 1. Executable
if [[ -x "$CLI" ]]; then
  ok "ai-squad is executable"
else
  fail "ai-squad is not executable"
fi

# 2. help exits 0
assert_exit_ok  "ai-squad help exits 0"         "$CLI" help
assert_exit_ok  "ai-squad --help exits 0"       "$CLI" --help
assert_exit_ok  "ai-squad -h exits 0"           "$CLI" -h

# 3. swarm help exits 0
assert_exit_ok  "ai-squad swarm help exits 0"   "$CLI" swarm help
assert_exit_ok  "ai-squad swarm (no args) exits 0" "$CLI" swarm

# 4. Unknown command exits non-zero
assert_exit_fail "unknown command exits non-zero" "$CLI" totally-not-a-command

# 5. swarm full fails without plan file
if ! PLAN_FILE="/tmp/does-not-exist-$$.md" "$CLI" swarm full >/dev/null 2>&1; then
  ok "swarm full fails without plan file"
else
  fail "swarm full should fail without plan file"
fi

# 6. swarm tasks fails without arguments
assert_exit_fail "swarm tasks fails with no task numbers" "$CLI" swarm tasks

# 7. swarm agent fails with too few arguments
assert_exit_fail "swarm agent fails with too few args" "$CLI" swarm agent

# 8. init copies template files
TEST_TMP="$(mktemp -d)"
TEST_PROJECT="$TEST_TMP/test-project"
trap 'rm -rf "$TEST_TMP"' EXIT

# Pipe "n" to skip labels prompt; pass absolute path to init
printf 'n\n' | "$CLI" init "$TEST_PROJECT" >/dev/null 2>&1 || true

if [[ -d "$TEST_PROJECT" ]]; then
  ok "init creates project directory"
else
  fail "init did not create project directory"
fi

# 9. init copies Claude Code agents
CLAUDE_AGENTS="$TEST_PROJECT/.claude/agents"
if [[ -d "$CLAUDE_AGENTS" ]]; then
  COUNT=$(find "$CLAUDE_AGENTS" -name "*.md" | wc -l | tr -d ' ')
  EXPECTED=$(find "$TEMPLATE_DIR/.claude/agents" -name "*.md" | wc -l | tr -d ' ')
  if [[ "$COUNT" -eq "$EXPECTED" ]]; then
    ok "init copies $COUNT Claude Code agent files"
  else
    fail "init copied $COUNT agents, expected $EXPECTED"
  fi
else
  fail "init did not create .claude/agents/"
fi

# 10. init copies OpenCode agents
OC_AGENTS="$TEST_PROJECT/.opencode/agents"
if [[ -d "$OC_AGENTS" ]]; then
  COUNT=$(find "$OC_AGENTS" -name "*.md" | wc -l | tr -d ' ')
  EXPECTED=$(find "$TEMPLATE_DIR/.opencode/agents" -name "*.md" | wc -l | tr -d ' ')
  if [[ "$COUNT" -eq "$EXPECTED" ]]; then
    ok "init copies $COUNT OpenCode agent files"
  else
    fail "init copied $COUNT agents, expected $EXPECTED"
  fi
else
  fail "init did not create .opencode/agents/"
fi

# 11. init copies Makefile
if [[ -f "$TEST_PROJECT/Makefile" ]]; then
  ok "init copies Makefile"
else
  fail "init did not copy Makefile"
fi

# 12. init copies CLAUDE.md
if [[ -f "$TEST_PROJECT/CLAUDE.md" ]]; then
  ok "init copies CLAUDE.md"
else
  fail "init did not copy CLAUDE.md"
fi

# 13. init copies opencode.json
if [[ -f "$TEST_PROJECT/opencode.json" ]]; then
  ok "init copies opencode.json"
else
  fail "init did not copy opencode.json"
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
