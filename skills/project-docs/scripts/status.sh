#!/usr/bin/env bash
# Prints the /project-docs status table and the one next step (D30). Read-only: it never writes a file.
# Usage: bash status.sh [path/to/repo]   (default: current folder)
# Exit codes: 0 = status printed, 1 = not a git repo, 3 = the team tracks .workflow/ (stop and ask, D26).
# Tests: bash tests/project-docs/run.sh
set -euo pipefail

TARGET="${1:-.}"
if ! ROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "Not inside a git repo: $TARGET" >&2
  exit 1
fi
cd "$ROOT"

# --- Which artifact base? (D26) ---------------------------------------------------------------
if [ -n "$(git ls-files -- .workflow | head -n 1)" ]; then
  echo "STOP: .workflow/ is tracked by git, so it belongs to the team. Ask Ashley for another artifact base name before writing anything."
  exit 3
fi
# Work repo = .workflow/ exists, or CLAUDE.local.md imports @AGENTS.md or names the artifact base. The CLAUDE.local.md
# signal is the same one skills/work-ticket/SKILL.md step 2 uses to spot a team repo set up by local-setup.sh (D18, D26).
if [ -d .workflow ] \
  || { [ -f CLAUDE.local.md ] && grep -qE '@AGENTS\.md|Artifact base in this repo is' CLAUDE.local.md; }; then
  BASE=".workflow"; LABEL=".workflow/ (work repo, local only)"
else
  BASE="docs"; LABEL="docs/ (personal repo)"
fi

# --- Facts from the files ----------------------------------------------------------------------
SCOPE_FILES=""; SCOPE_COUNT=0
if [ -d "$BASE/scope" ]; then
  SCOPE_FILES="$(find "$BASE/scope" -maxdepth 2 -type f -name '*.md' | sort)"
  [ -n "$SCOPE_FILES" ] && SCOPE_COUNT="$(printf '%s\n' "$SCOPE_FILES" | wc -l | tr -d ' ')"
fi

SPEC_NUMS=""; SPEC_COUNT=0
if [ -d "$BASE/specs" ]; then
  # /architect names specs NNNN-title.md, or a folder NNNN-title/ for an umbrella (one number each).
  # Keep only lines that are exactly four digits: a file name with a newline or odd characters must never
  # reach the arithmetic below, because bash evaluates expressions like a[$(cmd)] inside (( )).
  SPEC_NUMS="$(find "$BASE/specs" -maxdepth 2 -name '[0-9][0-9][0-9][0-9]-*' \
    | sed -nE 's#.*/([0-9]{4})-[^/]*$#\1#p' | { grep -xE '[0-9]{4}' || true; } | sort -u)"
  # Only grep's "no match" (exit 1) is allowed to pass; a find error (for example an unreadable folder)
  # fails the script instead of printing "Specs: none".
  [ -n "$SPEC_NUMS" ] && SPEC_COUNT="$(printf '%s\n' "$SPEC_NUMS" | wc -l | tr -d ' ')"
fi

# "Something runs": a project manifest or start file exists. Judgement call; the skill confirms before writing.
RUNNABLE="$( { find . -maxdepth 3 \( -name .git -o -name node_modules -o -path "./$BASE" \) -prune -o -type f \
  \( -name '*.sln' -o -name '*.csproj' -o -name package.json -o -name Makefile -o -name Dockerfile \
     -o -name 'docker-compose.y*ml' -o -name 'compose.y*ml' -o -name pyproject.toml -o -name go.mod -o -name Cargo.toml \) \
  -print | head -n 1; } || true )"

