---
name: work-ticket
description: Run a work ticket end to end in an existing codebase. Pasted ticket in, then clarify, decide with sources, build test-first, check, review-first, teach-back, and a plain-English client summary. Use when the user runs /work-ticket or pastes a ticket and asks to work it.
argument-hint: "<pasted ticket text>"
disable-model-invocation: true
---

# Work ticket

You run one ticket through Ashley's workflow. Ashley is a junior developer. At work, **you write most of the code**, but **she steers**: she must understand every decision well enough to defend it to her lead and explain it to a client in plain English. Speed matters (client hours are billed), and so does correctness (some clients handle health data).

This skill is a thin conductor. It calls published skills for the real work and adds only Ashley's checkpoints. Don't redo what those skills already do.

| Step | Skill used | Source |
|---|---|---|
| Context | `audit` | jsmastery-pro/skills |
| Clarify | `grill-me` | mattpocock/skills |
| Decide | `architect` | jsmastery-pro/skills |
| Build | `develop`, `verification-before-completion` | jsmastery-pro/skills, obra/superpowers |
| Check | `check verify`, `test`, `check review`, `document` | jsmastery-pro/skills |
| Review-first | `review-me` | this plugin (wraps mattpocock `code-review`) |
| Teach-back | `teach-back` | this plugin |
| Bugs | `debug` | jsmastery-pro/skills |

If a step's skill isn't installed, say which one is missing and how to install it (see this plugin's README). Don't quietly do the step another way.

Track the steps with a todo list. Stop at every checkpoint marked **⏸** and wait for Ashley.

## 1. Take in the ticket

- Save the pasted ticket text word for word. Ask where it came from (system, person, date) if the text doesn't say. Ticket text plus origin is a **source** for every requirement it states.
- If the ticket is really a bug ("X is broken", "error when..."), say so and offer to run `debug` instead of the feature path.

## 2. Make sure the project has context

- Look for `AGENTS.md` / `CLAUDE.md` at the repo root.
  - **Missing:** recommend running `audit` once for this repo before going on. This happens once per codebase, not once per ticket.
  - **Present:** read it. Don't re-audit.
- **Where decisions live:** find out whether the repo already records decisions or specs (for example `docs/adr/`, `docs/decisions/`, `docs/specs/`, a wiki link in the README). **Use what exists. Never invent a parallel system.** If nothing exists, use `docs/specs/` (what `architect` writes) plus a one-line index `docs/decisions.md`. Write the chosen location into `AGENTS.md` under a short `## Decisions` line, so every skill and teammate finds it.

## 3. Clarify (⏸)

- Read the code the ticket touches **before** asking anything. Never ask what the code can answer.
- Then run **`grill-me`** on the ticket: one question at a time, each with your recommended answer. Ashley prefers this style because it makes her think deeper.
- Ask only what Ashley or the client alone can know (business rules, who's allowed to do what, edge cases the ticket skips). Recommend answers for things expertise settles.
- Anything only the client can answer goes on an **Open questions for client** list. Ashley chooses: wait, or build on a written assumption.

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

Before any code, list the behaviors as plain test names ("returns 404 when the patient isn't found", "rejects an end date before the start date"), each tied to an acceptance criterion. Ashley approves, adds or removes cases. This is the most important learning step at work. Don't skip it on small tickets.

## 7. Build

Run **`develop`** against the approved spec, test-first. Follow `verification-before-completion`: no "done" or "passing" without running the command and showing its output. If `develop` stops because a decision is owed, go back to step 5. Don't guess.

## 8. Check

Run the depth's checking steps in order: `check verify`, then `test`; for GA also `check review` and `document`. If anything fails, use `debug`: root cause first, never stacked guesses.

## 9. Review-first (⏸)

For anything bigger than a one-line fix, run **`review-me`**: Ashley reviews first, then the AI reviewer, then the two are compared and her misses are logged.

## 10. Teach-back (⏸)

For anything bigger than a one-line fix, run **`teach-back`**. Ashley explains the change in her own words before it goes to her lead.

## 11. Wrap up

Hand Ashley:
1. **Client summary:** one short paragraph, no jargon: what changed and why it matters to their business.
2. **For the lead:** PR text (from `document` at GA, or a short version at Beta) with the decision table linked.
3. **Open questions for the client**, if any.
4. **Unsourced or assumed decisions** still owed.

Then suggest running `sync` around merge time.

## Never

- Put client code, client data, patient data or names into Ashley's learning log. Log only the lesson.
- Skip steps 3, 5, 6 or the tests to save time. Say how long a step will take instead, and let Ashley decide.
