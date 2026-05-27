# devflow

Adaptive workflow plugin for Claude Code. Lean for small tasks, strict for risky ones.

## What it is

A set of slash commands, skills, agents, and templates that turn any coding request into the right depth of workflow:

- **tiny** — quick fix, no ceremony
- **standard** — short design note, checklist, step-by-step + verification
- **deep** — discovery → spec → plan → task-by-task → review → handoff
- **debug** — reproduce → root cause → minimal fix → verify

The classifier (`devflow-adaptive-routing`) picks the mode in one line. You can override by calling the specific command directly.

## How it differs from Superpowers

Superpowers-style workflows are thorough but heavy: every task tends toward full discovery + spec + plan + brainstorm even when the work is trivial. devflow keeps the same staged thinking for risky work but skips it for trivial work.

Concrete differences:
- **Adaptive routing first.** Most tasks don't get a spec file.
- **Dynamic model routing.** Each phase dispatches to the cheapest model that can handle it (see Model Routing below).
- **Subagent dispatch.** Work runs in isolated subagents — no context accumulation in the main session.
- **Token-efficient skills.** Each skill ~1 screen, not a multi-page playbook.
- **Verification is a gate, not a suggestion.** "should work" / "probably fixed" / "looks good" are explicitly forbidden — only quoted command output counts.
- **No new agents per session.** Five agents total, reusable across tasks.
- **Templates are short.** Spec readable in 2 minutes, plan is a checkbox list.
- **Stack-aware.** Built-in verify commands for Java/Spring, .NET, Flutter, Angular, Node, SQL, Docker.

## Install

Already installed in `~/.claude/`. To verify:

```
ls ~/.claude/commands | grep devflow
ls ~/.claude/skills | grep devflow
ls ~/.claude/agents | grep devflow
ls ~/.claude/devflow
```

No restart needed. Slash commands appear immediately.

### Optional session-start hint

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/devflow/hooks/session-start.sh" }
        ]
      }
    ]
  }
}
```

(Optional. Hook just prints a one-line reminder of devflow commands.)

## Commands

| Command | Use |
|---------|-----|
| `/devflow <task>` | Main entry. Auto-classifies and runs matching flow. |
| `/devflow-plan <task>` | Discovery + spec + plan only. No implementation. |
| `/devflow-execute <plan-path>` | Implement an approved plan task-by-task. |
| `/devflow-debug <bug>` | Strict debug flow. |
| `/devflow-review <scope>` | Code review only. |
| `/devflow-finish` | Final verification + handoff. |

## Mode selection (router rules)

| Mode | Triggers |
|------|----------|
| **debug** | error / bug / crash / regression / failing test / unexpected output |
| **deep** | architecture / data model / migration / auth / payments / multi-module / unclear / high regression risk / multi-day |
| **tiny** | 1–2 files AND low risk AND no design/migration/security/contract change |
| **standard** | everything else |

Ties break toward the safer mode (standard > tiny, deep > standard).

## When docs are created

| Mode | Spec | Plan | Handoff |
|------|------|------|---------|
| tiny | none | none | summary only |
| standard | inline | inline (file only if > 5 tasks) | inline summary |
| deep | `docs/devflow/specs/<slug>.md` | `docs/devflow/plans/<slug>.md` | `docs/devflow/handoffs/<slug>.md` |

## Model routing

devflow uses a **hub-and-spoke** architecture for token efficiency:

**Hub** = Main session (Opus 4.6) — lightweight orchestrator. Classifies tasks, interacts with user, dispatches work, collects results.

**Spokes** = Subagents with task-appropriate models. Start fresh (no accumulated context), use the cheapest model that can handle the phase.

### Model tiers

| Tier | Agent `model` param | Resolves to | Use for |
|------|-------------------|-------------|---------|
| Hardest | `"opus"` | Opus 4.7 | Deep specs, architecture plans |
| Complex | *(no param — inherit)* | Opus 4.6 | Deep-mode implementation, complex debug |
| Medium | `"sonnet"` | Sonnet 4.6 | Discovery, reviews, standard impl, verification |
| Trivial | `"haiku"` | Haiku 4.5 | Tiny mode tasks |

### Routing matrix

| Mode | Phase | Model | Agent |
|------|-------|-------|-------|
| tiny | all | haiku | devflow-implementer |
| standard | discovery | sonnet | devflow-planner |
| standard | implementation | sonnet | devflow-implementer |
| standard | review + verify | sonnet | devflow-reviewer |
| deep | discovery | sonnet | devflow-planner |
| deep | spec + plan | opus | devflow-planner |
| deep | implementation | inherit (4.6) | devflow-implementer |
| deep | review + verify | sonnet | devflow-reviewer |
| debug (simple) | all | sonnet | devflow-debugger |
| debug (complex) | all | inherit (4.6) | devflow-debugger |

### Escalation

- Haiku subagent returns `ESCALATE: <reason>` → re-classify as standard, re-dispatch on sonnet
- Debugger returns `ESCALATE_TO_DEEP: <reason>` → dispatch planner on opus for spec/plan
- Any subagent returns blockers → orchestrator presents to user, gets direction, re-dispatches

### Overriding

- Change the session default model in `~/.claude/settings.json` → `"model"` field
- Change routing thresholds in `~/.claude/skills/devflow-adaptive-routing/SKILL.md`
- Pass explicit `model` param when calling Agent tool to override per-dispatch

## Customizing

- **Add a stack** — append a row to the verification table in `~/.claude/skills/devflow-executing-tasks/SKILL.md` and `~/.claude/skills/devflow-verification/SKILL.md`.
- **Change router thresholds** — edit `~/.claude/skills/devflow-adaptive-routing/SKILL.md`.
- **Add a checklist item** — edit the relevant skill's checklist section.
- **New template** — drop it in `~/.claude/devflow/templates/` and reference it from a skill.
- **Per-project tweaks** — copy any skill into `<project>/.claude/skills/` to override globally.

## Anti-bloat rules (always on)

- No huge spec for small task
- No restating obvious context
- No pasting entire files unless needed
- Compact checklists over prose
- Progressive depth: light first, deeper only when risk demands

## Operator persona

devflow runs as a **senior-engineer pair programmer**: direct, careful, low-bloat, evidence-based, implementation-focused, strict on tests and verification. No ceremony. No filler. Collaborates on judgment calls; does not ask permission for steps the plan already covers.

## Stack tuning

Built-in defaults cover common backend and app stacks: Java/Spring Boot (Maven + Gradle), .NET/C#, Flutter, Angular, PostgreSQL + MSSQL, Docker, AWS (ECS). Verification, discovery, and debugging recipes inside the skills are tuned for those stacks. Routing has default modes for common task shapes — see `devflow-adaptive-routing` skill, "Common task shapes" table.

## Assumptions / unknowns

- Slash commands at `~/.claude/commands/*.md` are user-global and available in every project. Verified against existing layout.
- Agent files at `~/.claude/agents/*.md` follow the same frontmatter format as the existing `anti-patterns.md` agent.
- Skill folders at `~/.claude/skills/<name>/SKILL.md` follow the same frontmatter format as the existing `solid/SKILL.md`.
- The `SessionStart` hook syntax above is Claude Code's documented hook format; treat it as optional — if the schema changes, the rest of devflow still works.
