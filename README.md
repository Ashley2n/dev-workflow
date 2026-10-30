# dev-workflow

My Claude Code engineering workflow, made to get work done **and** to make me a better developer.

At work, Claude writes most of the code and I steer: every decision needs a source, and I check that I can explain it before it ships. In personal projects, I write most of the code and Claude coaches. Both paths end with **me reviewing first** and **explaining the change back**, and my misses go into a learning log that decides what fundamentals I study next.

Most of the workflow is **published skills used unchanged**. This repo adds four small skills, a hidden handoff-rules skill, four agents and a settings template.

## How it fits together

```
Work ticket   /work-ticket <paste ticket>
  audit (once per repo) → grilling → po agent (Story Card) → architect (decision table + sources)
  → qa agent (test cases) → dev agent (builds) → qa agent (verdict per AC, max 3 loops)
  → [GA: check review → document]
  → review-me → teach-back → client summary

New project   /new-project <idea>
  scope → architect the stack → scaffold → audit
  → per feature: architect → test cases → develop (I write; coach mode) → check → test
  → review-me → teach-back → sync
```

## What's in this repo

| Skill | What it does |
|---|---|
| `/work-ticket` | Runs a pasted ticket through the work path above. Stops for my approval at clarify, decisions, test cases, review and teach-back. |
| `/new-project` | Greenfield path with coach mode on. Applies my stack rule: a clear winner wins, otherwise C# / ASP.NET Core / Blazor. |
| `/review-me` | I review the diff first (with `checklist.md`), then Matt Pocock's `code-review` runs, then the two are compared and my misses are logged. |
| `/teach-back` | Two or three "why" questions about the change, answered from memory, graded, with gaps logged. |
| `agents/po.md`, `dev.md`, `qa.md` | PO writes the Story Card, Dev builds it test-first and sources every decision, QA plans tests from the card and then gives a verdict per acceptance criterion. Adapted from my Grok-Team prompts. `/work-ticket` delegates to them; they never ask me anything, they stop and return questions. |
| `agents/conductor.md` | For ad-hoc tasks that aren't tickets: routes one clear task through PO, Dev and QA and returns one report. Runs only when I name it: `@"dev-workflow:conductor (agent)" <task>`. |
| `team-handoffs` (hidden skill) | The one copy of the handoff rules and formats (Story Card, Build Packet, QA Report, 3-loop cap) that `/work-ticket` and the agents all read. |
| `templates/user-claude.md` | My preferences (source rules, depth, stack rule, learning-log path), appended to `~/.claude/CLAUDE.md`. |
| `scripts/local-setup.sh` | For team repos. Keeps AGENTS.md, CLAUDE.local.md and docs/specs, scope and reviews out of git via `.git/info/exclude`, and makes CLAUDE.local.md import `@AGENTS.md`. Never touches the team's CLAUDE.md. |

`/work-ticket` and `/new-project` only run when I type them (`disable-model-invocation: true`), so Claude never starts a ticket on its own. `/review-me` and `/teach-back` don't have that flag, because the pipelines have to call them, and Claude Code blocks calls to flagged skills. Their descriptions limit them to my request or a pipeline step. For the same reason the pipelines clarify with `mattpocock-skills:grilling`, not the user-only `grill-me`. Plugin skills are namespaced: `/dev-workflow:work-ticket`, or just `/work-ticket` when no other command has that name ([docs](https://code.claude.com/docs/en/skills)).

## What it builds on (install all of these)

| From | Pieces | Used for |
|---|---|---|
| [jsmastery-pro/skills](https://github.com/jsmastery-pro/skills) (MIT) | scope, audit, architect, develop, check, test, document, sync, debug | The core plan → build → verify workflow |
| [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), official plugin | grilling, grill-me, teach, wait-what, code-review, and more | Clarifying, studying fundamentals, the independent review |
| [obra/superpowers](https://github.com/obra/superpowers) (MIT) | receiving-code-review, verification-before-completion | Handling lead feedback; evidence before "done" |
| [Anthropic official plugins](https://github.com/anthropics/claude-plugins-official) | explanatory-output-style (global), learning-output-style (personal repos only), csharp-lsp, security-guidance | Explanations, coach mode, C# intelligence, security review |

## Install

```bash
git clone https://github.com/Ashley2n/dev-workflow.git
cd dev-workflow
bash scripts/install.sh
```

Just this plugin, without the published pieces: `/plugin install dev-workflow --marketplace Ashley2n/dev-workflow`

Then restart Claude Code. On a work machine, check that the **Learning log** path in `~/.claude/CLAUDE.md` points at your vault.

In each **team repo**, once, before `/audit`:

```bash
bash path/to/dev-workflow/scripts/local-setup.sh path/to/team-repo
```

Safe to re-run, but it won't add new patterns to a repo it already set up. For repos set up before v0.3.0, add `/docs/decisions.md` by hand inside the `dev-workflow` block of `.git/info/exclude`. When `/audit` offers to move the team's CLAUDE.md into AGENTS.md, answer no. Afterwards `git status` should show nothing new.

Coach mode is per repo. `/new-project` turns it on with:

```bash
claude plugin install learning-output-style@claude-plugins-official --scope local
claude plugin disable explanatory-output-style@claude-plugins-official --scope local
```

## Rules this workflow keeps

- **No decision without a source.** Official docs, a `path:line` in the repo, a person + date, or the ticket. Anything else is marked ⚠ unsourced.
- **Use what the repo already has** for decisions and docs. Never invent a parallel system.
- **Work tickets always get tests** (Beta). GA for login, permissions, personal or health data, payments and migrations.
- **No client code or data in my learning log.** Only the lesson.

## License

MIT. The published skills keep their own licenses and authors (see table above).
