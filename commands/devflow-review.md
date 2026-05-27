---
description: Code review only. No implementation. Use to audit current diff, branch, or specified files.
argument-hint: <files, diff range, or "current branch">
---

# /devflow-review

**Target:** $ARGUMENTS (defaults to current unstaged + staged diff)

## Flow

### Step 1 — Resolve scope (inline)

- `$ARGUMENTS` is a branch / range / SHA → capture `git diff` output
- `$ARGUMENTS` is file path(s) → note them
- `$ARGUMENTS` empty AND repo is git → run `git diff HEAD` + `git status`. If empty, ask user what to review.
- `$ARGUMENTS` empty AND not a git repo → ask user for explicit file paths. Do not invent scope.

### Step 2 — Dispatch reviewer subagent

```
Agent(subagent_type="devflow-reviewer", model="sonnet")
```

Prompt: "Load devflow-code-review. Produce review using `~/.claude/devflow/templates/review-template.md`.

Target scope: <resolved scope from step 1>

Walk through checklist:
- requirement match (compare against stated intent)
- correctness
- edge cases
- security (input validation, auth, secrets, injection)
- performance (N+1, hot paths, allocations)
- test coverage (matched to changed behavior)
- readability / maintainability
- unnecessary complexity / over-engineering
- accidental unrelated changes

Return: per-finding location (`file:line`), problem, fix suggestion. End with recommendation: **approve** / **approve-with-fixes** / **request-changes**."

### Step 3 — Present (inline)

Format and display reviewer output. Do not modify code.
