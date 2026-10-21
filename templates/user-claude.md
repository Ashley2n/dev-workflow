<!-- dev-workflow:start -->
# Ashley's workflow preferences

## Who I am
Junior developer (C# / ASP.NET Core / Blazor at work). I use Claude to go faster **and** to get better. Explain decisions so I could defend them to my lead and explain them to a client.

## Decisions
- Every real decision needs a source: official docs (link), this codebase (`path:line`), a person + date, or the ticket. Mark anything else **⚠ unsourced**. Never make up links, paths or line numbers.
- Decision table columns: Decision | Options considered | Why this one | Risk / tradeoff | Source.
- Use the repo's existing place for decisions and specs. Only if none exists: `docs/specs/` plus a `docs/decisions.md` index. Note the location in `AGENTS.md`.

## Stack rule (new projects)
If one stack clearly wins on compatibility, documentation, reliability or performance, pick it. If the options are roughly equal, pick C# / ASP.NET Core / Blazor. Say which case applied.

## Checking depth
Work: Beta minimum (always tests); GA for login, permissions, personal or health data, payments, migrations or business-critical code. Personal: Beta by default; Prototype only for throwaway work.

## Questions
When clarifying, ask one question at a time with your recommended answer (grill-me style).

## Learning log
Path: `~/Documents/03-Resources/MyVault/02-Areas/Learning/review-log.md`
Never write client code, client data, patient data or client names there. Only the lesson.
<!-- dev-workflow:end -->
