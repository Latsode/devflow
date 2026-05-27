---
name: devflow-discovery
description: Inspect a codebase before designing or implementing. Use before writing specs/plans for standard or deep tasks. Maps relevant files, conventions, and verification commands. Skip for tiny tasks.
---

# Discovery

Goal: ground the work in what already exists before changing anything.

## Read budget

- Standard task: ≤ 10 file reads total during discovery
- Deep task: ≤ 20 file reads during discovery
- Prefer Glob + Grep before Read. Don't Read a file you only need to confirm exists.

## Steps

1. **Repo type** — read root: `package.json`, `pom.xml`, `build.gradle*`, `*.csproj`, `*.sln`, `pubspec.yaml`, `docker-compose*.yml`, `Makefile`, `pyproject.toml`. Note frameworks/languages present.
2. **Relevant files** — Glob/Grep for symbols, routes, tables, components named in the task. List 5–15 most relevant paths max. Don't read everything.
3. **Existing patterns** — read 1–3 sibling files to learn local conventions (naming, layering, error handling, test style). Match them.
4. **Verification commands** — discover from project files:
   - npm/pnpm/yarn → `package.json` scripts (`test`, `build`, `lint`, `typecheck`)
   - Angular → `angular.json` present → `ng lint`, `ng test --watch=false`, `ng build`
   - Java → `mvn -q verify`, `mvn -q test`, or `./gradlew check build`
   - .NET → `dotnet build -nologo`, `dotnet test -nologo`
   - Flutter → `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`
   - SQL → migration tool (Flyway/Liquibase/EF Migrations/dotnet ef) OR `psql -f` / `sqlcmd -i` against dev DB
   - Docker → `docker compose config`, `docker compose build <svc>`
   - AWS / ECS → `aws ecs describe-task-definition`, `aws logs tail` (read-only first; deploys to dev only with user confirmation)
5. **Test layout** — locate test directory and one matching test file to mirror style.
6. **Constraints** — read `CLAUDE.md`, `CONTRIBUTING.md`, `README.md` if present. Note hard rules.

## Output

Compact bullet list:
- Stack: …
- Key files: …
- Conventions to follow: …
- Verification: `<command>` (where to run)
- Open questions: …

Stop. Do not start implementing from discovery skill.
