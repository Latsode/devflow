---
description: Execute an existing plan task-by-task. Use after /devflow-plan when plan is approved and you want implementation.
argument-hint: <plan path or task description>
---

# /devflow-execute

Implementation phase. Assumes plan already exists (file path or inline checklist).

**Plan / task:** $ARGUMENTS

## Flow

1. **Locate plan** (inline):
   - If `$ARGUMENTS` is a file path → read it.
   - Else if `$ARGUMENTS` is an inline task list → use it directly.
   - Else if `docs/devflow/plans/` has exactly one file → use it.
   - Else list candidate plan files (with dates) and ask the user which one. Do not guess.

2. **Determine plan origin mode** (inline):
   - Check plan metadata or spec file for mode (deep vs standard).
   - If plan came from `/devflow-plan` or spec exists in `docs/devflow/specs/` → **deep** (use sonnet for impl).
   - Otherwise → **standard** (use sonnet for impl).

3. **Dependency scan** (inline):
   Scan the plan for references to external modules, sibling repos, or libraries whose source isn't in the working directory. Look for:
   - Import statements referencing packages not in `src/`
   - Plan tasks mentioning external models, mappers, or shared libraries
   - Column names, enum values, or APIs from external jars

   If found, collect into a list and ask at the session gate:
   > "This plan references external dependencies I can't inspect in this repo: `[list]`.
   > Provide local paths or git URLs so I can read source directly — or tell me the specific types/fields I need to know."

   Save confirmed paths as a reference memory (`external-source-paths`) for future sessions. Check existing memory first — paths may already be known.

4. **Session gate (inline — always, even for tiny scopes).**
   Before dispatching any subagent, post a single summary message containing:
   - Plan source (file path or inline)
   - Plan origin mode (deep/standard — both use sonnet for implementation)
   - Session scope: exactly which tasks will run this session. If the plan is large, propose a sensible cut and say which tasks are deferred and why.
   - Order they'll run in
   - Per-task verification that will gate completion
   - External dependencies resolved (from step 3) or still pending
   - Anything explicitly NOT touching this session
   - Open assumptions or risks worth flagging
   - **Test mode** — ask the user:
     > "Test mode for this session?"
     > - **Manual** (default for attended) — I skip test runs. At each phase boundary I list the commands for you to run. If something fails, we debug together.
     > - **Autonomous** (default for away/unattended) — I run tests myself, but pipe output to file and read only the summary line. Full output only on failure.
     > - **Targeted** — I run only the specific test classes I changed, not the full suite. Full suite at final phase boundary only.

   Then ask: "Approve this session plan, or want changes?"
   Wait for explicit go. Do NOT start work on "ok, sounds reasonable", silence, or anything ambiguous — only on a clear approval (e.g., "go", "approved", "proceed", "yes").
   If the user requests changes, apply them, repost the revised summary, and ask again. Approval covers the whole session scope just confirmed — no re-gating between tasks once execution starts.

5. **Dispatch implementation** (subagent per task batch):

   **Batch related tasks together** — group up to 3-4 related tasks into a single implementer dispatch instead of one-per-task. Group by: same file touched, same feature area, or sequential dependency.

   For each batch:
   ```
   Agent(subagent_type="devflow-implementer", model="sonnet")
   ```

   Prompt must include:
   - Plan content + specific task IDs to execute
   - devflow-executing-tasks rules: never edit unrelated files, inspect existing patterns, minimal diffs, preserve architecture, TDD where practical
   - Safety gates block (no git commit/push, no destructive SQL, no secrets)
   - External source paths from step 3 (if any) so subagent can read sibling repos directly
   - Test mode instructions (see §Test execution rules below)
   - "Return: task IDs completed, files changed (paths), verification commands run + output, any blockers."

   If subagent returns **blockers** → present to user inline → get direction → re-dispatch with additional context.

   **Debug attempt cap:** If a subagent hits an error during implementation, it may attempt up to **2 autonomous fix cycles**. On the 3rd failure for the same error, it MUST stop and return a blocker with: exact error, what was tried, hypothesis for root cause. The parent presents this to the user for direction. No runaway fix-test-fix loops.

6. **Self-review + Verification** (single subagent — merged):
   ```
   Agent(subagent_type="devflow-reviewer", model="sonnet")
   ```
   Prompt: "Load devflow-code-review. Review all changes from this session (use `git diff` to identify changed files — do NOT re-read files already summarized). Then, if test mode is Autonomous or Targeted, load devflow-verification and run the verification suite per the test execution rules below. Return: review findings + recommendation, verification output (if run)."

   If test mode is **Manual**: skip verification in the subagent. List verification commands in the delivery summary for the user to run.

7. **Delivery summary** (inline): Collect outputs from steps 5-6. Format:
   - Files changed (paths only, no content echo)
   - Review findings summary
   - Verification output OR commands to run manually
   - Anything skipped
   - What's left in the plan for a future session

   Keep delivery summary under 30 lines. No full diffs, no echoing file contents.

Do not claim completion without either fresh verification output (autonomous/targeted) or explicit user confirmation that manual tests passed.

---

## Test execution rules

These rules apply to ALL test runs in devflow-execute — both in implementer subagents and in the verification step.

### Manual mode
- **Never run `mvn test` or equivalent.** Zero test commands.
- At each phase boundary, list the exact test commands the user should run.
- If user reports failure, switch to debug flow with the provided error.

### Autonomous mode
- Pipe ALL test output to a file: `mvn test > target/test-output.log 2>&1`
- Read ONLY the last 3 lines: check for `BUILD SUCCESS`/`BUILD FAILURE` and test count summary.
- On **success**: report one-line summary (e.g., "219/0/0/0 BUILD SUCCESS"). Do not read or echo the full log.
- On **failure**: read last 80 lines of log to find the failing test. Then grep for `FAILURE` or `ERROR` in the log. Read only the relevant failure block. Do not dump the entire log into context.
- For `mvn verify` (spotless/jacoco/spotbugs): same pattern. File output, tail check, deep-read only on failure.

### Targeted mode
- Run only changed test classes: `mvn test -Dtest=ChangedTest1,ChangedTest2`
- Same file-output pattern as Autonomous.
- At the **final phase boundary only**, run the full suite (autonomous pattern).

---

## Context hygiene rules

These rules prevent context bloat that triggers expensive compaction.

1. **After editing a file, do NOT re-read it to verify.** The Edit tool errors on failure — success means it worked.
2. **After committing, emit only:** `{commit SHA, files changed count, test summary}`. No full diff echo.
3. **Never paste full file contents** into conversation or subagent prompts. Use file paths + line ranges.
4. **Track "already read" files.** If a file was read earlier in the session, don't re-read unless it was modified since.
5. **Plan and spec: read once at session start.** Reference by task ID after that, don't re-read.
6. **Subagent prompts: include file paths, not file contents.** The subagent can read files itself.
7. **Prefer Edit (small diff) over Read + Write (full file)** for modifications.
