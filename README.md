# devflow

> Adaptive Claude Code workflow plugin. Lean for tiny work, strict for risky work, and routes every phase to the cheapest model that can handle it.

devflow turns any coding request into the right depth of workflow. The classifier picks a mode (`tiny` / `standard` / `deep` / `debug`), then dispatches each phase to a subagent on a task-appropriate model (Sonnet or Opus). The main session stays a lightweight orchestrator — no accumulated context, no token bloat.

---

## Table of contents

- [Why devflow](#why-devflow)
- [Quick start](#quick-start)
- [Installation](#installation)
  - [Windows (PowerShell)](#windows-powershell)
  - [macOS / Linux / WSL](#macos--linux--wsl)
  - [Manual install](#manual-install)
  - [Project-local install](#project-local-install)
  - [Verifying the install](#verifying-the-install)
  - [Uninstall](#uninstall)
- [Commands](#commands)
- [Modes — what each one does](#modes--what-each-one-does)
- [Architecture (hub & spoke)](#architecture-hub--spoke)
- [Model routing matrix](#model-routing-matrix)
- [Skills reference](#skills-reference)
- [Agents reference](#agents-reference)
- [Templates](#templates)
- [Document layout in your project](#document-layout-in-your-project)
- [Customization recipes](#customization-recipes)
- [Worked examples](#worked-examples)
- [Operating principles](#operating-principles)
- [Stack tuning](#stack-tuning)
- [Repository layout](#repository-layout)
- [Compatibility & requirements](#compatibility--requirements)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Why devflow

Most "AI workflow" frameworks treat every task the same — discovery, spec, plan, brainstorm, implementation, review — even for a one-line typo fix. That burns tokens, breaks flow, and trains the user to skip the whole pipeline when speed matters.

devflow keeps the same disciplined staging for risky work, but **opts out of ceremony when the change has no behavior risk**. Concrete differences from heavier workflow plugins:

| Concern | devflow approach |
|---|---|
| Mode selection | One-line classifier picks `tiny`/`standard`/`deep`/`debug` first. Most tasks skip spec/plan files entirely. |
| Model cost | Each phase dispatches to the cheapest capable model — Sonnet for tiny + routine work, Opus only where architecture decisions live. |
| Context | Subagents run in isolation — the orchestrator never accumulates implementation noise. |
| Skills size | Each skill is ~1 screen, not a multi-page playbook. Loaded only when relevant. |
| Verification | A **gate**, not a suggestion. "should work" / "probably fixed" / "looks good" are explicitly forbidden — quoted command output is the only proof. |
| Agent count | Five total. Reused across tasks. No new agents per session. |
| Templates | Spec readable in 2 min. Plan is a checkbox list. Handoff is a paragraph plus quoted verification. |
| Stack awareness | Built-in verify recipes for Java/Spring (Maven + Gradle), .NET, Flutter, Angular, Node/TS, SQL (PG + MSSQL), Docker, AWS/ECS. |

---

## Quick start

```bash
# 1. clone or copy this directory anywhere
# 2. install user-globally (default)
./install.sh          # macOS / Linux / WSL
.\install.ps1         # Windows PowerShell

# 3. open Claude Code in any project and try:
/devflow add a /healthz endpoint that returns 200
```

That's it. Slash commands appear immediately — no restart required.

---

## Installation

> **Default behavior:** the installer forcibly overwrites every devflow-owned
> file in the target (`commands/devflow*.md`, `agents/devflow-*.md`,
> `skills/devflow-*`, and the `devflow/` config tree). Non-devflow files —
> your other commands, agents, skills, hooks, settings — are never read or
> modified. This makes updates a one-liner and keeps the rest of your
> Claude Code setup intact.
>
> If you've hand-edited a devflow file locally and want to preserve it, pass
> `--no-force` (bash) or `-NoForce` (PowerShell) and the installer will skip
> existing files.

### Windows (PowerShell)

```powershell
# user-global install (default — appears in every project, overwrites devflow files)
.\install.ps1

# keep any local edits to devflow files
.\install.ps1 -NoForce

# also wire the SessionStart hint hook (prints command cheatsheet on startup)
.\install.ps1 -InstallHook

# project-local install (current directory only)
.\install.ps1 -Scope project
```

If PowerShell blocks the script due to execution policy, run it once with a bypass:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### macOS / Linux / WSL

```bash
chmod +x install.sh
./install.sh                          # user-global (~/.claude), overwrite devflow files
./install.sh --no-force               # keep local edits to devflow files
./install.sh --install-hook           # add the SessionStart hint
./install.sh --scope project          # install into ./.claude
```

`--install-hook` uses `jq` if available; otherwise it prints the JSON snippet for you to paste into `settings.json` manually.

### Manual install

If you'd rather not run a script, copy the trees by hand:

```text
this-repo/commands/*.md         ->  ~/.claude/commands/
this-repo/agents/*.md           ->  ~/.claude/agents/
this-repo/skills/devflow-*      ->  ~/.claude/skills/
this-repo/hooks/*.sh            ->  ~/.claude/devflow/hooks/
this-repo/templates/*.md        ->  ~/.claude/devflow/templates/
this-repo/docs/*.md             ->  ~/.claude/devflow/docs/
```

For project-local install, replace `~/.claude` with `<project>/.claude`.

### Project-local install

Project-local files take precedence over user-global ones. Use this when:

- Your team wants a checked-in workflow standard.
- You want to customize devflow for one project without affecting others.
- You're trialing a change before promoting it user-global.

Commit `.claude/commands/`, `.claude/agents/`, `.claude/skills/devflow-*`, and `.claude/devflow/` to your repo. Other contributors get the same workflow without running an installer.

### Verifying the install

```bash
ls ~/.claude/commands | grep devflow      # 6 files
ls ~/.claude/agents   | grep devflow      # 5 files
ls ~/.claude/skills   | grep devflow      # 9 dirs
ls ~/.claude/devflow                       # docs/ hooks/ templates/
```

PowerShell equivalent:

```powershell
Get-ChildItem ~/.claude/commands -Filter "devflow*"
Get-ChildItem ~/.claude/agents   -Filter "devflow*"
Get-ChildItem ~/.claude/skills   -Filter "devflow-*" -Directory
Get-ChildItem ~/.claude/devflow
```

Open Claude Code. Type `/` — you should see `/devflow`, `/devflow-plan`, `/devflow-execute`, `/devflow-debug`, `/devflow-review`, `/devflow-finish`.

### Uninstall

```bash
./uninstall.sh user          # or 'project'
```

```powershell
.\uninstall.ps1
.\uninstall.ps1 -Scope project
```

The uninstaller removes all six commands, five agents, the nine `devflow-*` skill folders, and the `devflow/` config tree. The optional SessionStart hook is **not** auto-removed — open `settings.json` and delete the `SessionStart` block by hand if you want.

---

## Commands

| Command | Purpose |
|---|---|
| `/devflow <task>` | Main entry. Auto-classifies into tiny/standard/deep/debug and runs the matching flow end-to-end. |
| `/devflow-plan <task>` | Discovery + spec + plan only. No implementation. Use when you want a design doc and task breakdown before coding. |
| `/devflow-execute <plan-path>` | Implement an approved plan task-by-task with per-task verification. Run after `/devflow-plan`. |
| `/devflow-debug <bug>` | Strict 8-step debugging: reproduce → evidence → hypothesis → minimal fix → verify. |
| `/devflow-review <scope>` | Read-only code review on a diff, branch, or named files. Returns approve / approve-with-fixes / request-changes. |
| `/devflow-finish` | Final verification + delivery summary. Run when implementation is done and you want a clean handoff. |

You can always override the auto-classifier by calling the specific command directly — `/devflow-plan` forces deep planning even for a request the router might've called standard.

---

## Modes — what each one does

| Mode | When the router picks it | What happens |
|---|---|---|
| **tiny** | One-sentence change, no behavior risk. Typos, log copy, format-only edits, single-line config, SQL formatting, adding a missing import — even in sensitive files, as long as runtime behavior can't change. | Single Sonnet implementer subagent. Read → edit → minimum verify (test for changed file OR lint OR typecheck OR build) → one-line summary. No spec, no plan, no review pass. |
| **standard** | Multi-file but architecture clear. Behavior changes. Tests required. No architectural decision pending. | Three phases: Sonnet planner → Sonnet implementer → Sonnet reviewer-with-verify. Inline design note (≤20 lines), inline task checklist, full test + lint + typecheck at the end. Plan saved to file only if >5 tasks. |
| **deep** | Touches architecture, data model, schema migration, auth/security/payments/PII, public API contract, multiple modules, unclear requirements, or multi-day work. | Sonnet discovery → **Opus** spec + plan → presented to user → user runs `/devflow-execute` separately → Sonnet implementer (one batch per task group) → Sonnet review + verify → handoff file. |
| **debug** | User describes a problem that already exists: quoted error, stack trace, "X is broken", "test failing", "crash", "wrong output". | Strict 8-step systematic debugging on Sonnet (simple) or inherit-Opus (complex). No fix before evidence. Max 2 autonomous attempts per error before stopping for user direction. |

### Conflict resolution

- `debug + deep` both fire (payment is broken) → start **debug** (root-cause first); escalate to deep flow only once root cause is known.
- Uncertain between `tiny` and `standard` → pick **standard**.
- Uncertain between `standard` and `deep` → pick **deep** (safer).
- Code unfamiliar to you → never `tiny`.

### When docs are written

| Mode | Spec | Plan | Handoff |
|---|---|---|---|
| tiny | none | none | chat summary only |
| standard | inline | inline checklist | inline summary |
| deep | `docs/devflow/specs/<slug>.md` | `docs/devflow/plans/<slug>.md` | `docs/devflow/handoffs/<slug>.md` |

---

## Architecture (hub & spoke)

devflow uses a **hub-and-spoke** topology to keep the orchestrator small and let each phase run on the cheapest capable model.

```
                ┌─────────────────────────────────────┐
                │   Main session  —  Opus 4.8         │
                │   • classifies task                 │
                │   • talks to user                   │
                │   • dispatches subagents            │
                │   • collects + presents results     │
                └──────────────────┬──────────────────┘
                                   │
       ┌───────────┬───────────────┼───────────────┬───────────┐
       ▼           ▼               ▼               ▼           ▼
 ┌──────────┐ ┌──────────┐  ┌──────────────┐ ┌──────────┐ ┌──────────┐
 │ planner  │ │implementer│ │   debugger   │ │ reviewer │ │  tester  │
 │ (sonnet/ │ │ (sonnet)  │  │ (sonnet/    │ │ (sonnet) │ │ (sonnet) │
 │  opus)   │ │           │  │  inherit)   │ │          │ │          │
 └──────────┘ └──────────┘  └──────────────┘ └──────────┘ └──────────┘
```

- **Hub** — main session. Stays lightweight. Never reads source files during implementation; the subagents do that.
- **Spokes** — five subagents. Each one starts fresh with zero accumulated context, loads only the skill it needs, and returns a structured summary.

Why this matters: a single 200-line `git diff` echoed back into the orchestrator after implementation kills your context budget. The implementer subagent reports `files changed (paths only)` + a one-line verification summary, and the orchestrator never has to ingest the diff.

---

## Model routing matrix

| Mode | Phase | Model param | Resolves to | Why |
|---|---|---|---|---|
| tiny | full pass | `sonnet` | Sonnet 4.6 | Low-risk, single-file, no design decision. |
| standard | discovery + design | `sonnet` | Sonnet 4.6 | Read-heavy, pattern matching. |
| standard | implementation | `sonnet` | Sonnet 4.6 | Routine coding, clear requirements. |
| standard | review + verify | `sonnet` | Sonnet 4.6 | Checklist-based, read-only. |
| deep | discovery | `sonnet` | Sonnet 4.6 | Read-heavy exploration. |
| deep | spec + plan | `opus` | Opus 4.8 | Architecture decisions, high stakes. |
| deep | per-task impl | *(inherit)* | Opus 4.8 (session default) | Complex coding paths. |
| deep | review + verify | `sonnet` | Sonnet 4.6 | Checklist review. |
| debug — simple | full flow | `sonnet` | Sonnet 4.6 | Single-file, clear trace. |
| debug — complex | full flow | *(inherit)* | Opus 4.8 (session default) | Multi-file, concurrency, intermittent. |

### Escalation

- Tiny-mode subagent returns `ESCALATE: <reason>` → re-classify as standard, adding review + verify phases.
- Debugger returns `ESCALATE_TO_DEEP: <reason>` → dispatch planner on Opus for spec/plan.
- Any subagent returns blockers → orchestrator presents to user, gets direction, re-dispatches with added context.

### Overriding

- **Session default model** — change `"model"` in `~/.claude/settings.json`.
- **Routing thresholds** — edit the decision tables in `~/.claude/skills/devflow-adaptive-routing/SKILL.md`.
- **Per-dispatch override** — explicit `model="..."` param in any `Agent(...)` call inside a command file.

---

## Skills reference

Skills are short, focused instruction files Claude loads on demand. Each skill is ~1 screen — readable in under a minute.

| Skill | Loaded by | Purpose |
|---|---|---|
| `devflow-adaptive-routing` | `/devflow`, edge-case classification | Decision rules for picking `tiny`/`standard`/`deep`/`debug`. Maps mode → per-phase model tier. |
| `devflow-discovery` | `devflow-planner` agent | Inspect a repo before designing. Bounded read budget. Outputs stack, key files, conventions, verification commands. |
| `devflow-writing-specs` | `devflow-planner` agent | Write a short, decisive design contract using the spec template. |
| `devflow-writing-plans` | `devflow-planner` agent | Convert a spec into an ordered, verifiable task list. Each task atomic and testable. |
| `devflow-executing-tasks` | `devflow-implementer` agent | Surgical edits, minimal diffs, TDD where applicable, per-task verification. Includes hard safety rules (no force-push, no destructive SQL, no secrets in diff). |
| `devflow-systematic-debugging` | `devflow-debugger` agent | Strict 8-step method. No fix before evidence. No random changes. One variable at a time. |
| `devflow-code-review` | `devflow-reviewer` agent | Structured checklist: requirement match, correctness, edge cases, security, performance, tests, readability, complexity, hygiene. |
| `devflow-verification` | `devflow-reviewer` agent, `/devflow-finish` | Discover real verification commands from the repo. Gate completion language on quoted output. |
| `devflow-finishing` | `/devflow-finish`, end of any mode | Pre-finish checklist + delivery summary structure. Forbids running git commits or opening PRs without explicit user request. |

---

## Agents reference

Five subagents — total. They're reusable across every task; devflow never creates one-off agents per session.

| Agent | Tools | Used for | Stops itself when |
|---|---|---|---|
| `devflow-planner` | Read, Glob, Grep, Bash, Write, WebFetch | Discovery + spec + plan. Never implements. | Spec + plan written. |
| `devflow-implementer` | Read, Edit, Write, Glob, Grep, Bash | Executes one task or a tight batch from a plan. Refuses scope creep. | Tasks done or scope creep detected. |
| `devflow-debugger` | Read, Edit, Glob, Grep, Bash | Reproduce → root-cause → minimal fix → verify. Max 2 autonomous attempts per error. | Root cause + green verification OR 3rd-attempt blocker. |
| `devflow-reviewer` | Read, Glob, Grep, Bash | Read-only review on a diff/branch/files. Returns approve / approve-with-fixes / request-changes. | Review complete. |
| `devflow-tester` | Read, Edit, Write, Glob, Grep, Bash | Adds or improves test coverage for a specific change. Never modifies production code without approval. | Tests added and green. |

Each agent enforces the same hard safety block: no `git commit/push/reset --hard/branch -D/force-push`, no `--no-verify`, no destructive SQL outside dev/test, no committing files that look like secrets.

---

## Templates

Four short Markdown templates used by the agents — kept short on purpose. Each lives in `~/.claude/devflow/templates/` after install.

| Template | When it's used | Output size goal |
|---|---|---|
| `spec-template.md` | Deep tasks — written by planner to `docs/devflow/specs/<slug>.md`. Standard tasks — inline only. | Readable in 2 min. |
| `plan-template.md` | Deep tasks (always) or standard tasks with >5 steps. Written to `docs/devflow/plans/<slug>.md`. | Compact checklist. |
| `review-template.md` | Optional structured format for `/devflow-review`. | Findings table. |
| `handoff-template.md` | Deep tasks at finish — written to `docs/devflow/handoffs/<slug>.md`. | Summary + verification + next-step draft. |

Customize them in place. They're plain Markdown — no DSL.

---

## Document layout in your project

After running devflow against a project, you'll see:

```
your-project/
├── src/
├── tests/
└── docs/
    └── devflow/
        ├── specs/        # deep-mode design contracts
        ├── plans/        # deep-mode task lists
        └── handoffs/     # deep-mode delivery summaries
```

Tiny and standard tasks produce no files — only chat output. The `docs/devflow/` tree only appears when you run deep work. Commit it if you want the design trail in git, or add it to `.gitignore` if you'd rather keep it local.

---

## Customization recipes

### Add a new stack

Append a row to both verification tables:

- `~/.claude/skills/devflow-executing-tasks/SKILL.md` — `Stack-specific verification` table.
- `~/.claude/skills/devflow-verification/SKILL.md` — `Command discovery` table.

Example for Rust:

```markdown
| Rust / Cargo | `cargo test --lib <name>::<test>` | `cargo fmt --check && cargo clippy -- -D warnings && cargo test` |
```

### Change router thresholds

Edit `~/.claude/skills/devflow-adaptive-routing/SKILL.md`. The decision-rule list is evaluated in order — move conditions earlier or later, or add new ones for your team's risk profile.

### Add a checklist item to code review

Edit `~/.claude/skills/devflow-code-review/SKILL.md`. Add a section. Each subagent loads the skill fresh, so the change applies immediately.

### Add a new template

1. Drop the file in `~/.claude/devflow/templates/`.
2. Reference it from the relevant skill (`devflow-writing-specs`, `devflow-writing-plans`, etc.) or from a command file (`~/.claude/commands/devflow*.md`).

### Per-project override

Copy any skill into `<project>/.claude/skills/`. Project-local skills override user-global ones — useful for setting per-repo conventions without touching your global config.

### Persona tuning

The `/devflow` command file at `~/.claude/commands/devflow.md` opens with the operator persona block. Edit that paragraph to change how devflow communicates in your sessions (more pedagogical, more terse, language preferences, etc.).

---

## Worked examples

### 1. Tiny — SQL formatting

```
> /devflow reformat the user-search query in OrderRepository.java to use multiline + named params
```

Expected output:

```
Mode: tiny — one file, formatting only, no behavior change.
Models: all=sonnet

Read OrderRepository.java:42-58. Rewrite query block. Run:
$ mvn -q -pl repo test -Dtest=OrderRepositoryTest
Tests run: 7, Failures: 0, Errors: 0

Done. Changed OrderRepository.java only.
```

No spec. No plan. One verification.

### 2. Standard — new API endpoint

```
> /devflow add GET /api/v1/customers/{id}/orders returning paged list, default size 20, max 100
```

```
Mode: standard — multi-file (controller + service + repo + test), behavior change.
Models: discovery=sonnet, impl=sonnet, review=sonnet

Discovery: Spring Boot 3, JPA, paging via Pageable, existing pattern in ProductController.

Design (inline):
- New endpoint in CustomerController
- Reuse CustomerService.findOrders(id, Pageable)
- Add JPA query in OrderRepository.findByCustomerId(id, Pageable)
- Validation: size 1..100, page >= 0

Checklist:
[ ] T1 repo method + test
[ ] T2 service method + test
[ ] T3 controller + integration test
[ ] T4 full mvn verify

Implementing T1...
$ mvn -q test -Dtest=OrderRepositoryTest
Tests run: 9, Failures: 0
✓

(...T2, T3 similar...)

Final:
$ mvn -q verify
BUILD SUCCESS · 142 tests, 0 failed

Files: OrderRepository.java, CustomerService.java, CustomerController.java + 3 tests.
Next: commit feat(orders): list customer orders endpoint
```

### 3. Debug — failing test

```
> /devflow-debug PaymentServiceTest.refundExpired failing on CI but passes locally
```

```
Loading devflow-systematic-debugging.

Reproduce:
$ mvn -q test -Dtest=PaymentServiceTest#refundExpired
Tests run: 1, Failures: 1
  expected: 2026-05-15T00:00:00Z but was: 2026-05-14T19:00:00Z

Evidence: assertion uses LocalDateTime.now() + ZoneId.systemDefault().
CI runs in UTC, dev in Asia/Tbilisi (UTC+4). Diff = 4h, but failure offset 5h → DST adjacent.

Hypothesis: comparison mixes LocalDateTime and Instant, drops zone info.
Falsifier: PaymentService.refund() returns LocalDateTime — grep confirms.

Failing test (already exists). Minimal fix:
- PaymentService.java:88 — change return type to Instant, callers updated
- PaymentServiceTest.java:34 — assert with Instant comparison

Verify:
$ TZ=UTC mvn -q test -Dtest=PaymentServiceTest
Tests run: 6, Failures: 0
$ TZ=Asia/Tbilisi mvn -q test -Dtest=PaymentServiceTest
Tests run: 6, Failures: 0

Root cause: zone-naive datetime compared across zones. Fixed by using Instant.
```

### 4. Deep — payments refactor

```
> /devflow-plan migrate refund flow from Stripe v1 to v2 API with backward-compat for in-flight requests
```

```
Mode: deep — payments + external API + migration.

Loading devflow-discovery.
[discovery output: services, files, current StripeClient, ~14 callsites]

Spec saved: docs/devflow/specs/stripe-v2-refunds.md
Plan saved: docs/devflow/plans/stripe-v2-refunds.md (11 tasks)

Top risks:
- in-flight refunds during deploy → use idempotency keys consistent across versions
- v2 webhook signature change → dual-verify until cutover
- partial refunds field rename → translation layer

Next: /devflow-execute docs/devflow/plans/stripe-v2-refunds.md
```

Then:

```
> /devflow-execute docs/devflow/plans/stripe-v2-refunds.md
```

Runs T1..T11 task by task, verifying each. Stops on red. Posts a session gate first to confirm scope and test mode (Manual / Autonomous / Targeted).

### 5. Review only

```
> /devflow-review feature/customer-orders
```

```
Scope: git diff main...feature/customer-orders (4 files, +127/-12)

Requirement match: meets ticket WMS-844.

Findings:
- src/.../CustomerController.java:54 (major) — page size cap of 100 not enforced; returns 500 on size=10000. Fix: clamp via PageRequest.of(page, Math.min(size, MAX_SIZE)).
- src/.../OrderRepository.java:31 (minor) — query missing index hint; verify orders(customer_id, created_at) index exists.
- src/.../CustomerControllerTest.java (minor) — no test for empty result.

Security: ok (auth via existing filter). PII: response body fine.

Recommendation: **approve-with-fixes** — fix the size cap before merge.
```

More examples in `docs/EXAMPLES.md`.

---

## Operating principles

These are non-negotiable rules baked into every command and agent:

- **Verification is a gate.** No "should work" / "probably fixed" / "looks good" — only quoted command output proves a task is done.
- **No fix before evidence.** Debug mode forbids guess-and-check; every fix has a stated hypothesis backed by reproduction.
- **Minimal diffs.** Each task touches only what its goal requires. No drive-by cleanups. No surrounding refactors.
- **Hard safety rules.** No `git commit/push/reset --hard/branch -D/force-push` without explicit user request. No `--no-verify`. No destructive SQL on shared DBs. No committing secrets.
- **No bloat.** No huge spec for small task. No restating obvious context. No pasting entire files. Progressive depth — light first, deeper only when risk demands.
- **Subagent isolation.** Every implementation phase runs in a fresh subagent. The orchestrator never accumulates code-reading context.

---

## Stack tuning

Built-in verification recipes match these stacks out of the box:

- **Java / Spring Boot** — Maven + Gradle, JUnit 5
- **.NET / C#** — `dotnet build`, `dotnet test`
- **Flutter / Dart** — `flutter test`, `flutter analyze`, `dart format`
- **Angular / TypeScript** — `ng lint`, `ng test`, `ng build`
- **Node / TypeScript** — `npm run lint/test/build`
- **PostgreSQL** — `psql -f ... -v ON_ERROR_STOP=1`
- **MSSQL** — `sqlcmd -i ... -b`
- **Docker** — `docker compose config`, `docker compose build`
- **AWS / ECS** — `aws ecs describe-task-definition`, `aws logs tail`

For other stacks, follow the recipe in [Customization → Add a new stack](#add-a-new-stack).

---

## Repository layout

```
devflow/
├── README.md                  # this file
├── LICENSE                    # MIT
├── CHANGELOG.md
├── plugin.json                # machine-readable manifest
├── install.ps1                # Windows installer
├── install.sh                 # macOS / Linux / WSL installer
├── uninstall.ps1
├── uninstall.sh
├── .gitignore
│
├── commands/                  # slash command definitions
│   ├── devflow.md
│   ├── devflow-plan.md
│   ├── devflow-execute.md
│   ├── devflow-debug.md
│   ├── devflow-review.md
│   └── devflow-finish.md
│
├── agents/                    # subagent definitions
│   ├── devflow-planner.md
│   ├── devflow-implementer.md
│   ├── devflow-debugger.md
│   ├── devflow-reviewer.md
│   └── devflow-tester.md
│
├── skills/                    # on-demand instruction modules
│   ├── devflow-adaptive-routing/SKILL.md
│   ├── devflow-discovery/SKILL.md
│   ├── devflow-writing-specs/SKILL.md
│   ├── devflow-writing-plans/SKILL.md
│   ├── devflow-executing-tasks/SKILL.md
│   ├── devflow-systematic-debugging/SKILL.md
│   ├── devflow-code-review/SKILL.md
│   ├── devflow-verification/SKILL.md
│   └── devflow-finishing/SKILL.md
│
├── hooks/
│   └── session-start.sh       # optional hint hook
│
├── templates/
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── review-template.md
│   └── handoff-template.md
│
└── docs/
    ├── DEVFLOW.md             # original design notes
    └── EXAMPLES.md            # extended worked examples
```

After install, these are split across two trees in your Claude Code config:

```
~/.claude/
├── commands/devflow*.md
├── agents/devflow-*.md
├── skills/devflow-*/SKILL.md
└── devflow/
    ├── docs/
    ├── hooks/
    └── templates/
```

---

## Compatibility & requirements

- **Claude Code** — v1.0.0 or newer (any version that supports custom slash commands, subagents under `~/.claude/agents/`, and skills under `~/.claude/skills/`).
- **Operating systems** — Windows, macOS, Linux, WSL. The optional SessionStart hook is native per installer: `install.ps1 -InstallHook` wires `session-start.ps1` (PowerShell, no bash needed); the `.sh` installer wires `session-start.sh` (bash).
- **Shell** — bash for the `.sh` installer; PowerShell 5.1+ for `install.ps1`. No external dependencies required for the basic install; `jq` is optional for the bash installer's `--install-hook` mode.
- **Models** — works with whatever models your Claude Code config is wired for. The matrix above assumes Sonnet 4.6 and Opus 4.8 are available; if some are missing, devflow still works — those phases just run on the next-best model the session has access to.

---

## Troubleshooting

**Slash commands don't appear.** Check that the files landed in `~/.claude/commands/` (not `~/.claude/commands/devflow/`). devflow uses flat command files. Re-run `install.ps1 -Force` or `install.sh --force`.

**Subagents fail with "agent not found".** Confirm `~/.claude/agents/devflow-*.md` exist. The agent name in the frontmatter (`name: devflow-planner`) must match the filename without `.md`.

**Skill load fails.** Confirm each skill directory contains a file named exactly `SKILL.md` (uppercase). Some filesystems are case-sensitive; the installer normalizes casing, but a manual copy might not.

**Hook doesn't print on startup.** Open `~/.claude/settings.json` and verify the `SessionStart` entry exists and points to a valid path. On Windows you'll need `bash` available (Git Bash or WSL); otherwise drop the hook — it's optional.

**Subagent says `ESCALATE: ...` and stops.** That's the design. The orchestrator should automatically re-dispatch on a stronger model. If it doesn't, re-run with the explicit command (`/devflow-plan` instead of `/devflow`) to force the deep flow.

**`/devflow-execute` waits forever at the session gate.** It's waiting for explicit approval ("go", "approved", "proceed", "yes"). Ambiguous responses don't unblock it on purpose.

**Tests in deep mode run the full suite repeatedly.** Switch the session test mode to **Targeted** at the gate — devflow will only run the test classes you modified until the final phase.

**The implementer keeps re-trying the same fix.** Each subagent has a 2-attempt cap per error. On the 3rd failure it must return a blocker. If you're seeing more than 2 attempts, your agent or skill files are stale — re-run the installer with `--force` to refresh.

---

## Contributing

devflow is small on purpose. Before adding a feature, check whether the goal is achievable by editing a skill — most behavior changes belong there, not in a new command or agent.

1. Fork and clone.
2. Make changes in this repo's `commands/`, `agents/`, `skills/`, `templates/`, or `hooks/`.
3. Run `./install.sh --force` (or `install.ps1 -Force`) to push them into `~/.claude/` and try them out in a real Claude Code session.
4. Verify changes against the worked examples in `docs/EXAMPLES.md`.
5. Open a PR describing the change and the use case that motivated it.

Style guidelines:

- Skills stay ~1 screen. If a skill is growing, split it.
- Templates stay short — readable in 2 min for specs, checklist-only for plans.
- No new top-level commands without a clear reason (the existing six cover the lifecycle).
- No new agents without a clear reason (five is the target).

---

## License

MIT — see [LICENSE](LICENSE).
