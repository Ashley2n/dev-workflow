---
name: project-docs
description: Write and track a project's PRD (product requirements), SDD (system design), test plan and runbook. Run /project-docs alone for a status table plus the one next step, or /project-docs prd | sdd | test-plan | runbook to write one. Not for README or AGENTS.md (that is /audit), per-feature specs (/architect), scope (/scope) or release notes (/document).
argument-hint: "[prd | sdd | test-plan | runbook]"
---

# Project docs

Writes four documents on top of the existing scope, specs and reviews (D25). Status lives in the files, so any session can pick up where the last one stopped (D30).

## Where files go
- The script below picks the artifact base: `docs/` in a personal repo, `.workflow/` in a work repo (D26). Use the base it prints.
- Exit code 3 means the team tracks `.workflow/`. Relay the STOP line to Ashley and wait for her to name another base.
- Before the first write into `.workflow/`, run `git check-ignore -q .workflow/<file>`. Not ignored: write nothing, and tell her to add `/.workflow/` to `.git/info/exclude`.
- One file per document per repo (D29). A new feature or ticket adds a section; existing text stays. A large work ticket is a section in `.workflow/prd.md` (D34).

## Steps

1. **Read the status.** Run `bash scripts/status.sh` (the `scripts/` folder next to this file; pass the repo path if you are not inside it). Show the table and the `Next:` line. Done when both are on screen.
2. **No argument:** offer to start the `Next:` step and stop. Done when Ashley answers.
3. **With an argument:** find that document's `Ready?` cell. A cell starting `no:` means say why, name the `Next:` step instead, and stop.
4. **Create it if missing:** copy `templates/<name>.md` into the base, keeping `Status: skeleton`.
5. **Fill it:**
   - `prd` and `sdd`: ask one question at a time, each with your recommended answer, in the main session. Ask only what the scope, specs and code leave open. As a subagent, return `NEEDS ASHLEY` with the questions.
   - `test-plan` and `runbook`: derive from the PRD's acceptance criteria, the code, the config and the specs. Ask only when a fact is missing.
   - Give every claim a source: the scope, a spec number, `path:line`, the ticket, or a link. Mark the rest **⚠ unsourced**.
   - Replace each guidance block with the answer. Done when no guidance block is left.
6. **Set the status lines.** `Status: draft` after the first full fill; `current` only after Ashley approves it. Write `Checked against: <scope files>, specs <first>–<last> (<today>)`, or `specs none`. List every scope file name, because the script marks a document stale when one is missing from the line.
7. **Show the new status.** Re-run the script and print the table. Done when the document's row reads `draft` or `current`.

## Hand off, don't write
- Per-feature design: `/architect`. Scope: `/scope`. PR text and release notes: `/document`. README and AGENTS.md: `/audit`.
- `decisions.md`: the status shows its row count, and `/new-project` step 2 and `/architect` own the file (D31).
- Leave JS Mastery's skills as they are (D28).

## Ready when (D30)
| Document | Ready when |
|---|---|
| PRD | a scope exists |
| SDD | the PRD is `current` and at least one `/architect` spec exists |
| Test plan | the PRD has a line starting `Acceptance criteria:` and is past `skeleton` |
| Runbook | a project manifest or start file exists (`*.csproj`, `package.json`, `Dockerfile`, `Makefile`, ...) |
