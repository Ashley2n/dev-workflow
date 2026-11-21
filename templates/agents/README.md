# Vendored agents

`scout.md` and `researcher.md` are copied unchanged from [jsmastery-pro/skills](https://github.com/jsmastery-pro/skills), `.claude/agents/`, at commit `1523f3f` (2026-07-09). `install.sh` copies them into `~/.claude/agents/` under these plain names, because `develop` asks for the `scout` subagent type by name and plugin agents are namespaced (D56). A different file already there is backed up to `<name>.bak-<timestamp>` first.

**Licence:** MIT, Copyright (c) 2026 JavaScript Mastery. Upstream added its `LICENSE` in `82615dc`, later the same day as `1523f3f`; both files are unchanged between `1523f3f` and upstream `43b69e4` (2026-08-07), which carries that licence.

**Updating:** don't edit these files here. To take a newer upstream version, copy it in a deliberate PR and update the commit above.
