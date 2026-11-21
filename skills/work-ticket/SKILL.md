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
| Security (GA) | `security-review` | built into Claude Code |

If a skill isn't installed or the call is refused, stop and say which one, and how to install it (see this plugin's README). Don't quietly do the step another way.

**Agents (D21–D22).** You are the conductor: grilling, `architect` and every ⏸ checkpoint stay with you in the main session, because subagents can't ask Ashley questions. The writing, building and checking go to this plugin's agents. First invoke **`dev-workflow:team-handoffs`** and follow its flow, formats and loop cap.

| Step | Agent | Gets | Returns |
|---|---|---|---|
| 3 | `dev-workflow:po` | `ticket.md` + Ashley's grilling answers | Story Card → `story-card.md` |
| 6 | `dev-workflow:qa` (pass 1) | Story Card only | Test Plan, the draft test names for the checkpoint |
| 7 | `dev-workflow:dev` | Story Card + approved decisions + approved test names | Build Packet → `build-packet.md` |
| 8 | `dev-workflow:qa` (pass 2) | Story Card + changed files + loop number | QA Report → `qa-report.md` |
| 5, big | `scout` | the ticket area, from the card and spec | exploration map → `exploration.md` |

**Small, clear tickets** (step 3's small-ticket path): write the one-AC Story Card and the test names yourself in the team-handoffs formats, and delegate only `dev-workflow:dev` and `dev-workflow:qa` pass 2. Each agent re-reads the code from scratch, so skipping PO and QA pass 1 halves the cost where they add little. The step 6 checkpoint still happens.

**Big tickets** (D48–D66): PO flags them at step 3 and Ashley confirms. Then the spec's `## Build plan` is grouped into slices after step 5, and step 7 builds, gates and commits one slice at a time, with one QA pass 2 at the end. The parts marked **Big:** below apply only to them. Big tickets run here only; the conductor agent sends them here (D59). Slices run one after another; parallel slices are revisited after 3 big tickets, at the monthly metrics run (D60).

Track the steps with a todo list. Stop at every checkpoint marked **⏸** and wait for Ashley.

## 0. Resume or start

Every ticket gets a folder, `<specs location>/<ticket-id-or-short-slug>/` (specs location from step 2; default `docs/specs/`). Agent handoffs (`story-card.md`, `build-packet.md`, `qa-report.md`) are saved there too. Its `ticket.md` holds the ticket word for word, its origin, and a `## Progress` checklist of steps 1–11. Tick a step and add a one-line outcome (depth chosen, decisions approved, test names agreed, open client questions) **each time a step finishes**. This file is how the work survives a long session, a summarized context, or tomorrow morning.

If a folder for this ticket already exists, read its `ticket.md`, say which step you're resuming at, and continue from there. Don't redo finished steps.

**Big:** the folder also holds `exploration.md`, one `build-packet-S<m>.md` per slice and, for a BLOCKED slice, `S<m>-gate-failure.patch`. None of them is ever committed. `## Progress` records the base commit (`Base: <sha>`, the branch point from step 6) and one line per slice, updated as it moves (D65):
```
- S2 (tasks 4–5): planned → building → gate passed → committed <sha>
```
On resume, a slice is done only if its commit exists (`git cat-file -e <sha>` and `git log <base>..HEAD` shows it). A dirty tree with no commit for the current slice: show `git status` and ask Ashley what to do. Never clean it up on your own.

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
- **Big:** if the card says `Big ticket: yes`, propose the big path in one line: which signal, and what it costs (more checkpoints at step 6, one commit per slice) and saves (each slice is built in a fresh context and gated before the next). Ashley confirms or declines, and you record `Size: big` or `normal` in Progress (D48).

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

**Big: group the Build plan into slices (D49, D50, D62).** After `architect` and its cross check, read only the spec's `## Build plan` section and write the **Slices** section into Story Card v2 (team-handoffs format). Don't send it back to PO.
- A slice is a group of Build-plan task numbers. Never copy, reword or add tasks; the Build plan stays the only task list, the one `develop` ticks and resumes from.
- Slices are vertical: each cuts through every layer its ACs need and can be checked on its own. Every AC is in exactly one slice. About 1–3 ACs each (⚠ unsourced). A wide mechanical refactor may be S1.
- Each slice lists Blocked by (earlier slices only) and expected files.
- **Merge rule:** more than about 4 slices, or a slice with one small AC, means merge slices (⚠ unsourced, tuned from the ticket log).

**Big: map the area once (D53).** Brief a `scout` agent on the ticket area (the card's ACs and the spec's key interfaces) and write its map to `exploration.md` in the ticket folder. Only facts about code that already exists: paths, patterns (`file:line`), helpers to reuse, gotchas. If the `scout` type isn't installed, stop and say to re-run `install.sh` (D56).

## 6. Agree the test cases (⏸)

Before any code, list the behaviors as plain test names ("returns 404 when the patient isn't found", "rejects an end date before the start date"), each tied to an acceptance criterion. Draft them with **`dev-workflow:qa`** pass 1 (Story Card only, so the cases come from the card and not from a plan for the code). Ashley approves, adds or removes cases. This is the most important learning step at work. Don't skip it on small tickets.

**Big:** give QA pass 1 card v2 and the spec's path; it also checks the slice grouping (D58). Bring any UNRESOLVED grouping row to Ashley with QA's fix. At this checkpoint Ashley also approves, once for the whole ticket:
1. **The slices**, and which test names belong to each.
2. **UI per slice (D54):** `delegate` only if the slice follows an existing screen or component named in `exploration.md` **and** every UI answer (assets, which screen to copy, styling, platform quirks) is collected into card v2 now. Otherwise `main`: it runs in this session.
3. **Slice commits (D52):** you commit each slice locally after its gate, on the ticket branch. Still on the base branch? Ask Ashley for the branch name and create it first. Record the base commit in Progress.
4. **Keep or squash** the slice commits before the PR. Recommend one from the repo's history (`git log --first-parent --oneline origin/<base>`: merge commits keep the slices visible, one commit per PR means squash).

## 7. Build

Delegate the build to **`dev-workflow:dev`** with the Story Card, the approved decisions and the approved test names. It runs `develop` test-first and follows `verification-before-completion`: no "done" or "passing" without the command's real output in the Build Packet. If it returns `NEEDS ASHLEY` rows, go back to step 5 with them. Don't guess.

**UI tickets** (pages, components, layout, styling): run `develop` here in the main session instead of delegating, because its UI path asks Ashley questions as it goes and a subagent can't. Still return a Build Packet before step 8.

**Big: one slice at a time, in order (D51–D55, D65).** For each slice:
1. Set its Progress line to `building`.
2. **Build.** `delegate`: send `dev-workflow:dev` in **slice mode** the card, the slice line, its approved test names, the approved decisions, the base commit and the ticket folder path. `main`: run `develop` here on the slice's tasks only, under the same slice-mode rules. Save the packet as `build-packet-S<m>.md`.
3. **NEEDS ASHLEY:** on a delegated UI slice, move that slice to this session instead of re-sending it (D54). Otherwise go back to step 5 with the rows, as above.
4. **Gate (D51).** The packet's item 8 must show the slice's tests and the full existing suite green, plus the real-app evidence for any UI AC. Before committing, run the full test command once yourself (`verification-before-completion`); never commit on the packet's word alone.
5. **BLOCKED after 3 gate attempts (D55):** don't commit. Save the work: `git add -N <new files from the packet>`, then `git diff HEAD --binary > <ticket folder>/S<m>-gate-failure.patch`. Stop before the next slice and give Ashley the failing output, the likely cause and three options: retry with `debug` in a fresh agent, re-slice, or pull the slice into this session. Reset the tree only after she chooses.
6. **Slice check (D51):** on a GA ticket, or a slice with UI ACs, run `dev-workflow:qa`'s slice check on that slice. A Code bug goes back to Dev for this slice (Dev↔QA loops count here).
7. **Commit (D52).** `git add <paths>`: the packet's files plus the spec (its Build plan ticks). Never `-A`, never chained with a build command. Message `<ticket> S<m>: <what the slice does>`. Local only: never push a slice commit; pushing waits for Ashley after step 9. Set Progress to `committed <sha>`.

After the last slice, do `develop`'s Step 4 once for the whole ticket: the `verify.md` panel, the scope update and the offer to mark it done. Slice-mode Dev skips them (D65).

## 8. Check

Delegate **`dev-workflow:qa`** pass 2 with the Story Card, the changed files from the Build Packet and the loop number (never Dev's reasoning). It runs the project's existing tests and build, plus `check verify` for user-facing behavior, and returns a verdict per AC. It doesn't write tests: a missing test comes back as a Bug card for Dev. BLOCKED ACs come with a question for Ashley (for example how to start the app); ask her, then run QA again.
- **FAIL, Cause: Code:** back to `dev-workflow:dev` with the Bug card. Use `debug` thinking: root cause first, never stacked guesses.
- **FAIL, Cause: Spec:** back to `dev-workflow:po` for v<n+1>; Ashley confirms the change before Dev builds again.
- **Loop 3 still failing:** QA's Escalation goes to Ashley. Stop.

**Big:** one QA pass 2 over every AC. Changed files are `git diff --name-only <base>..HEAD` plus anything uncommitted. A Code Bug card goes to `dev-workflow:dev` in slice mode for the slice its `Slice:` field names, through the same gate and 3 attempts, and you commit the fix locally as `<ticket> S<m>: fix <ID>-B<n>` (D66).

On overall PASS, for GA also run `check review` and `document` here in the main session, then `security-review` on the branch before step 9 (D63).

## 9. Review-first (⏸)

For anything bigger than a one-line fix, run **`dev-workflow:review-me`**: Ashley reviews first, then the AI reviewer, then the two are compared and her misses are logged.

**Big (D65):** pass the base commit as the fixed point, so the review covers `<base>..HEAD`. Ashley reviews slice by slice (`git show <sha>` per slice); the AI reviews the whole range once. You commit review fixes locally as `<ticket> review: …`. Pushing the branch waits for Ashley's go after this step (D52).

## 10. Teach-back (⏸)

For anything bigger than a one-line fix, run **`dev-workflow:teach-back`**. Ashley explains the change in her own words before it goes to her lead.

**Big:** two or three questions across all the slices, the riskiest slice first (D65).

## 11. Wrap up

Hand Ashley:
1. **Client summary:** one short paragraph, no jargon: what changed and why it matters to their business.
2. **For the lead:** PR text (from `document` at GA, or a short version at Beta) with the decision table linked.
3. **Open questions for the client**, if any.
4. **Unsourced or assumed decisions** still owed.

Then suggest running `sync` around merge time.

**Big:** delete `exploration.md` (D53). If Ashley chose squash at step 6, remind her before the PR.

## Never

- Put client code, client data, patient data or names into Ashley's learning log. Log only the lesson.
- Push a slice commit, or start the big path without Ashley's yes at step 3.
- Skip steps 3, 5, 6 or the tests on your own to save time. You may *propose* a lighter version (as in step 3's small-ticket path). Say what it saves, and let Ashley decide.