# --- Per-document status -----------------------------------------------------------------------
# Sets ST_<doc> (missing|skeleton|draft|current|stale|unknown) and RS_<doc> (why it is stale).
# Stale = a scope file or spec number that the "Checked against" line does not cover. Dates are not
# compared on purpose: file times reset on every clone, which would make every document look stale.
analyze() {
  local name="$1" file="$BASE/${1//_/-}.md" status chk hi lo n f   # key test_plan -> file test-plan.md
  printf -v "ST_$name" '%s' missing; printf -v "RS_$name" '%s' ''
  [ -f "$file" ] || return 0
  status="$(grep -m1 -E '^Status:' "$file" | sed -E 's/^Status:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r' || true)"
  case "$status" in
    skeleton) printf -v "ST_$name" '%s' skeleton; return 0 ;;
    draft|current) ;;
    *) printf -v "ST_$name" '%s' unknown; return 0 ;;
  esac
  printf -v "ST_$name" '%s' "$status"
  chk="$(grep -m1 -E '^Checked against:' "$file" | tr -d '\r' || true)"
  if [ -z "$chk" ]; then
    printf -v "ST_$name" '%s' stale; printf -v "RS_$name" '%s' "it has no Checked against line"; return 0
  fi
  # specs 0001 | specs 0001-0003 | specs 0001–0003 (en dash) | specs none
  read -r lo hi <<<"$(printf '%s' "$chk" | sed -nE 's/.*specs ([0-9]{4})((–|-)([0-9]{4}))?.*/\1 \4/p')"
  hi="${hi:-${lo:-0}}"; lo="${lo:-0}"
  # Defence in depth: sed only captures four digits, but these values feed (( )), which executes
  # expressions like a[$(cmd)]. Re-check so a future edit to the pattern cannot open that hole.
  [[ $lo =~ ^[0-9]+$ ]] || lo=0
  [[ $hi =~ ^[0-9]+$ ]] || hi=0
  for n in $SPEC_NUMS; do
    [[ $n =~ ^[0-9]{4}$ ]] || continue   # same reason: SPEC_NUMS is already filtered to four digits
    # Both ends of the range count: a spec below the first listed number is not covered either.
    if (( 10#$n > 10#$hi || 10#$n < 10#$lo )); then
      printf -v "ST_$name" '%s' stale; printf -v "RS_$name" '%s' "spec $n is not in its Checked against line"; return 0
    fi
  done
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if ! printf '%s' "$chk" | grep -qF -- "$(basename "$f")"; then
      printf -v "ST_$name" '%s' stale
      printf -v "RS_$name" '%s' "scope file $(basename "$f") is not in its Checked against line"; return 0
    fi
  done <<<"$SCOPE_FILES"
}
for d in prd sdd test_plan runbook; do analyze "$d"; done

PRD_AC=no
if [ -f "$BASE/prd.md" ] && [ "$ST_prd" != skeleton ] && grep -qi 'acceptance criteria:' "$BASE/prd.md"; then PRD_AC=yes; fi

# --- "Ready when" rules (D30) --------------------------------------------------------------------
READY_prd="no: needs a scope"; [ "$SCOPE_COUNT" -gt 0 ] && READY_prd=yes
if [ "$ST_prd" = current ] && [ "$SPEC_COUNT" -gt 0 ]; then READY_sdd=yes
elif [ "$ST_prd" = current ]; then READY_sdd="no: needs one spec"
elif [ "$SPEC_COUNT" -gt 0 ]; then READY_sdd="no: needs a current PRD"
else READY_sdd="no: needs a current PRD and one spec"; fi
READY_tp="no: needs PRD acceptance criteria"; [ "$PRD_AC" = yes ] && READY_tp=yes
READY_rb="no: needs something that runs"; [ -n "$RUNNABLE" ] && READY_rb=yes

# --- Print ----------------------------------------------------------------------------------------
echo "Artifact base: $LABEL"
if [ "$SCOPE_COUNT" -eq 0 ]; then echo "Scope: none"
else echo "Scope: $BASE/scope/ ($SCOPE_COUNT file$([ "$SCOPE_COUNT" -eq 1 ] || echo s))"; fi
if [ "$SPEC_COUNT" -eq 0 ]; then echo "Specs: none"
else echo "Specs: $SPEC_COUNT ($(printf '%s\n' "$SPEC_NUMS" | paste -sd, - | sed 's/,/, /g'))"; fi
if [ -f "$BASE/decisions.md" ]; then
  rows="$(grep -c '^|' "$BASE/decisions.md" || true)"; rows=$(( rows > 2 ? rows - 2 : 0 ))
  echo "decisions.md: $rows rows (read-only)"
else echo "decisions.md: none"; fi
echo
echo "| Document | Status | Ready? |"
echo "|---|---|---|"
echo "| prd.md | $ST_prd | $READY_prd |"
echo "| sdd.md | $ST_sdd | $READY_sdd |"
echo "| test-plan.md | $ST_test_plan | $READY_tp |"
echo "| runbook.md | $ST_runbook | $READY_rb |"
echo

why_not_current() { # doc name -> sentence
  local s="ST_$1" r="RS_$1" file="${1//_/-}.md"
  case "${!s}" in
    stale) echo "$file is stale: ${!r}." ;;
    unknown) echo "$file has no readable Status line." ;;
    *) echo "$file is ${!s}." ;;
  esac
}

if [ "$SCOPE_COUNT" -eq 0 ]; then
  NEXT="/scope"; WHY="there is no scope yet, and the PRD is written from it."
elif [ "$ST_prd" != current ]; then
  NEXT="/project-docs prd"; WHY="$(why_not_current prd)"
elif [ "$PRD_AC" = no ]; then
  NEXT="/project-docs prd"; WHY="prd.md has no acceptance criteria yet."
elif [ "$SPEC_COUNT" -eq 0 ]; then
  NEXT="/architect"; WHY="sdd.md needs at least one spec first."
elif [ "$ST_sdd" != current ]; then
  NEXT="/project-docs sdd"; WHY="$(why_not_current sdd)"
elif [ "$ST_test_plan" != current ]; then
  NEXT="/project-docs test-plan"; WHY="$(why_not_current test_plan)"
elif [ "$ST_runbook" != current ] && [ -n "$RUNNABLE" ]; then
  NEXT="/project-docs runbook"; WHY="$(why_not_current runbook)"
elif [ "$ST_runbook" != current ]; then
  NEXT="none"; WHY="runbook.md waits until something runs."
else
  NEXT="none"; WHY="all documents are current."
fi
echo "Next: $NEXT"
echo "Why: $WHY"
