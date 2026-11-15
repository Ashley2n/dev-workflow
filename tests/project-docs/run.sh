#!/usr/bin/env bash
# Fixture-repo tests for skills/project-docs/scripts/status.sh (D30, D35).
# Each folder in fixtures/ holds:
#   repo/          the files of a pretend repo (copied to a temp folder and `git init`-ed)
#   expected.txt   the exact output status.sh must print
#   exit           optional: expected exit code (default 0)
#   track.txt      optional: paths to `git add` (to pretend the team tracks them)
# Usage: bash tests/project-docs/run.sh [fixture-name ...]   (default: all)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS="$HERE/../../skills/project-docs/scripts/status.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ "$#" -gt 0 ]; then names=("$@"); else names=(); for d in "$HERE"/fixtures/*/; do names+=("$(basename "$d")"); done; fi

pass=0; fail=0
for name in "${names[@]}"; do
  dir="$HERE/fixtures/$name"
  work="$TMP/$name"
  mkdir -p "$work"
  cp -R "$dir/repo/." "$work/"
  git -C "$work" init -q
  if [ -f "$dir/track.txt" ]; then
    while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && git -C "$work" add -f -- "$p"; done < "$dir/track.txt"
  fi

  want_exit=0; [ -f "$dir/exit" ] && want_exit="$(tr -d '\r\n' < "$dir/exit")"
  got="$(bash "$STATUS" "$work" 2>&1 | tr -d '\r')"; got_exit="${PIPESTATUS[0]}"
  want="$(tr -d '\r' < "$dir/expected.txt")"

  if [ "$got" == "$want" ] && [ "$got_exit" == "$want_exit" ]; then
    printf 'PASS  %s\n' "$name"; pass=$((pass + 1))
  else
    printf 'FAIL  %s (exit %s, wanted %s)\n' "$name" "$got_exit" "$want_exit"
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/      /'
    fail=$((fail + 1))
  fi
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
