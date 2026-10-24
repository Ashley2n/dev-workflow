---
name: review-me
description: Review-first practice. Ashley reviews the change herself, then an independent AI review runs (mattpocock code-review), then the two are compared and her misses are logged so her study list comes from real mistakes. Use only when Ashley runs /review-me or asks to practice reviewing a change, or when /work-ticket or /new-project reaches its review-first step. Not for ordinary "review this PR" requests.
argument-hint: "[fixed point to diff against, default: the branch's merge-base with the default branch]"
---

# Review me

Ashley is a junior developer learning to review code: her own, Claude's, and teammates'. Reading a checklist won't build that skill. **Trying, then comparing with a stronger reviewer, again and again** will. This skill runs that loop once.

The independent review is **mattpocock `code-review`**, used unchanged. This skill only adds the "you first" step, the comparison and the log.

## 1. Set up

- Work out the fixed point: the argument if given, else the merge-base with the repo's default branch (team repos often use `develop` or `master`, not `main`):
  ```bash
  BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
  FIXED=$(git merge-base HEAD "$BASE")
  git diff "$FIXED" --stat   # committed + uncommitted changes since the fixed point
  ```
  List the changed files with a one-line summary each. **Don't hint at problems.**
- Open `checklist.md` (next to this file) and show Ashley the checklist.

## 2. Ashley reviews first (⏸)

Ask her to write her findings in any form: file, what she noticed, why it worries her. Suggest 5–10 minutes. **Show no AI findings yet, and don't run the AI review yet.** If she asks for a hint, point to a checklist area ("look at error handling in `X.cs`"), never the answer.

"I found nothing" is a valid answer. Record it.

## 3. Independent review

Run **`mattpocock-skills:code-review`** on the same fixed point. Use that full name: Claude Code also ships a built-in `code-review`, which is a different reviewer without the Standards/Spec split. If there's a spec or ticket, give it the spec so both of its checks run (Standards and Spec). Keep only findings it is confident about. Pre-existing issues that the diff didn't touch don't count.

## 4. Compare

Show one table:

| Finding | Ashley | AI | Verdict |
|---|---|---|---|
| … | ✅ caught | ✅ | **Both caught** |
| … | ❌ | ✅ | **Missed:** why it matters, plus the fundamental behind it |
| … | ✅ | ❌ | **Ashley only:** say honestly whether it's a real issue (a good catch the AI missed) or a false alarm, and why |

For each miss, name the **fundamental** in a few words (for example "async void swallows exceptions", "N+1 query from lazy loading", "missing authorization check: user can read another user's record", "Feature Envy (Fowler)") and link **one** trustworthy source, such as Microsoft Learn, official docs or Fowler's *Refactoring* catalog. Never make up a link.

End with one line: her catch rate this time, and the one thing to look for first next time.

## 5. Fix decisions

For each real finding, Ashley chooses: fix now, fix later (make a ticket), or leave it with a reason. If her lead's review later adds comments, use **`receiving-code-review`** (obra/superpowers) to handle them.

## 6. Log the misses

Append one line per **missed** finding (and per real catch the AI missed, marked ⭐) to the learning log. Find the path in `~/.claude/CLAUDE.md` under **Learning log**. If it isn't set, ask Ashley.

```
- YYYY-MM-DD · <topic tag> · <what was missed, one line> · <why it matters, one line> · <source link>
```

Topic tags are short and reused (`async`, `ef-core`, `di`, `auth`, `validation`, `testing`, `blazor-state`, `naming`, `smell/feature-envy`…), so the monthly "top three topics" count works.

**Never write client code, client data, patient data, client names or file paths from client repos into the log. Only the lesson.**
