---
name: work-ticket
description: Run a work ticket end to end in an existing codebase. Pasted ticket in, then clarify, decide with sources, build test-first, check, review-first, teach-back, and a plain-English client summary. Use when the user runs /work-ticket or pastes a ticket and asks to work it.
argument-hint: "<pasted ticket text>"
disable-model-invocation: true
---

# Work ticket

You run one ticket through Ashley's workflow. Ashley is a junior developer. At work, **you write most of the code**, but **she steers**: she must understand every decision well enough to defend it to her lead and explain it to a client in plain English. Speed matters (client hours are billed), and so does correctness (some clients handle health data).

This skill is a thin conductor. It calls published skills for the real work and adds only Ashley's checkpoints. Don't redo what those skills already do.

Invoke each skill with the Skill tool by the exact name below. Plugin skills need their namespace, and some short names collide (Claude Code has its own built-in `code-review`).

| Step | Skill name to invoke | Source |
|---|---|---|
| Context | `audit` | jsmastery-pro/skills |
| Clarify | `mattpocock-skills:grilling` | mattpocock/skills (`grill-me` is user-only, so it can't be called from here) |
| Decide | `architect` | jsmastery-pro/skills |
| Build | `develop`, `verification-before-completion` | jsmastery-pro/skills, obra/superpowers |
| Check | `check` (args `verify` / `review`), `document` | jsmastery-pro/skills (tests are written by `dev-workflow:dev` test-first, not `test`) |
| Review-first | `dev-workflow:review-me` | this plugin (wraps `mattpocock-skills:code-review`) |
| Teach-back | `dev-workflow:teach-back` | this plugin |
| Bugs | `debug` | jsmastery-pro/skills |

If a skill isn't installed or the call is refused, stop and say which one, and how to install it (see this plugin's README). Don't quietly do the step another way.

**Agents (D21–D22).** You are the conductor: grilling, `architect` and every ⏸ checkpoint stay with you in the main session, because subagents can't ask Ashley questions. The writing, building and checking go to this plugin's agents. First invoke **`dev-workflow:team-handoffs`** and follow its flow, formats and loop cap.

| Step | Agent | Gets | Returns |
|---|---|---|---|
| 3 | `dev-workflow:po` | `ticket.md` + Ashley's grilling answers | Story Card → `story-card.md` |
| 6 | `dev-workflow:qa` (pass 1) | Story Card only | Test Plan, the draft test names for the checkpoint |
| 7 | `dev-workflow:dev` | Story Card + approved decisions + approved test names | Build Packet → `build-packet.md` |
| 8 | `dev-workflow:qa` (pass 2) | Story Card + changed files + loop number | QA Report → `qa-report.md` |

