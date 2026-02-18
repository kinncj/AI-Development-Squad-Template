#!/usr/bin/env bash
# tests/template/test_skills.sh — skill file validation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="$REPO_ROOT/template"
PASS=0
FAIL=0

# ─── helpers ──────────────────────────────────────────────────────────────────
ok()   { printf "  \033[1;32m✓\033[0m  %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "  \033[1;31m✗\033[0m  %s\n" "$1"; FAIL=$((FAIL + 1)); }

# ─── required skills ──────────────────────────────────────────────────────────
REQUIRED_SKILLS=(
  tdd-workflow
  playwright-cli
  github-cli
  mermaid-diagrams
  docker-patterns
  finops-review
  jupyter-patterns
  kubernetes-patterns
  postgresql-patterns
  redis-patterns
  rfc-adr
  sre-review
  stripe-patterns
  supabase-patterns
  terraform-patterns
  threat-modeling
  vercel-patterns
)

# ─── Claude Code skills ───────────────────────────────────────────────────────
printf "\n\033[1m  Claude Code Skills\033[0m\n\n"

for skill in "${REQUIRED_SKILLS[@]}"; do
  p="$TEMPLATE/.claude/skills/$skill"
  # Skills can be files or directories (some are directories with content)
  if [[ -e "$p" ]]; then
    ok ".claude/skills/$skill"
  else
    fail ".claude/skills/$skill missing"
  fi
done

# Minimum count
CLAUDE_SKILL_COUNT=$(find "$TEMPLATE/.claude/skills" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
if [[ "$CLAUDE_SKILL_COUNT" -ge 17 ]]; then
  ok "Claude Code: $CLAUDE_SKILL_COUNT skills (min 17)"
else
  fail "Claude Code: $CLAUDE_SKILL_COUNT skills (min 17 required)"
fi

# ─── OpenCode skills ──────────────────────────────────────────────────────────
printf "\n\033[1m  OpenCode Skills\033[0m\n\n"

for skill in "${REQUIRED_SKILLS[@]}"; do
  p="$TEMPLATE/.opencode/skills/$skill"
  if [[ -e "$p" ]]; then
    ok ".opencode/skills/$skill"
  else
    fail ".opencode/skills/$skill missing"
  fi
done

OC_SKILL_COUNT=$(find "$TEMPLATE/.opencode/skills" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
if [[ "$OC_SKILL_COUNT" -ge 17 ]]; then
  ok "OpenCode: $OC_SKILL_COUNT skills (min 17)"
else
  fail "OpenCode: $OC_SKILL_COUNT skills (min 17 required)"
fi

# ─── Parity check ─────────────────────────────────────────────────────────────
printf "\n\033[1m  Skill Parity\033[0m\n\n"

if [[ "$CLAUDE_SKILL_COUNT" -eq "$OC_SKILL_COUNT" ]]; then
  ok "Skill counts are mirrored: $CLAUDE_SKILL_COUNT each"
else
  fail "Skill count mismatch: Claude Code=$CLAUDE_SKILL_COUNT OpenCode=$OC_SKILL_COUNT"
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
