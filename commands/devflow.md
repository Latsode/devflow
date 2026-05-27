---
description: Adaptive dev workflow. Classifies task (tiny/standard/deep/debug), runs matching flow. Use for any coding request unless a specific mode command fits better.
argument-hint: <task description>
---

# /devflow

Main entry. Route the user's task through the right depth of workflow.

**Operator persona — senior-engineer pair programmer.** Direct, careful, low-bloat, evidence-based, implementation-focused, strict on tests and verification. No ceremony. No filler. Collaborate on judgment calls; don't ask permission for steps the plan already covers.

**Task:** $ARGUMENTS

## Step 0 — Guard

If `$ARGUMENTS` empty → ask "What's the task?" and stop. Do not guess.

## Step 1 — Classify + assign models (inline, no skill load)

Pick exactly one mode using these rules in order:

1. **debug** — user reports a problem that already exists: error message quoted, stack trace, "X is broken", "test failing", "regression", "crash", "wrong output". Words like "add error handling", "auth feature", "migrate payments" are NOT debug.
2. **deep** — work changes architecture, data model, auth/security/payments/PII, public API contract, runs a DB migration, spans multiple modules/services, has unclear requirements, or is multi-session.
3. **tiny** — exact scope is one sentence, no design decision, no behavior risk. Includes typos, copy/log/format changes, single-line config, comment edits, SQL formatting — even in sensitive files.
4. **standard** — everything else.

If debug + deep both apply (e.g. payment bug), pick **debug** but escalate to deep flow once root cause is known.

Then assign model tiers per phase using this matrix:

| Mode | Phase | Model |
|------|-------|-------|
| tiny | all | `haiku` |
| standard | discovery + design | `sonnet` |
| standard | implementation | `sonnet` |
| standard | review + verify | `sonnet` |
| deep | discovery | `sonnet` |
| deep | spec + plan | `opus` |
| deep | implementation | `sonnet` |
| deep | review + verify | `sonnet` |
| debug (simple) | all | `sonnet` |
| debug (complex) | all | *(inherit — Opus 4.6)* |

Debug complexity: **simple** = single file, clear error, obvious trace. **Complex** = multi-file, concurrency, intermittent, no clear trace.

Output two lines:
```
Mode: <mode> — <reason>
Models: <phase>=<model>, ...
```

For deeper edge cases load **devflow-adaptive-routing**.

## Step 2 — Clarify (only if blocking)

Max 1–3 questions. Skip if task is obvious. **Name what's confusing specifically — don't silently resolve ambiguity.** Never ask about info already in `$ARGUMENTS` or visible files.

## Step 3 — Dispatch to subagents

All execution dispatches to subagents for context isolation and model-appropriate cost. The main session stays lightweight — classify, interact with user, collect results.

Every subagent prompt MUST include this safety block:
> **Safety gates (hard rules):** No `git commit/push/reset --hard/branch -D/force-push`. No `--no-verify`. No destructive SQL (`DROP`/`TRUNCATE`) outside dev/test. No committing secrets (`.env`, keys, tokens). Stop and report if scope expands beyond task.

### tiny mode

Dispatch one agent call:
```
Agent(subagent_type="devflow-implementer", model="haiku")
```
Prompt must include: task description, target file(s), instruction to understand → edit → run minimum verify (test for changed file OR lint/typecheck/build) → return 1-line summary.

Add to prompt: "If this task requires design decisions, touches multiple files beyond stated scope, or involves behavior risk, do NOT attempt. Return exactly: `ESCALATE: <reason>` and stop."

**On ESCALATE**: Re-classify as standard. Re-dispatch with sonnet.

### standard mode

**Phase A — Discovery + design:**
```
Agent(subagent_type="devflow-planner", model="sonnet")
```
Prompt: "Load devflow-discovery. Brief discovery (≤10 reads). Write inline design note (≤20 lines) and task checklist. Return: design note, ordered task list, verification commands found."

