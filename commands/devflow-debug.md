---
description: Strict debugging flow — reproduce, root-cause, minimal fix, verify. Use for bugs, failing tests, regressions, crashes, perf issues.
argument-hint: <bug description or error message>
---

# /devflow-debug

**Problem:** $ARGUMENTS

## Flow

### Step 1 — Classify bug complexity (inline)

Evaluate the problem description:
- **Simple**: single file suspect, clear error message, obvious stack trace, config typo, missing import
- **Complex**: multi-file interaction, concurrency/race condition, data corruption, intermittent failure, no clear trace, requires hypothesis testing

### Step 2 — Dispatch debugger subagent

```
# Simple bug:
Agent(subagent_type="devflow-debugger", model="sonnet")

# Complex bug:
Agent(subagent_type="devflow-debugger")  # inherits Opus 4.6
```

Prompt: "Load devflow-systematic-debugging. Hard rules: no fix before evidence, no random patches, no multi-variable changes without justification.

Problem: <$ARGUMENTS>

Follow the full 8-step method:
1. Reproduce or observe. Run failing command/test. Capture exact output. Quote errors verbatim.
2. Gather evidence. Stack trace, logs, git blame on suspect lines, recent commits, related tests.
3. Compare working vs broken. Find nearest working example/branch/commit. Diff behavior.
4. Identify root cause. State it explicitly. Distinguish symptom from cause.
5. Failing test / minimal repro. Create one before fixing where practical.
6. Minimal fix. Smallest change that addresses the root cause. No cleanup. No drive-by edits.
7. Verify. Re-run original failing scenario AND the new test. Confirm both pass. Quote the output.
8. Regression check. Run nearby test suite to confirm no breakage.

Safety gates: No git commit/push. No destructive SQL outside dev/test. No secrets. Stop and report if scope expands.

Return: root cause statement, fix diff summary, verification output, regression check result. If fix requires architectural changes, state: ESCALATE_TO_DEEP: <reason>."

### Step 3 — Post-debug (inline)

If debugger returns `ESCALATE_TO_DEEP` → dispatch `Agent(subagent_type="devflow-planner", model="opus")` for spec/plan on the architectural fix.

Otherwise: format delivery summary from debugger output.
