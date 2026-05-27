---
name: devflow-executing-tasks
description: Disciplined task-by-task implementation. Use during /devflow-execute or any devflow mode that's implementing changes. Enforces minimal diffs, pattern matching, TDD where applicable, and per-task verification.
---

# Executing Tasks

## Pre-flight

Before touching code:
- Run `git status` (if repo). If working tree is dirty with files unrelated to the task, list them and confirm with user before continuing. Do not assume those changes belong to you.
- If repo is not git or `git status` unavailable, note it and continue.
- State assumptions: list 3–5 assumptions about this task batch. Flag any that could be wrong — stop and ask before writing code.

## Hard rules

1. **Never edit unrelated files.** Each task touches only what its goal requires.
2. **Inspect before writing.** Read 1–3 sibling files to learn local patterns. Match them.
3. **Minimal diffs.** Smallest change that satisfies the task. No drive-by cleanups.
4. **Preserve architecture.** Don't refactor unless the plan says so.
5. **TDD where behavior changes.** Failing test first → implementation → green. Skip TDD for pure config/text changes.
6. **No claim of completion without verification output.**
7. **Orphan cleanup.** When YOUR changes make an import, variable, or function unused — remove it. Pre-existing dead code: mention but don't touch.
8. **Complexity check.** After drafting, ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify before moving on.

## Safety rules (never without explicit user request)

- `git commit`, `git push`, force-push, `git reset --hard`, `git branch -D`, `git checkout --`
- `--no-verify` or any flag that skips pre-commit / pre-push hooks
- Destructive SQL on shared DB: `DROP`, `TRUNCATE`, unscoped `DELETE`/`UPDATE` outside dev/test
- Adding files that look like secrets (`.env`, `*.pem`, `*.key`, `credentials.*`, tokens) to the diff
- Removing or downgrading dependencies, modifying CI/CD pipelines, or editing infra outside the task scope
- Long-running / network-heavy commands without warning the user first

If one of these is genuinely required, stop and ask before doing it.

## Per-task cycle

For each task in the plan:

1. **Goal** — one verifiable line: `"<what changes>" → verify: <specific check>`. Example: "Add null guard" → verify: "NullPointerTest passes".
2. **Modify files** — edits only. Surgical.
3. **Verify** — run the task's verification command (`mvn test -Dtest=…`, `npm test -- …`, `dotnet test --filter …`, `flutter test test/foo_test.dart`, etc.). Quote output.
4. **Fix** — if red, fix root cause, not symptoms. Re-run until green.
5. **Mark complete** — check the task box. Move on.

## Stack-specific verification

| Stack | Per-task verify | Full verify |
|-------|-----------------|-------------|
| Java / Spring Boot (Maven) | `mvn -pl <module> -q test -Dtest=ClassName#method` | `mvn -q verify` |
| Java / Spring Boot (Gradle) | `./gradlew :module:test --tests ClassName.method` | `./gradlew check build` |
| .NET / C# | `dotnet test --filter FullyQualifiedName~Foo --nologo` | `dotnet build -nologo && dotnet test -nologo` |
| Flutter / Dart | `flutter test test/path_test.dart` | `dart format --set-exit-if-changed . && flutter analyze && flutter test` |
| Angular / TS | `ng test --include='**/foo.spec.ts' --watch=false --browsers=ChromeHeadless` | `ng lint && ng build --configuration=production && ng test --watch=false --browsers=ChromeHeadless` |
| Node / TS | `npm test -- --testPathPattern=foo` | `npm run lint && npm test && npm run build` |
| PostgreSQL | `psql -f path/to/query.sql -v ON_ERROR_STOP=1` (or app's migrate tool) | full migration up/down round-trip on a dev DB |
| MSSQL | `sqlcmd -S <srv> -d <db> -i path/to/query.sql -b` | migration round-trip on dev DB |
| Docker | `docker compose config` (syntax) + `docker compose build <svc>` | `docker compose up --abort-on-container-exit` against a dev profile |
| AWS / ECS | `aws ecs describe-task-definition` (read-only); `aws ecs run-task --dry-run` if available | deploy to dev cluster + `aws logs tail` against the new task |

## SQL extraction / cleanup defaults

- Preserve query semantics. Diff EXPLAIN plans if available; never rewrite WHERE/JOIN logic during a "cleanup" task without explicit ask.
- Format: one column per line in SELECT lists, lowercase keywords by default unless project uses uppercase, named bind params over positional `?`.
- For extraction (inline → file): keep the SQL string identical at first commit; refactoring of the query itself goes in a separate task.

## Deployment / config troubleshooting defaults

- Treat as **debug** mode. Reproduce locally if practical (`docker compose up` with the same env). Quote exit codes, log lines, env var diffs verbatim.
- Compare a known-good environment to the failing one: image tag, env vars, IAM role, security group, task def revision.
- Change one variable at a time. Re-run after each.
- Never modify CI/CD pipelines, IAM, or infra outside the task's stated scope without confirming with the user first.

## Anti-bloat

- Don't restate plan content in implementation
- Don't paste whole files — show only the changed hunk if narrating
- Don't write summary paragraphs between tasks; one line is enough
- If a task balloons, stop and split it
