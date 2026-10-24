#!/usr/bin/env bash
# Sets up a TEAM repo for this workflow without changing anything the team shares (D18).
#   - Lists AGENTS.md, CLAUDE.local.md and docs/{specs,scope,reviews} in .git/info/exclude,
#     so git never sees them and nothing lands in a commit by accident.
#   - Makes CLAUDE.local.md import @AGENTS.md. When a repo has a CLAUDE.md, Claude Code
#     doesn't read AGENTS.md unless something imports it (https://code.claude.com/docs/en/memory).
#   - Never touches the team's CLAUDE.md, .gitignore or any tracked file.
# Usage: bash scripts/local-setup.sh [path/to/team-repo]   (default: current folder)
# Safe to re-run.
set -euo pipefail

say() { printf '\n==> %s\n' "$1"; }

TARGET="${1:-.}"
if ! ROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "Not inside a git repo: $TARGET" >&2
  exit 1
fi
cd "$ROOT"
# --git-path also works in worktrees, where .git is a file, not a folder.
EXCLUDE="$(git rev-parse --git-path info/exclude)"
mkdir -p "$(dirname "$EXCLUDE")"
touch "$EXCLUDE"

say "Repo: $ROOT"

say "Local-only patterns -> $EXCLUDE"
if grep -q "dev-workflow:start" "$EXCLUDE"; then
  echo "   Already present; edit $EXCLUDE by hand to change it."
else
  PATTERNS=(AGENTS.md CLAUDE.local.md)
  # Folders end in /; docs/decisions.md is the index /work-ticket creates when the team has none.
  for path in docs/specs/ docs/scope/ docs/reviews/ docs/decisions.md; do
    # Excluding a path the team already commits to would hide new team files too.
    if [ -n "$(git ls-files -- "${path%/}" | head -n 1)" ]; then
      echo "   Skipped $path: the team already tracks it. Use it the team's way."
    else
      PATTERNS+=("/$path")
    fi
  done
  {
    printf '\n# dev-workflow:start (local only, see scripts/local-setup.sh)\n'
    printf '%s\n' "${PATTERNS[@]}"
    printf '# dev-workflow:end\n'
  } >> "$EXCLUDE"
  printf '   Added: %s\n' "${PATTERNS[@]}"
fi

say "CLAUDE.local.md imports @AGENTS.md"
touch CLAUDE.local.md
if grep -qx "@AGENTS.md" CLAUDE.local.md; then
  echo "   Already imports it."
else
  printf '%s\n' "@AGENTS.md" | cat - CLAUDE.local.md > CLAUDE.local.md.tmp
  mv CLAUDE.local.md.tmp CLAUDE.local.md
  echo "   Added the import at the top."
fi
[ -f AGENTS.md ] || echo "   No AGENTS.md yet; /audit creates it."

say "Check: tracked files git can't hide"
TRACKED="$(git ls-files -- AGENTS.md CLAUDE.local.md)"
if [ -n "$TRACKED" ]; then
  echo "   WARNING: already committed, so exclude has no effect on them:"
  printf '     %s\n' $TRACKED
  echo "   Ask your lead before changing them."
else
  echo "   OK: none of the local files are tracked."
fi

say "Done. Next: run /audit once in this repo."
echo "   If /audit offers to move the team's CLAUDE.md into AGENTS.md, answer no (D18)."
echo "   Afterwards, run 'git status': it should show nothing new from the workflow."
