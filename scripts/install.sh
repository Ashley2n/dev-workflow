#!/usr/bin/env bash
# Installs Ashley's whole workflow: published skills/plugins first, then this plugin.
# Safe to re-run. Requires: node (npx), Claude Code CLI (claude), .NET SDK for csharp-ls.
set -euo pipefail

say() { printf '\n==> %s\n' "$1"; }

say "JS Mastery workflow skills (scope, audit, architect, develop, check, test, document, sync, debug)"
npx -y skills@latest add jsmastery-pro/skills -g -a claude-code -y

say "Superpowers: only receiving-code-review and verification-before-completion"
npx -y skills@latest add obra/superpowers -g -a claude-code \
  -s receiving-code-review -s verification-before-completion -y

say "Official plugins (user scope)"
for p in mattpocock-skills explanatory-output-style csharp-lsp security-guidance; do
  claude plugin install "$p@claude-plugins-official" --scope user || echo "   (skipped $p, check: claude plugin install $p@claude-plugins-official)"
done
echo "   Coach mode (learning-output-style) is NOT installed globally."
echo "   /new-project turns it on per personal repo with --scope local."

say "C# language server for csharp-lsp"
if command -v dotnet >/dev/null 2>&1; then
  dotnet tool install --global csharp-ls 2>/dev/null || dotnet tool update --global csharp-ls
else
  echo "   dotnet not found; install the .NET SDK, then: dotnet tool install --global csharp-ls"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

say "This plugin (work-ticket, new-project, review-me, teach-back)"
# Uses the GitHub repo once it's pushed; falls back to this local clone.
claude plugin marketplace add Ashley2n/dev-workflow 2>/dev/null \
  || claude plugin marketplace add "$REPO_DIR" \
  || echo "   (marketplace already added)"
claude plugin install dev-workflow@ashley-dev-workflow --scope user \
  || echo "   (install failed; run: claude plugin install dev-workflow@ashley-dev-workflow)"

say "Personal preferences -> ~/.claude/CLAUDE.md"
TEMPLATE="$SCRIPT_DIR/../templates/user-claude.md"
mkdir -p "$HOME/.claude"
touch "$HOME/.claude/CLAUDE.md"
if grep -q "dev-workflow:start" "$HOME/.claude/CLAUDE.md"; then
  echo "   Already present; edit ~/.claude/CLAUDE.md by hand to change it."
else
  printf '\n' >> "$HOME/.claude/CLAUDE.md"
  cat "$TEMPLATE" >> "$HOME/.claude/CLAUDE.md"
  echo "   Added. On a work machine, fix the Learning log path if the vault lives elsewhere."
fi

say "Done. Restart Claude Code, then try /work-ticket or /new-project."
