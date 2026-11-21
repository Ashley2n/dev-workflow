<!-- dev-workflow:start -->
# Ashley's workflow preferences

## Who I am
Junior developer (C# / ASP.NET Core / Blazor at work). I use Claude to go faster **and** to get better. Explain decisions so I could defend them to my lead and explain them to a client.

## Decisions
- Every real decision needs a source: official docs (link), this codebase (file and symbol name; add `:line` only in a dated record such as `rationale.md`, stamped `as of <commit>, <date>`), a person + date, or the ticket. Mark anything else **⚠ unsourced**. Never make up links, paths or line numbers.
- Decision table columns: Decision | Options considered | Why this one | Risk / tradeoff | Source.
- Use the repo's existing place for decisions and specs. Only if none exists: `docs/specs/` plus a `docs/decisions.md` index. Note the location in `AGENTS.md`.

## Stack rule (new projects)
If one stack clearly wins on compatibility, documentation, reliability or performance, pick it. If the options are roughly equal, pick C# / ASP.NET Core / Blazor. Say which case applied.

## Checking depth
Work: Beta minimum (always tests); GA for login, permissions, personal or health data, payments, migrations or business-critical code. Personal: Beta by default; Prototype only for throwaway work.

## Questions
When clarifying, ask one question at a time with your recommended answer (grill-me style).

## Done means checked in the real app
- When `/develop` finishes a task with user-facing behavior, run `check verify` on each of that task's acceptance criteria before ticking it. Evidence is a screenshot, or BLOCKED with the reason. No evidence, no tick.
- Web: Playwright screenshots at 1280 and 390 px. MAUI: iOS simulator and Android emulator screenshots for every UI acceptance criterion. A platform that can't run marks its criteria BLOCKED, never passed.

## Pitfalls (work repos)
- Read `.workflow/pitfalls.md` before every `/check review` and `check verify`. Test each pitfall that applies to the changed screens. The file is local; never commit it.
- When a bug turns up after a task was marked done, the fixing session adds an entry (symptom, platform, trigger, how to check) and tells me in one line. Keep the file to about 30 entries; merge or delete stale ones at the monthly metrics run.

## Git and shell
- Fetch before compare: `git fetch origin`, then compare against `origin/<base>` for every review, merge check and PR text.
- Quote paths. Run globs and loops with `bash -c`. Never chain a build and a commit in one command.
- Plan, then confirm before sending email, pushing or posting comments. Exception: when I ask for a commit, pushing that branch is approved. Never force-push; never push `main`.

## Ticket log (work)
When a work ticket's PR is ready, print one row for my metrics, ready to paste:
`| W-NN | YYYY-MM-DD | hours (rough) | review rounds | escaped defects | found by | notes |`
Codes and counts only: no client names, ticket titles or code. Notes are one or two words naming the kind of bug, like `iOS layout` or `stale base`.

## Learning log
Path: `~/Documents/03-Resources/MyVault/02-Areas/Learning/review-log.md`
Never write client code, client data, patient data, client names or client repo paths there. Only the lesson.
<!-- dev-workflow:end -->
