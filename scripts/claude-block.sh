#!/usr/bin/env bash
# Writes the dev-workflow block from a template into a CLAUDE.md (D47). install.sh calls it.
#   - No file: creates it with the block.
#   - No block: appends the block. Existing text is left byte for byte.
#   - Block present and different: backs the file up to CLAUDE.md.bak-<timestamp>,
#     prints a diff, and replaces only the lines from the start marker to the end marker.
#   - Block identical: says so and changes nothing.
#   - Markers broken (start without end, end first, more than one): changes nothing, exits 1.
# Plain bash, awk, head and tail, so it runs on macOS and Git Bash on Windows.
# Usage: bash scripts/claude-block.sh <template> <target CLAUDE.md>
set -euo pipefail

START='<!-- dev-workflow:start -->'
END='<!-- dev-workflow:end -->'

if [ "$#" -ne 2 ]; then
  echo "Usage: bash scripts/claude-block.sh <template> <target CLAUDE.md>" >&2
  exit 2
fi
TEMPLATE="$1"
TARGET="$2"

# Line numbers of lines that contain the marker, one per line.
lines_with() { awk -v m="$1" 'index($0, m) { print NR }' "$2"; }
count() { if [ -z "$1" ]; then echo 0; else printf '%s\n' "$1" | wc -l | tr -d ' '; fi; }

# Prints why the markers in $1 are broken, or nothing when they are fine (none, or one pair in order).
marker_problem() {
  local s e ns ne
  s="$(lines_with "$START" "$1")"; e="$(lines_with "$END" "$1")"
  ns="$(count "$s")"; ne="$(count "$e")"
  if [ "$ns" -eq 0 ] && [ "$ne" -eq 0 ]; then return 0; fi
  if [ "$ns" -gt 1 ] || [ "$ne" -gt 1 ]; then echo "more than one start or end marker"; return 0; fi
  if [ "$ns" -eq 0 ]; then echo "end marker without a start marker"; return 0; fi
  if [ "$ne" -eq 0 ]; then echo "start marker without an end marker"; return 0; fi
  if [ "$e" -lt "$s" ]; then echo "end marker comes before the start marker"; fi
}

[ -f "$TEMPLATE" ] || { echo "   Template not found: $TEMPLATE" >&2; exit 1; }
problem="$(marker_problem "$TEMPLATE")"
if [ -n "$problem" ] || [ -z "$(lines_with "$START" "$TEMPLATE")" ]; then
  echo "   Template markers are broken (${problem:-no block}): $TEMPLATE" >&2
  exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/claude-block.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
# The block in the template, start marker through end marker.
awk -v s="$START" -v e="$END" 'index($0, s) { on = 1 } on { print } index($0, e) { on = 0 }' \
  "$TEMPLATE" > "$WORK/new-block"

if [ ! -e "$TARGET" ]; then
  mkdir -p "$(dirname "$TARGET")"
  cat "$WORK/new-block" > "$TARGET"
  echo "   Created $TARGET with the block."
  exit 0
fi

problem="$(marker_problem "$TARGET")"
if [ -n "$problem" ]; then
  echo "   Changed nothing: $TARGET has broken dev-workflow markers ($problem)." >&2
  echo "   Fix them by hand (one start marker, then one end marker), then re-run." >&2
  exit 1
fi

s="$(lines_with "$START" "$TARGET")"
if [ -z "$s" ]; then
  # No block yet. Appending leaves every existing byte where it was.
  { printf '\n'; cat "$WORK/new-block"; } >> "$TARGET"
  echo "   Added the block to the end of $TARGET."
  exit 0
fi
e="$(lines_with "$END" "$TARGET")"

sed -n "${s},${e}p" "$TARGET" > "$WORK/old-block"
if cmp -s "$WORK/old-block" "$WORK/new-block"; then
  echo "   Up to date; nothing changed."
  exit 0
fi

# head and tail copy the text outside the markers byte for byte, including a missing final newline.
{
  if [ "$s" -gt 1 ]; then head -n "$((s - 1))" "$TARGET"; fi
  cat "$WORK/new-block"
  tail -n "+$((e + 1))" "$TARGET"
} > "$WORK/new-file"

BACKUP="$TARGET.bak-$(date +%Y%m%d-%H%M%S)"
if [ -e "$BACKUP" ]; then BACKUP="$BACKUP-$$"; fi
cp -p "$TARGET" "$BACKUP"

echo "   Block changed:"
(cd "$WORK" && diff -u old-block new-block) | sed 's/^/   /' || true
# Write through the existing file, so a symlink or its permissions stay as they are.
cat "$WORK/new-file" > "$TARGET"
echo "   Updated the block. Backup: $BACKUP"
