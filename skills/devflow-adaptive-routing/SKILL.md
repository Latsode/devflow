---
name: devflow-adaptive-routing
description: Classify a coding task into tiny/standard/deep/debug mode for the devflow workflow. Use when /devflow starts, when a user request needs mode selection, or when deciding workflow depth. Returns one mode label with one-sentence reason.
---

# Adaptive Routing

Pick exactly one mode. Output: `Mode: <tiny|standard|deep|debug> — <reason>`.

## Decision rules — evaluate in this exact order

### 1. debug — pick if the user describes a PROBLEM THAT ALREADY EXISTS
- quoted error / stack trace in the request
- "X is broken", "test fails", "crash", "regression", "wrong output", "doesn't work", "why is X happening"

**NOT debug** (these are feature work):
- "add error handling", "improve auth", "migrate payments", "harden security"
- Treat as standard or deep unless an actual failure is also described.

### 2. tiny — pick if scope is one sentence AND no behavior risk
Stays tiny even when the file is "sensitive":
- typos, comment edits, log/message wording
- config single-line change, format-only refactor
- SQL/JSON/YAML formatting
- adding a missing import, renaming a local variable

Tiny exception: tiny applies regardless of file location (auth.js, payment.go, etc.) as long as the change cannot alter runtime behavior.

### 3. deep — pick if ANY:
- new architecture / module / boundary
- data model / schema / migration change
- auth / security / payments / PII / billing logic *behavior*
- breaking public API contract
- multiple modules or services touched
- requirements unclear or contradictory
- high regression risk on core path
- multi-day / multi-session feature

### 4. standard — default for everything else
- multi-file but architecture clear
- behavior changes, tests required
- no architectural decision pending

## Common task shapes → default mode

| Task | Default |
|------|---------|
| SQL extraction / cleanup / formatting | tiny (standard if also restructuring the query) |
| New backend endpoint / service / repo method | standard |
| Bug, failing test, 500, crash, ECS task stopping, container exit | debug |
| Code review (no implementation) | use `/devflow-review` instead |
| Deployment / config troubleshooting (Docker, ECS, env, secrets) | debug |
| Architecture / data model / migration / payments / auth refactor | deep |

Use these defaults unless the request contradicts them.

## Conflict resolution

- debug + deep both fire (payment is broken) → start in **debug** (root-cause first), escalate to deep flow only after root cause is known
- uncertain between tiny and standard → pick **standard**
- uncertain between standard and deep → pick **deep** (safer)
- code unfamiliar to you → never tiny

## Model routing — pick model tier after mode

Once mode is chosen, assign model tier per phase using this matrix:

| Mode | Phase | Model param | Why |
|------|-------|-------------|-----|
| tiny | full pass | `sonnet` | Low-risk, single-file, no design decision |
| standard | discovery + design | `sonnet` | Read-heavy, pattern matching |
| standard | implementation | `sonnet` | Routine coding, clear requirements |
| standard | review + verify | `sonnet` | Checklist-based, read-only |
| deep | discovery | `sonnet` | Read-heavy exploration |
| deep | spec + plan | `opus` | Architecture decisions, high stakes |
| deep | per-task impl | *(inherit)* | Complex coding, Opus 4.8 from session |
| deep | review + verify | `sonnet` | Checklist review |
| debug (simple) | full flow | `sonnet` | Single file, clear error/trace |
| debug (complex) | full flow | *(inherit)* | Multi-file, concurrency, intermittent |

**Debug complexity heuristic:**
- **Simple**: single file suspect, clear error message, obvious stack trace, config typo
- **Complex**: multi-file interaction, concurrency/race, data corruption, intermittent failure, no clear trace, requires hypothesis testing

**Escalation**: If tiny-mode subagent returns `ESCALATE`, re-classify as standard (adds review + verify).

## Output format

```
Mode: <mode> — <one sentence reason naming the deciding rule>
Models: <phase1>=<model>, <phase2>=<model>, ...
```

Example outputs:
```
Mode: tiny — typo fix, no behavior change
Models: all=sonnet
```
```
Mode: standard — new endpoint, clear requirements
Models: discovery=sonnet, impl=sonnet, review=sonnet
```
```
Mode: deep — new data model with migration
Models: discovery=sonnet, spec=opus, impl=inherit, review=sonnet
```
```
Mode: debug — single-file NPE with clear stack trace
Models: all=sonnet
```

No filler. No alternatives listed. Two lines.
