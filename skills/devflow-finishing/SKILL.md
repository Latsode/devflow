---
name: devflow-finishing
description: Final handoff and delivery summary. Use at end of any devflow task and during /devflow-finish. Produces evidence-backed summary, optional handoff doc, and next-step suggestion.
---

# Finishing

## Pre-finish checklist

Run all of these before writing the summary:

- [ ] All planned tasks marked complete
- [ ] **devflow-verification** ran and is green (or explicitly marked pending with reason)
- [ ] **devflow-code-review** self-review ran (standard/deep tasks)
- [ ] No unrelated files modified (check `git status` / `git diff --stat`)
- [ ] No debug code, prints, commented blocks left behind
- [ ] No secrets in diff

## Delivery summary structure

```
## Summary
<1–3 sentences: what changed and why>

## Files changed
- path/one
- path/two

## Verification
- $ <cmd>
  <quoted output snippet — pass counts / build OK>

## Known limitations
- <or "none">

## Next step
<commit message draft, PR title, or "ready to merge">
```

## When to write a handoff file

- **tiny** — no file, summary in chat only
- **standard** — no file unless the user asks
- **deep** — file at `docs/devflow/handoffs/<kebab-slug>.md` using `~/.claude/devflow/templates/handoff-template.md`

## Forbidden

- Restating the plan
- Re-narrating each task done (the plan checkboxes already do that)
- Speculating about future work that wasn't asked
- Pleasantries
- **Running `git commit`, `git push`, `git tag`, or any branch-mutating command without an explicit user request.** Draft the commit message in the summary — do not execute it.
- **Opening PRs / posting to external services** unless the user asked.
