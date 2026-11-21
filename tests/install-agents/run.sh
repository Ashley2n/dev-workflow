#!/usr/bin/env bash
# Tests for the install.sh step that copies the vendored scout and researcher agents
# into ~/.claude/agents/ (D56), and for the local-only ticket files in a team repo (D65(c)).
# install.sh runs end to end against a fake HOME whose path has a space, with stub
# npx/claude/dotnet on PATH. Nothing is written to the repo or the real ~/.claude.
# Usage: bash tests/install-agents/run.sh [case-name ...]   (default: all)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SRC="$REPO/templates/agents"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/install-agents-test.XXXXXX")" || exit 1
trap 'rm -rf "$TMP"' EXIT

# Per case: a fresh fake HOME and stub commands; $OUT / $CODE from the last run.
setup() {
  H="$TMP/$1/home dir"
  A="$H/.claude/agents"
  BIN="$TMP/$1/bin"
  mkdir -p "$H/.claude" "$BIN"
  for cmd in npx claude dotnet; do printf '#!/bin/sh\nexit 0\n' > "$BIN/$cmd"; done
  chmod +x "$BIN/npx" "$BIN/claude" "$BIN/dotnet"
}
run() { OUT="$(HOME="$H" PATH="$BIN:$PATH" bash "$REPO/scripts/install.sh" 2>&1)"; CODE=$?; }
backups() { find "$A" -name "$1.bak-*" 2>/dev/null | wc -l | tr -d ' '; }
fail() { echo "      $1"; echo "      output: $OUT" | head -n 20; return 1; }

case_vendored_files_present() {
  OUT=""
  for f in scout.md researcher.md; do
    [ -f "$SRC/$f" ] || fail "missing templates/agents/$f" || return 1
    grep -q "^name: ${f%.md}$" "$SRC/$f" || fail "$f has no 'name: ${f%.md}' line" || return 1
  done
  grep -q "1523f3f" "$SRC/README.md" 2>/dev/null || fail "templates/agents/README.md does not name the upstream commit" || return 1
  grep -qi "MIT" "$SRC/README.md" || fail "templates/agents/README.md has no licence note"
}

case_fresh_home_gets_both() {
  setup fresh_home_gets_both
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  cmp -s "$A/scout.md" "$SRC/scout.md" || fail "scout.md not copied" || return 1
  cmp -s "$A/researcher.md" "$SRC/researcher.md" || fail "researcher.md not copied" || return 1
  [ "$(backups scout.md)" -eq 0 ] || fail "backup made of nothing"
}

case_different_file_backed_up() {
  setup different_file_backed_up
  mkdir -p "$A"
  printf -- '---\nname: scout\n---\nMy own scout, $HOME & `ticks`\n' > "$A/scout.md"
  cp "$A/scout.md" "$TMP/orig"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  cmp -s "$A/scout.md" "$SRC/scout.md" || fail "scout.md not replaced" || return 1
  [ "$(backups scout.md)" -eq 1 ] || fail "wanted 1 backup, found $(backups scout.md)" || return 1
  cmp -s "$(find "$A" -name 'scout.md.bak-*')" "$TMP/orig" || fail "backup is not the original" || return 1
  printf '%s' "$OUT" | grep -q "scout.md.bak-" || fail "output does not name the backup"
}

case_identical_file_left_alone() {
  setup identical_file_left_alone
  mkdir -p "$A"
  cp "$SRC/scout.md" "$A/scout.md" || fail "no vendored scout.md to copy" || return 1
  touch -t 200001010000 "$A/scout.md"
  touch -t 200101010000 "$TMP/ref"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  # researcher.md proves the step ran; otherwise "left alone" passes by doing nothing.
  cmp -s "$A/researcher.md" "$SRC/researcher.md" || fail "agent step did not run" || return 1
  [ -z "$(find "$A" -name scout.md -newer "$TMP/ref")" ] || fail "identical scout.md was rewritten" || return 1
  [ "$(backups scout.md)" -eq 0 ] || fail "backup made of an identical file"
}

case_rerun_is_up_to_date() {
  setup rerun_is_up_to_date
  mkdir -p "$A"
  printf 'old\n' > "$A/researcher.md"
  run
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  [ "$(backups researcher.md)" -eq 1 ] || fail "second run made another backup" || return 1
  printf '%s' "$OUT" | grep -qi "researcher.md.*up to date" || fail "second run did not say researcher.md is up to date"
}

# A team repo after local-setup.sh: the big-ticket files in the default ticket folder
# (docs/specs/<ticket>/) must be ignored, so they never show in the team's git status.
case_ticket_files_ignored_in_team_repo() {
  local repo="$TMP/team repo"
  mkdir -p "$repo"
  git -C "$repo" init -q
  OUT="$(bash "$REPO/scripts/local-setup.sh" "$repo" 2>&1)" || fail "local-setup.sh failed" || return 1
  for p in docs/specs/W-12/exploration.md docs/specs/W-12/build-packet-S1.md \
           docs/specs/W-12/build-packet-S10.md docs/specs/W-12/S2-gate-failure.patch; do
    git -C "$repo" check-ignore -q "$p" || fail "not ignored: $p" || return 1
  done
}

ALL=(vendored_files_present fresh_home_gets_both different_file_backed_up
     identical_file_left_alone rerun_is_up_to_date ticket_files_ignored_in_team_repo)
if [ "$#" -gt 0 ]; then names=("$@"); else names=("${ALL[@]}"); fi

passed=0; failed=0
for name in "${names[@]}"; do
  if "case_$name"; then
    printf 'PASS  %s\n' "$name"; passed=$((passed + 1))
  else
    printf 'FAIL  %s\n' "$name"; failed=$((failed + 1))
  fi
done

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
