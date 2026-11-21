## What changed and why


## Checklist
- [ ] Version bumped in `.claude-plugin/plugin.json` if a skill, agent or script changed (patch = fix, minor = feature). A pinned version keeps every machine on the cached copy until it changes: [Versions and updates](https://code.claude.com/docs/en/plugins/loading.md#versions-and-updates)
- [ ] `bash tests/project-docs/run.sh` passes (when `skills/project-docs/` changed)
- [ ] `bash tests/claude-block/run.sh` passes (when `scripts/install.sh` or `scripts/claude-block.sh` changed)
- [ ] README table updated if a skill was added or renamed