**Small, clear tickets** (step 3's small-ticket path): write the one-AC Story Card and the test names yourself in the team-handoffs formats, and delegate only `dev-workflow:dev` and `dev-workflow:qa` pass 2. Each agent re-reads the code from scratch, so skipping PO and QA pass 1 halves the cost where they add little. The step 6 checkpoint still happens.

Track the steps with a todo list. Stop at every checkpoint marked **⏸** and wait for Ashley.

## 0. Resume or start

Every ticket gets a folder, `<specs location>/<ticket-id-or-short-slug>/` (specs location from step 2; default `docs/specs/`). Agent handoffs (`story-card.md`, `build-packet.md`, `qa-report.md`) are saved there too. Its `ticket.md` holds the ticket word for word, its origin, and a `## Progress` checklist of steps 1–11. Tick a step and add a one-line outcome (depth chosen, decisions approved, test names agreed, open client questions) **each time a step finishes**. This file is how the work survives a long session, a summarized context, or tomorrow morning.

If a folder for this ticket already exists, read its `ticket.md`, say which step you're resuming at, and continue from there. Don't redo finished steps.

## 1. Take in the ticket

- Write the pasted ticket text word for word to `ticket.md`. Ask where it came from (system, person, date) if the text doesn't say. Ticket text plus origin is a **source** for every requirement it states.
- If the ticket is really a bug ("X is broken", "error when..."), say so and offer to run `debug` instead of the feature path.

## 2. Make sure the project has context

- Look for `AGENTS.md` / `CLAUDE.md` at the repo root.
  - **Missing:** recommend running `audit` once for this repo before going on. This happens once per codebase, not once per ticket.
  - **Present:** read it. Don't re-audit.
- **Where decisions live:** if `AGENTS.md` already has a `## Decisions` line, use it and skip the search. Otherwise find out whether the repo already records decisions or specs (for example `docs/adr/`, `docs/decisions/`, `docs/specs/`, a wiki link in the README). **Use what exists. Never invent a parallel system.** If nothing exists, use `docs/specs/` (what `architect` writes) plus a one-line index `docs/decisions.md`. Write the chosen location into `AGENTS.md` under `## Decisions`, so the next ticket skips the search.
- **Team repo check:** if `CLAUDE.local.md` imports `@AGENTS.md`, this is a team repo set up with `scripts/local-setup.sh` (decision D18). Before writing any workflow file (`ticket.md`, specs, `docs/decisions.md`), run `git check-ignore -q <path>`. If it isn't ignored, don't write it. Tell Ashley that file would show up in the team's `git status`, and ask whether it belongs in the team's existing decision file instead.

## 3. Clarify (⏸)

- Read the code the ticket touches **before** asking anything. Never ask what the code can answer.
- **Small, clear tickets** (a typo, a copy change, a config value, or a change where the ticket and code leave nothing to decide): don't grill. Write your reading of the ticket in two or three lines and ask Ashley to confirm it. That confirmation is this checkpoint.
- Otherwise run **`mattpocock-skills:grilling`** on the ticket: one question at a time, each with your recommended answer. Ashley prefers this style because it makes her think deeper.
- Ask only what Ashley or the client alone can know (business rules, who's allowed to do what, edge cases the ticket skips). Recommend answers for things expertise settles.
- Anything only the client can answer goes on an **Open questions for client** list. Ashley chooses: wait, or build on a written assumption.
- Once Ashley confirms, delegate the Story Card to **`dev-workflow:po`** with the ticket and her answers. Show her the card. If it comes back NOT READY, grill the UNRESOLVED questions and send them back to PO. The checkpoint passes when Ashley accepts a READY card; its ACs are the acceptance criteria for every later step.

## 4. Pick the checking depth

The names come from `scope`/`architect`. Choose per ticket and say why in one line:

- **GA:** touches login, permissions, personal or health data, payments, database migrations, or anything the client's business runs on.
- **Beta:** everything else. **Beta is the floor at work: every ticket gets tests.** Never pick Prototype or Alpha for work.

Ashley can override. Record the override and her reason.

## 5. Decide, with sources (⏸)

Run **`architect`** for any real decision (data model, approach, library, where the logic lives). When it asks for the references level, recommend **`sources+links`**.

Then show Ashley the **decision table**. Add a row to the project's decision index (step 2) for each decision:

| Decision | Options considered | Why this one | Risk / tradeoff | Source |
|---|---|---|---|---|

**Source rules (non-negotiable):**
- A real source is one of: official docs (link), this codebase (`path:line` of the pattern followed), a person + when ("Mike, standup 2026-10-21"), or the ticket/requirement.
- "Claude knows this" is **not** a source. Mark such rows **⚠ unsourced**. Ashley must either back them up or explicitly accept the risk before step 6.
- Never make up a link, a file path or a line number. If you can't confirm it, say so.

Explain each row so Ashley could say it out loud to her lead. Wait for her approval or pushback on each row.

## 6. Agree the test cases (⏸)

Before any code, list the behaviors as plain test names ("returns 404 when the patient isn't found", "rejects an end date before the start date"), each tied to an acceptance criterion. Draft them with **`dev-workflow:qa`** pass 1 (Story Card only, so the cases come from the card and not from a plan for the code). Ashley approves, adds or removes cases. This is the most important learning step at work. Don't skip it on small tickets.

## 7. Build

Delegate the build to **`dev-workflow:dev`** with the Story Card, the approved decisions and the approved test names. It runs `develop` test-first and follows `verification-before-completion`: no "done" or "passing" without the command's real output in the Build Packet. If it returns `NEEDS ASHLEY` rows, go back to step 5 with them. Don't guess.

**UI tickets** (pages, components, layout, styling): run `develop` here in the main session instead of delegating, because its UI path asks Ashley questions as it goes and a subagent can't. Still return a Build Packet before step 8.

## 8. Check

Delegate **`dev-workflow:qa`** pass 2 with the Story Card, the changed files from the Build Packet and the loop number (never Dev's reasoning). It runs the project's existing tests and build, plus `check verify` for user-facing behavior, and returns a verdict per AC. It doesn't write tests: a missing test comes back as a Bug card for Dev. BLOCKED ACs come with a question for Ashley (for example how to start the app); ask her, then run QA again.
- **FAIL, Cause: Code:** back to `dev-workflow:dev` with the Bug card. Use `debug` thinking: root cause first, never stacked guesses.
- **FAIL, Cause: Spec:** back to `dev-workflow:po` for v<n+1>; Ashley confirms the change before Dev builds again.
- **Loop 3 still failing:** QA's Escalation goes to Ashley. Stop.

On overall PASS, for GA also run `check review` and `document` here in the main session.

## 9. Review-first (⏸)

For anything bigger than a one-line fix, run **`dev-workflow:review-me`**: Ashley reviews first, then the AI reviewer, then the two are compared and her misses are logged.

## 10. Teach-back (⏸)

For anything bigger than a one-line fix, run **`dev-workflow:teach-back`**. Ashley explains the change in her own words before it goes to her lead.

## 11. Wrap up

Hand Ashley:
1. **Client summary:** one short paragraph, no jargon: what changed and why it matters to their business.
2. **For the lead:** PR text (from `document` at GA, or a short version at Beta) with the decision table linked.
3. **Open questions for the client**, if any.
4. **Unsourced or assumed decisions** still owed.

Then suggest running `sync` around merge time.

## Never

- Put client code, client data, patient data or names into Ashley's learning log. Log only the lesson.
- Skip steps 3, 5, 6 or the tests on your own to save time. You may *propose* a lighter version (as in step 3's small-ticket path). Say what it saves, and let Ashley decide.
