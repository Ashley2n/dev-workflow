---
name: teach-back
description: Check that Ashley understands a finished change before it goes to her lead or client. Asks two or three questions about the decisions in the change, grades her own-words answers, and logs gaps to her learning log. Use only when Ashley runs /teach-back or asks to check she can explain a change, or when /work-ticket or /new-project reaches its teach-back step.
argument-hint: "[optional: the change, ticket or spec to quiz on]"
---

# Teach-back

Ashley has to explain changes to her lead and to clients, often for code Claude wrote. Feeling that she understands it isn't proof. **Explaining it from memory is.** Recalling something from memory is also what makes it stick (see the "fluency vs storage strength" idea in mattpocock's `teach` skill).

## 1. Pick the questions

Read the diff and its spec or decision table. Write **two or three** questions that:

- ask **why**, not what ("Why does the check happen in the service and not the Blazor component?", "What happens if the client's API is down?", "Why this index on the table?")
- come from the decisions and risks that matter most in *this* change, and at least one from a ⚠ unsourced or assumed decision if there is one
- could really come up from her lead or a client

At least one question should be one a **non-technical client** might ask, answered in plain English.

## 2. Ask one at a time (⏸)

Ask the first question, then wait. **Don't show the code or the decision table while she answers.** It's from memory, on purpose.

## 3. Grade each answer

For each answer:
- **Got it:** say what was right in one line.
- **Partly:** what was right, what was missing, and the fuller answer in two or three sentences.
- **Missed:** the answer in plain words, plus one trustworthy source (official docs, or the `path:line` in this repo). Never make up a link.

Then the next question.

## 4. Wrap up

One line: ready to explain to the lead and client, or "review X before the PR".

## 5. Log the gaps

Append each **partly** or **missed** answer to the learning log (path in `~/.claude/CLAUDE.md` under **Learning log**; ask if it isn't set):

```
- YYYY-MM-DD · teach-back · <topic tag> · <the question, made general> · <the key idea she was missing> · <source link>
```

Make the question general, so no client details leak: "why validate in the service layer", not the client's feature name. **Never log client code, client data, patient data or client names.**
