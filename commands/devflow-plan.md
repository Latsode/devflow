---
description: Discovery + spec + plan only. No implementation. Use when you want a design doc and task breakdown before coding.
argument-hint: <task description>
---

# /devflow-plan

Plan only. Stop after plan. Do not implement.

**Task:** $ARGUMENTS

## Flow

1. **Discovery** (subagent):
   ```
   Agent(subagent_type="devflow-planner", model="sonnet")
   ```
   Prompt: "Load devflow-discovery. Inspect relevant files for task: <$ARGUMENTS>. Return: stack, key files, conventions, verification commands, assumptions, open questions."

2. **Clarify** (inline): If discovery subagent surfaced blocking unknowns, ask up to 3 clarifying questions. Otherwise skip.

3. **Spec + Plan** (subagent):
   ```
   Agent(subagent_type="devflow-planner", model="opus")
   ```
   Prompt: Include discovery output from step 1 + any clarification answers from step 2. "Load devflow-writing-specs. Write spec using template to `docs/devflow/specs/<slug>.md` (or inline for mid-size). Load devflow-writing-plans. Write plan using template to `docs/devflow/plans/<slug>.md` (or inline checklist if tasks ≤ 5). Return: spec path/content, plan path/content, top 3 risks, task count."

4. **Present** (inline): Output spec location, plan location, risks, next command (`/devflow-execute`).

Do NOT modify production code. Spec/plan files only.
