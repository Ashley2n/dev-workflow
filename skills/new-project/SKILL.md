---
name: new-project
description: Start a brand-new personal project the senior-engineer way. Scope, decide the stack with sources, scaffold, audit, then build features in coach mode where Ashley writes most of the code. Use when the user runs /new-project or wants to plan a new app from scratch.
argument-hint: "<the idea, in a sentence or two>"
disable-model-invocation: true
---

# New project

You guide Ashley from an idea to a running first feature. This is for **personal projects**, where **Ashley writes most of the code** and you coach. The goal is a good app **and** a better developer.

It follows the greenfield path from jsmastery-pro/skills: **scope → architect the stack → scaffold → audit → feature loop**. Call those skills for the real work. This skill only adds Ashley's preferences and checkpoints. If a skill isn't installed, say which one and point to this plugin's README.

Track the stages with a todo list. Stop at every **⏸**.

## 0. Before anything

- Check Ashley's vault (`MyVault/01-Projects/Personal-Projects/`) for an existing folder or notes on this idea. Many of her projects already have a PRD, SRS, RFC, ADR or roadmap. **Use what exists. Don't re-plan from zero.**

## 1. Scope (⏸)

Run **`scope`**. Use **`grill-me`** for anything fuzzy: one question at a time, each with a recommended answer.

- When `scope` asks for the delivery style, explain the four options in one line each and recommend one.
- When it asks for the workflow depth, recommend **Beta** (tests included). Recommend **Prototype** only if Ashley says it's a throwaway experiment.

## 2. Decide the stack (⏸)

Run **`architect`** in stack mode, with references level **`sources+links`**.

Apply Ashley's **stack rule**:
1. If one stack is the **clear winner** on compatibility, documentation, reliability or performance for this idea, pick it.
2. If the options are **roughly equal**, pick her work stack: **C# / ASP.NET Core / Blazor** (she gets twice the practice).
3. Say which case applied and why, as a row in the decision table below, with a real source.

Decision table (rows into the project's decision record, `docs/specs/` plus `docs/decisions.md` index unless the project already has one):

| Decision | Options considered | Why this one | Risk / tradeoff | Source |
|---|---|---|---|---|

No invented sources. "Claude knows this" is marked **⚠ unsourced** until backed up or explicitly accepted.

## 3. Scaffold, then audit

- Ashley runs the stack's own scaffold command herself (for example `dotnet new blazor`). Explain what each generated folder is for in two lines each. This is free fundamentals.
- Turn on coach mode for this repo only:
  `claude plugin install learning-output-style@claude-plugins-official --scope local`
  `claude plugin disable explanatory-output-style@claude-plugins-official --scope local` (coach mode already includes explanations)
- Run **`audit`** so `AGENTS.md` describes the real, scaffolded project.

## 4. Feature loop, in coach mode

For each feature in scope order:

1. **`architect`** for the feature (⏸ approve the decision table).
2. **Test cases first** (⏸): Ashley writes the plain-English test names. You suggest any she missed and explain why each matters.
3. **`develop`**, but **Ashley writes the core logic**. You set up the files, boilerplate and wiring. At each real decision point (business rule, error handling, data shape), stop and ask her to write it. Coach mode does this automatically. Give hints and questions first. Show a full answer only if she asks or has been stuck past the limit she set (default 20 minutes).
4. The depth's checks: `check verify`, `test` (Beta and above).
5. **`review-me`** (⏸): she reviews her own code first, then compares with the AI reviewer.
6. **`teach-back`** on anything new to her.
7. `sync`, then commit.

## 5. Record it in the vault

Make sure the project has a folder in `MyVault/01-Projects/Personal-Projects/<Project-Name>/` with a `README.md`, and that the vault's root `CLAUDE.md` map lists it. Follow the vault's own `CLAUDE.md` rules.
