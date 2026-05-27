---
description: Final verification + delivery summary. Use when implementation is complete and you want a clean handoff.
argument-hint: <optional context>
---

# /devflow-finish

## Flow

### Step 1 — Verification (subagent)
```
Agent(subagent_type="devflow-reviewer", model="sonnet")
```
Prompt: "Load devflow-verification. Discover and run the project's real verification commands (build, test, lint, typecheck). Quote all output. If any fail, report which and stop."

### Step 2 — Self-review (subagent)
```
Agent(subagent_type="devflow-reviewer", model="sonnet")
```
Prompt: "Load devflow-code-review. Quick pass over the current diff. Return: findings list, recommendation."

### Step 3 — Handoff (inline)

Collect outputs from steps 1-2. Format handoff using `~/.claude/devflow/templates/handoff-template.md`. Inline for small work, save to `docs/devflow/handoffs/<slug>.md` for deep work.

### Step 4 — Delivery summary (inline)
- what changed (1–3 lines)
- files touched
- verification commands + result (quoted from step 1)
- review findings (from step 2)
- known limitations / follow-ups
- suggested next step (commit message draft, PR title, etc.)

No "should work" / "probably fixed" language. Evidence only.
