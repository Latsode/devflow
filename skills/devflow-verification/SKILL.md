---
name: devflow-verification
description: Evidence-based completion verification. Use before claiming any task done. Discovers project verification commands, runs them, and gates completion language on real output.
---

# Verification

## Completion language gate

Allowed:
- "Ran `<cmd>` — N tests passed, 0 failed."
- "Ran `<cmd>` — build succeeded."
- "Could not run `<cmd>` because <reason>. Manual steps: …"

Forbidden:
- "should work"
- "probably fixed"
- "looks good"
- "tests would pass"
- "tested locally" (without quoting actual output)

## Command discovery

Look at project root, in order:

| File present | Try |
|--------------|-----|
| `package.json` | `npm test`, `npm run build`, `npm run lint`, `npm run typecheck` (only those defined in `scripts`) |
| `angular.json` | `ng lint`, `ng test --watch=false --browsers=ChromeHeadless`, `ng build --configuration=production` |
| `pom.xml` | `mvn -q verify` or `mvn -q test`; `mvn -q compile` for build-only |
| `build.gradle*` | `./gradlew check build` (or `gradlew.bat` on Windows) |
| `*.csproj` / `*.sln` | `dotnet build -nologo`, `dotnet test -nologo` |
| `pubspec.yaml` | `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` |
| `*.sql` only | `psql -f file.sql -v ON_ERROR_STOP=1` (PG) or `sqlcmd -i file.sql -b` (MSSQL) against dev DB |
| `pyproject.toml` / `setup.py` | `pytest`, `ruff check`, `mypy` (only if configured) |
| `Makefile` | `make test`, `make build`, `make lint` (only existing targets) |
| `docker-compose*.yml` | `docker compose config`; `docker compose build <svc>` for build-level check |
| `task-definition.json` / ECS files | `aws ecs register-task-definition --cli-input-json file://... --generate-cli-skeleton` for syntax; deploy to dev cluster for real check |

Never invent a command. If unsure, list the candidates and let the user pick.

## Scope

- After tiny task → single test for the changed file IF a matching test exists; otherwise run lint OR typecheck OR build for that file. Verification is never skipped entirely. If absolutely nothing can run (e.g. text file with no tooling), say so explicitly and quote what you checked manually.
- After standard task → full test + lint + typecheck
- After deep task → above + build + any integration/e2e suite

## When verification can't run

State explicitly:
1. Why it can't (no Docker, no DB access, missing creds, slow)
2. What you did instead (static check, dry-run, manual reasoning)
3. Exact manual steps the user should run, with expected output

Never claim done in this case. Mark as "implementation complete — verification pending".
