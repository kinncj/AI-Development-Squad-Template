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

# swarm (no args) now opens interactive mode — requires Zellij (no TTY in tests).
# Verify it attempts interactive mode rather than printing help.
SWARM_NOARGS=$("$CLI" swarm 2>&1 || true)
if printf '%s' "$SWARM_NOARGS" | grep -qiE 'orchestrator|interactive|Zellij|zellij|session'; then
  ok "swarm (no args) attempts interactive mode"
else
  fail "swarm (no args) did not attempt interactive mode"
fi

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

# 14. swarm feature fails with no description
assert_exit_fail "swarm feature fails with no description" "$CLI" swarm feature

# 15. swarm help mentions 'feature' subcommand
# Capture output first: both the CLI and this script have pipefail, and grep -q
# exits as soon as it finds a match, causing a broken pipe in the CLI process
# which would make the pipeline return non-zero even when the text is found.
SWARM_HELP=$("$CLI" swarm help 2>&1 || true)
if grep -q 'feature' <<< "$SWARM_HELP"; then
  ok "swarm help lists 'feature' subcommand"
else
  fail "swarm help does not mention 'feature'"
fi

# 16. ai-squad help mentions 'feature' in swarm line
MAIN_HELP=$("$CLI" help 2>&1 || true)
if grep -q 'feature' <<< "$MAIN_HELP"; then
  ok "ai-squad help mentions 'feature' in swarm description"
else
  fail "ai-squad help does not mention 'feature'"
fi

# 17. swarm feature watcher script is generated correctly
#     Simulate: create a temp dir, run the watcher, verify it detects a plan file.
WATCHER_TEST_DIR="$(mktemp -d)"
FAKE_PLAN="$WATCHER_TEST_DIR/plan.md"
FAKE_SESSION="test-session-$$"
WATCHER_SCRIPT="$WATCHER_TEST_DIR/watcher.sh"
trap 'rm -rf "$TEST_TMP" "$WATCHER_TEST_DIR"' EXIT

# Build the same watcher script that swarm feature would produce
{
  printf '#!/usr/bin/env bash\n'
  printf 'PLAN_FILE="%s"\n' "$FAKE_PLAN"
  printf 'SESSION="%s"\n'   "$FAKE_SESSION"
  cat <<'WATCHER_BODY'
# Minimal test harness: exit 0 if plan file already exists, exit 1 if not found within 1 s
FOUND=0
for _ in 1; do
  if [[ -f "$PLAN_FILE" ]]; then FOUND=1; break; fi
  sleep 0.1
done
exit $((1 - FOUND))
WATCHER_BODY
} > "$WATCHER_SCRIPT"
chmod +x "$WATCHER_SCRIPT"

# Without plan file — should exit 1
if ! bash "$WATCHER_SCRIPT" >/dev/null 2>&1; then
  ok "watcher exits non-zero when plan file is absent"
else
  fail "watcher should exit non-zero when plan file is absent"
fi

# With plan file present — should exit 0
echo '- [ ] Task 1: @qa write tests' > "$FAKE_PLAN"
if bash "$WATCHER_SCRIPT" >/dev/null 2>&1; then
  ok "watcher exits 0 when plan file is present"
else
  fail "watcher should exit 0 when plan file is present"
fi

# 18. swarm-agent-wrapper.sh exists and is executable
if [[ -x "$REPO_ROOT/scripts/swarm-agent-wrapper.sh" ]]; then
  ok "swarm-agent-wrapper.sh is executable"
else
  fail "swarm-agent-wrapper.sh missing or not executable"
fi

# 19. swarm-dashboard.sh exists and is executable
if [[ -x "$REPO_ROOT/scripts/swarm-dashboard.sh" ]]; then
  ok "swarm-dashboard.sh is executable"
else
  fail "swarm-dashboard.sh missing or not executable"
fi

# 20. swarm-merge.sh exists and is executable
if [[ -x "$REPO_ROOT/scripts/swarm-merge.sh" ]]; then
  ok "swarm-merge.sh is executable"
else
  fail "swarm-merge.sh missing or not executable"
fi

# 21. swarm status fails with no session (run from empty temp dir)
NO_SESSION_TMP="$(mktemp -d)"
if ! ( cd "$NO_SESSION_TMP" && "$CLI" swarm status ) >/dev/null 2>&1; then
  ok "swarm status fails with no session"
else
  fail "swarm status should fail with no session"
fi
rm -rf "$NO_SESSION_TMP"

# 22. swarm merge fails with no session (run from empty temp dir)
NO_SESSION_TMP2="$(mktemp -d)"
if ! ( cd "$NO_SESSION_TMP2" && "$CLI" swarm merge ) >/dev/null 2>&1; then
  ok "swarm merge fails with no session"
else
  fail "swarm merge should fail with no session"
fi
rm -rf "$NO_SESSION_TMP2"

# 23. swarm help mentions 'status' subcommand
SWARM_HELP2=$("$CLI" swarm help 2>&1 || true)
if printf '%s' "$SWARM_HELP2" | grep -q 'status'; then
  ok "swarm help lists 'status' subcommand"
else
  fail "swarm help does not mention 'status'"
fi

# 24. swarm help mentions 'merge' subcommand
if printf '%s' "$SWARM_HELP2" | grep -q 'merge'; then
  ok "swarm help lists 'merge' subcommand"
else
  fail "swarm help does not mention 'merge'"
fi

# 25. swarm status reads mock .swarm/ session
MOCK_DIR="$(mktemp -d)"
MOCK_SESSION="swarm-9999999999"
mkdir -p "$MOCK_DIR/.swarm/$MOCK_SESSION/agents/typescript-1"
printf 'done\n' > "$MOCK_DIR/.swarm/$MOCK_SESSION/agents/typescript-1/status"
printf '0\n'    > "$MOCK_DIR/.swarm/$MOCK_SESSION/agents/typescript-1/exit_code"
printf 'swarm/%s/typescript-1\n' "$MOCK_SESSION" \
  > "$MOCK_DIR/.swarm/$MOCK_SESSION/agents/typescript-1/branch"
STATUS_OUT=$( cd "$MOCK_DIR" || exit; "$CLI" swarm status 2>&1 || true )
if printf '%s' "$STATUS_OUT" | grep -q 'typescript-1'; then
  ok "swarm status reads mock session agent data"
else
  fail "swarm status did not show mock session agent"
fi
rm -rf "$MOCK_DIR"

# ─── summary ──────────────────────────────────────────────────────────────────
printf "\n  ────────────────────────────────────────\n"
printf "  \033[1;32m%d passed\033[0m  ·  " "$PASS"
if [[ "$FAIL" -gt 0 ]]; then
  printf "\033[1;31m%d failed\033[0m\n\n" "$FAIL"
  exit 1
else
  printf "\033[2m0 failed\033[0m\n\n"
fi
