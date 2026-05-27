---
name: devflow-writing-plans
description: Turn an approved spec into an ordered, verifiable task list. Use after devflow-writing-specs. Inline checklist for standard tasks; file in docs/devflow/plans/ when tasks > 5 or work spans sessions.
---

# Writing Plans

Plan = executable task list. Each task is atomic, testable, and small.

## When to create a file vs inline

- **tiny** — no plan
- **standard** ≤ 5 tasks — inline checklist
- **standard** > 5 tasks or **deep** — file at `docs/devflow/plans/<kebab-slug>.md`

## Template

Use `~/.claude/devflow/templates/plan-template.md`. Required sections:

1. **Overview** — one paragraph linking to the spec
2. **Assumptions** — what must be true for the plan to hold
3. **Tasks** — ordered, each with:
   - `[ ] Task N: <verb-led goal>`
   - files to touch (paths)
   - verification command for that task
4. **Files touched** — flat list, dedup
5. **Test commands** — full suite, lint, typecheck
6. **Rollback plan** — how to undo (revert commit, feature flag off, migration down)
7. **Completion criteria** — checklist tied to spec's acceptance criteria

## Task sizing rules

- One task = one logical change verifiable on its own
- Tasks must be ordered so that each one keeps the build green
- Split tasks that require multi-file refactors + behavior change into two
- Add a TDD task ("write failing test for X") before behavior-changing tasks where practical
- Transform each task to verifiable form before writing: `<task> → verify: <check>`. Strong criteria = agent loops independently. Weak criteria ("make it work") = user interruptions.

## Output

Compact. No prose between tasks. Use checkboxes.
