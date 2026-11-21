#!/usr/bin/env bash
# Tests for scripts/claude-block.sh, the step of install.sh that writes the
# dev-workflow block into ~/.claude/CLAUDE.md (D47).
# Every case runs against a fake HOME in a temp folder whose path has a space.
# Nothing is written to the repo or the real ~/.claude.
# Usage: bash tests/claude-block/run.sh [case-name ...]   (default: all)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
BLOCK="$REPO/scripts/claude-block.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/claude-block-test.XXXXXX")" || exit 1
trap 'rm -rf "$TMP"' EXIT

START='<!-- dev-workflow:start -->'
END='<!-- dev-workflow:end -->'

# Per case: a fresh fake HOME, a template, and $OUT / $CODE from the last run.
setup() {
  H="$TMP/$1/home dir"
  mkdir -p "$H/.claude"
  F="$H/.claude/CLAUDE.md"
  T="$TMP/$1/template with space.md"
  printf '%s\n# Prefs\n\n- new rule $HOME & \\ stays literal\n%s\n' "$START" "$END" > "$T"
}
run() { OUT="$(bash "$BLOCK" "$T" "$F" 2>&1)"; CODE=$?; }
backups() { find "$H/.claude" -name 'CLAUDE.md.bak-*' | wc -l | tr -d ' '; }
fail() { echo "      $1"; echo "      output: $OUT" | head -n 20; return 1; }

# Text outside the markers. AFTER has no trailing newline on purpose.
BEFORE=$'# My own notes\n\nKeep $HOME, `ticks`, \\back\\slashes & "quotes" ✓\n\n'
AFTER=$'\n## Coding standards\nMine, not the template\'s.\r\nCRLF line above.\nno newline at end'
OLDBLOCK=$'<!-- dev-workflow:start -->\n# Prefs\n\n- old rule\n<!-- dev-workflow:end -->\n'

case_missing_file() {
  setup missing_file
  rm -rf "$H/.claude"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  cmp -s "$F" "$T" || fail "new file is not the template" || return 1
  [ "$(backups)" -eq 0 ] || fail "made a backup of nothing"
}

case_no_block_appends() {
  setup no_block_appends
  printf '%s' "${BEFORE}last line, no newline" > "$F"
  cp "$F" "$TMP/orig"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  { cat "$TMP/orig"; printf '\n'; cat "$T"; } > "$TMP/want"
  cmp -s "$F" "$TMP/want" || fail "existing text changed or block not appended" || return 1
  [ "$(backups)" -eq 0 ] || fail "backup made when only appending"
}

case_identical_block() {
  setup identical_block
  { printf '%s' "$BEFORE"; cat "$T"; printf '%s' "$AFTER"; } > "$F"
  cp "$F" "$TMP/orig"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  printf '%s' "$OUT" | grep -qi "up to date" || fail "did not say up to date" || return 1
  cmp -s "$F" "$TMP/orig" || fail "file changed" || return 1
  [ "$(backups)" -eq 0 ] || fail "backup made when nothing changed"
}

case_changed_block_replaced() {
  setup changed_block_replaced
  printf '%s%s%s' "$BEFORE" "$OLDBLOCK" "$AFTER" > "$F"
  cp "$F" "$TMP/orig"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  { printf '%s' "$BEFORE"; cat "$T"; printf '%s' "$AFTER"; } > "$TMP/want"
  cmp -s "$F" "$TMP/want" || fail "text outside the markers changed, or block not replaced" || return 1
  [ "$(backups)" -eq 1 ] || fail "wanted 1 backup, found $(backups)" || return 1
  cmp -s "$(find "$H/.claude" -name 'CLAUDE.md.bak-*')" "$TMP/orig" || fail "backup is not the original" || return 1
  printf '%s' "$OUT" | grep -qE '^ *-- old rule' || fail "diff missing the old line" || return 1
  printf '%s' "$OUT" | grep -qE '^ *\+- new rule' || fail "diff missing the new line"
}

case_rerun_is_up_to_date() {
  setup rerun_is_up_to_date
  printf '%s%s%s' "$BEFORE" "$OLDBLOCK" "$AFTER" > "$F"
  run
  cp "$F" "$TMP/after-first"
  run
  [ "$CODE" -eq 0 ] || fail "exit $CODE" || return 1
  printf '%s' "$OUT" | grep -qi "up to date" || fail "second run did not say up to date" || return 1
  cmp -s "$F" "$TMP/after-first" || fail "second run changed the file" || return 1
  [ "$(backups)" -eq 1 ] || fail "second run made another backup"
}

# Malformed markers: no change, no backup, an error, non-zero exit.
malformed() {
  setup "$1"
  printf '%s' "$2" > "$F"
  cp "$F" "$TMP/orig"
  run
  [ "$CODE" -ne 0 ] || fail "exit 0 on malformed markers" || return 1
  cmp -s "$F" "$TMP/orig" || fail "file changed" || return 1
  [ "$(backups)" -eq 0 ] || fail "backup made" || return 1
  printf '%s' "$OUT" | grep -qi "marker" || fail "error does not mention the markers"
}
case_start_without_end() { malformed start_without_end "${BEFORE}${START}"$'\n- half a block\n'; }
case_end_without_start() { malformed end_without_start "${BEFORE}${END}"$'\n'; }
case_end_before_start()  { malformed end_before_start "${END}"$'\nx\n'"${START}"$'\n'; }
case_two_blocks()        { malformed two_blocks "${OLDBLOCK}${BEFORE}${OLDBLOCK}"; }

case_install_uses_helper() {
  setup install_uses_helper
  OUT="$(grep -n 'claude-block.sh' "$REPO/scripts/install.sh")"
  [ -n "$OUT" ] || fail "install.sh does not call scripts/claude-block.sh"
}

ALL=(missing_file no_block_appends identical_block changed_block_replaced rerun_is_up_to_date
     start_without_end end_without_start end_before_start two_blocks install_uses_helper)
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