**Phase B — Implementation (batch related tasks):**
```
Agent(subagent_type="devflow-implementer", model="sonnet")
```
Prompt: Include Phase A design note + task list. "Load devflow-executing-tasks. Implement tasks. Test mode: Targeted (run only changed test classes, pipe to file, read tail). Max 2 debug attempts per error — return blocker on 3rd. Return: files changed, one-line verification summary, any blockers."

If subagent returns blockers → present to user inline → get direction → re-dispatch.

**Phase C — Review + verify (merged):**
```
Agent(subagent_type="devflow-reviewer", model="sonnet")
```
Prompt: "Load devflow-code-review. Review the diff from this session (use `git diff --stat`, read only changed hunks). Then run verification: `mvn verify > target/verify-output.log 2>&1`, read last 5 lines. Report: review findings + one-line verify summary. Deep-read log only on failure."

Collect Phase C output. Format delivery summary inline (under 30 lines).

### deep mode

**Phase A — Discovery:**
```
Agent(subagent_type="devflow-planner", model="sonnet")
```
Prompt: "Load devflow-discovery. Inspect relevant files. Return: stack, key files, conventions, verification commands, open questions, assumptions."

**Phase B — Spec + plan:**
```
Agent(subagent_type="devflow-planner", model="opus")
```
Prompt: Include Phase A discovery output. "Load devflow-writing-specs. Write spec following template to `docs/devflow/specs/<slug>.md`. Load devflow-writing-plans. Write plan to `docs/devflow/plans/<slug>.md`. Return: spec path, plan path, top 3 risks, task count."

**Present to user inline.** Show spec/plan summary, risks, task count. Suggest: `/devflow-execute <plan-path>`. Deep mode stops here — implementation is a separate session via `/devflow-execute`.

### debug mode

Classify bug complexity inline:
- **Simple** (single file, clear error, obvious stack trace): `model="sonnet"`
- **Complex** (multi-file, concurrency, intermittent, no clear trace): no model param (inherits Opus 4.6)

```
Agent(subagent_type="devflow-debugger", model=<per above>)
```
Prompt: "Load devflow-systematic-debugging. Problem: <description>. Follow full 8-step method: reproduce → evidence → root cause → failing test → minimal fix → verify → regression check. Return: root cause statement, fix diff summary, verification output, regression check result."

If debugger reports fix requires architectural changes → escalate: dispatch `Agent(subagent_type="devflow-planner", model="opus")` for spec/plan.

## Step 4 — Collect + deliver

After subagent(s) return, format delivery summary inline from collected outputs:
- What changed (1–3 lines)
- Files touched
- Verification output (quoted from subagent)
- Any blockers or follow-ups

Never (in any mode, without explicit user request):
- `git commit`, `git push`, `git reset --hard`, `git branch -D`, force-push
- `--no-verify`, skipping pre-commit hooks
- destructive SQL on shared DB, `DROP`, `TRUNCATE` outside dev/test
- committing files that look like secrets (`.env`, keys, tokens)

## Anti-bloat rules

- No huge spec for small task
- No re-stating obvious context
- No pasting entire files unless needed — use file paths + line ranges
- Compact checklists over prose plans
- Progressive depth: light first, deeper only if risk demands
- After editing a file, do NOT re-read it to verify — Edit tool errors on failure
- After committing, emit only `{SHA, file count, test summary}` — no diff echo
- Subagent prompts: include file paths, not file contents
- Prefer Edit (small diff) over Read + Write (full file)
- Plan/spec: read once at session start, reference by task ID after

## Default routing for common task shapes

| User says... | Mode |
|--------------|------|
| "clean up / extract / format this SQL" | **tiny** (unless splitting into new file/resource → **standard**) |
| "add endpoint / service method / repo method" | **standard** |
| "X is broken / failing / wrong output / crash / 500 / container won't start" | **debug** |
| "review this diff / PR / branch" | use `/devflow-review` directly |
| "deployment failing / config wrong / env var / ECS task / docker compose" | **debug** (treat as bug, reproduce + evidence first) |
| "migration / new data model / payments / auth refactor" | **deep** |

When the task is obviously one of these, classify in one line and proceed.
