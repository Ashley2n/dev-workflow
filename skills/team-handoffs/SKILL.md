---
name: team-handoffs
description: Shared handoff rules and formats for the PO, Dev and QA agents (Story Card, Build Packet, Test Plan, QA Report, Bug card, loop cap). Load only when /work-ticket or the conductor agent passes work between dev-workflow:po, dev-workflow:dev and dev-workflow:qa.
user-invocable: false
---

# Team handoffs

The one place for how work moves between `dev-workflow:po`, `dev-workflow:dev` and `dev-workflow:qa`. `/work-ticket` and `dev-workflow:conductor` both follow this file; change a rule here, not in either of them (D23).

Adapted from Ashley's Grok-Team design (`01-Projects/Personal-Projects/Grok-Team/` in her vault, decisions D4–D7, D13, D15).

## Flow

```
request or ticket (+ answers Ashley already gave)
  → PO      Story Card <ID> v<n>, READY or NOT READY
  → Dev     Build Packet <ID> v<n> - loop <k>, or NEEDS ASHLEY rows
  → QA      QA Report <ID> v<n> - loop <k>
              PASS                → done
              FAIL, Cause: Code   → Dev, loop k+1
              FAIL, Cause: Spec   → PO, card v<n+1>, then Ashley confirms the change
              loop 3 still failing → Escalation to Ashley, stop
```

Big tickets (`/work-ticket` only, D48–D55): one card whose ACs are grouped into slices of the spec's `## Build plan`.
```
per slice S<m>, in order
  → Dev     Build Packet <ID> v<n> S<m> - loop 1, slice gate green (or BLOCKED after 3 gate attempts → stop, ask Ashley)
  → QA      slice check, only on GA tickets and slices with UI ACs
  → conductor commits the slice locally: <ticket> S<m>: …
after the last slice
  → QA      QA Report <ID> v<n> - loop <k> over every AC, then the flow above (a Code bug goes to Dev with its Slice)
```

## Rules for whoever passes the work

1. **Subagents can't ask Ashley anything.** Settle unclear points before delegating. When an agent returns `NOT READY`, `NEEDS ASHLEY` or an Escalation, stop and bring it to Ashley. Never answer for her.
2. **Give QA the Story Card and the list of changed files, never Dev's reasoning.** QA judges the code against the card with fresh eyes.
3. **Version stamps everywhere.** An agent that gets a card older than one it has seen stops and says so.
4. **Two counters, never mixed (D55).** **Dev↔QA loops:** max 3 per card version, then escalate. **Gate attempts** (big tickets): max 3 per slice, inside that slice's Dev run, then BLOCKED. Gate attempts never count as Dev↔QA loops.
5. **Files.** In a `/work-ticket` run, handoffs are saved in the ticket folder next to `ticket.md`: `story-card.md`, `build-packet.md`, `qa-report.md` (newest on top). Big tickets use `build-packet-S<m>.md` per slice instead of `build-packet.md`, plus `exploration.md` (the scout map, D53) and `S<m>-gate-failure.patch` for a BLOCKED slice (D55). None of these is ever committed. In a team repo, run `git check-ignore -q <path>` before writing any of them and don't write if it isn't ignored (D18). The conductor writes no handoff files; it carries them in its prompts and report.
6. **Data.** Made-up data only in examples, fixtures and test data. Never client data, patient data or client names in anything that leaves the repo, including the learning log.

## Formats

### Story Card (PO)
```
## Story Card: <ID> v<n>
**Story:** As a <user>, I want <goal>, so that <reason>.
**Acceptance criteria**
- AC1: Given ... When ... Then ...
**Out of scope:** ...
**Open questions:**
- [resolved | UNRESOLVED] question -> answer (source)
**Change note:** (v2+ only) what changed and why
**Big ticket:** no | yes (<which signal>)
**Slices:** (big tickets only, card v2)
- S<m> = tasks <n>–<n> | ACs: AC1, AC2 | Blocked by: — or S<k> | Files: expected paths | UI: no, delegate or main
**Status:** READY | NOT READY (<reason>)
```
- READY only when nothing is UNRESOLVED. 3–6 ACs; bigger means propose a split, or flag it as a big ticket (`/work-ticket` only). **Big cards are exempt from the 3–6 cap** (D65).
- **Slices** (D49, D50): written by the `/work-ticket` conductor after `/architect`, never by PO. Tasks are numbers from the spec's `## Build plan`, the only task list; never copy or reword the tasks. Every AC is in exactly one slice; Blocked by names only earlier slices. Card v2 adds only the grouping; any AC change is a normal version bump that Ashley confirms.
- Each AC is one observable behavior, testable without reading code.

### Build Packet (Dev)
```
## Build Packet: <ID> v<n> - loop <k>        (slice mode: <ID> v<n> S<m> - loop <k>)
1. Decisions: | # | Decision | Options considered | Why this one | Risk / tradeoff | Source |
2. AC map: ACn -> file / function / test name
3. Files: new (+) / changed (~), with paths
4. Ran: exact commands and their real output (tests, build)
5. QA note: what changed / what I checked / what I'm unsure of
6. Suggestions: ideas outside the ACs (not built)
7. Principles: IDs applied from principles.md (P-STD-1, P-ARCH-5, ...), and the repo style guide rule that won where one conflicted
8. Slice gate (slice mode only): PASS with the command and its output, or BLOCKED after 3 attempts with the failing output and the likely cause
```
- A slice packet covers only that slice's tasks and ACs, and stays short.
- Source is ACn, the ticket, a `path:line`, official docs (link), a person + date, or `NEEDS ASHLEY`. Any `NEEDS ASHLEY` row means no code was written.

### Test Plan (QA, pass 1)
```
## Test Plan: <ID> v<n>
| AC | Test cases (happy / edge / error) as plain test names | Auto or manual |
Manual steps: numbered, each with its expected result
Spec gaps: ACs that are ambiguous, contradictory or untestable
Slice grouping (big tickets): | Check | yes / no | Fix if no |
```

### QA Report (QA, pass 2)
```
## QA Report: <ID> v<n> - loop <k>
Slice: all | S<m> (a slice check)
| AC | PASS / FAIL / BLOCKED | Evidence (test name + result, or manual check) |
Standards: the yes/no check of each principle in principles.md that applies to the changed files, as `P-STD-3 pass` or `P-ARCH-5 fail: <file>`. P-STD-3 (silent failures) and P-STD-1 (features no AC asked for) always apply
Security: changed files against `/check review`'s Security list (unvalidated input, injection, missing auth checks, secrets in code or logs, sensitive data exposure) and P-ARCH-3; each finding is a Bug card
Overall: PASS only if every AC passes and no Security Bug card is open
Bug <ID>-B<n> | AC | Slice: S<m> or — | Cause: Code (-> Dev) or Spec (-> PO) | Steps | Expected | Actual | Severity: high/med/low
```
- No evidence means BLOCKED, not PASS.
- Cause is Spec when the AC is ambiguous, contradictory or missing, so Dev never has to guess.

### Escalation (QA, loop 3)
What keeps failing, the likely root cause (spec / approach / tool limits), and options for Ashley.
