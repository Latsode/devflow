---
name: devflow-writing-specs
description: Write a focused design spec for non-trivial work. Use after discovery for standard tasks (inline spec) and deep tasks (file in docs/devflow/specs/). Skip for tiny tasks. Output uses the spec template structure.
---

# Writing Specs

Spec = design contract. Short, decisive, no fluff.

## When to create a file vs inline

- **tiny** — no spec
- **standard** — inline spec (≤ 20 lines)
- **deep** — file at `docs/devflow/specs/<kebab-slug>.md`

## Template

Use `~/.claude/devflow/templates/spec-template.md`. Required sections:

1. **Goal** — what success looks like, one paragraph
2. **Non-goals** — explicitly out of scope
3. **Context** — current state, why now
4. **Constraints** — performance, compat, security, deadlines
5. **Proposed approach** — the chosen design, not a survey
6. **Alternatives considered** — 1–3 lines each on rejected options + why
7. **Risks** — what could go wrong, mitigations
8. **Test strategy** — unit / integration / e2e / manual, what each covers
9. **Acceptance criteria** — verifiable bullet list

## Rules

- No restating obvious context
- No paragraph where a bullet works
- Cite real file paths, not invented ones
- If a section is genuinely empty for this task, write "n/a — <one-line reason>" instead of padding
- Spec must be readable in under 2 minutes
