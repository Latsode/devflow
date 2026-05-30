---
name: devflow-systematic-debugging
description: Evidence-based debugging method. Use for any bug, failing test, regression, crash, perf issue, or unexpected output. Forbids fixes before reproduction and root-cause identification.
---

# Systematic Debugging

## Hard rules

- **No fix before evidence.**
- **No random changes.** No "try this and see".
- **One variable at a time** unless you can justify multi-variable.
- **Fix root cause, not symptom.**
- **Verify with the original failing scenario.**

## Method

### 1. Reproduce or observe
- Run the failing command/test/scenario yourself
- Quote the exact error/output
- If you can't reproduce, gather the user's exact steps, env, version, data
- Cheapest reproduction first (unit > integration > full stack)

### 2. Gather evidence
- Full stack trace
- Recent commits touching the affected files (`git log -p -- <path>`)
- Relevant logs at the failure point
- The smallest input that triggers it
- If a graphify graph is available (`graphify` CLI + `graphify-out/graph.json`):
  `graphify affected "<symbol>"` to find impacted nodes and
  `graphify path "<failing-symbol>" "<suspect>"` to trace the call chain without
  reading every file. Results are **unverified hints** — confirm each hop in
  source before trusting it. Fall back to `git log`/Grep on empty/ambiguous/error
  results. Never read `graph.json` raw. Skip silently if graphify is absent.

### 3. Compare working vs broken
- Most recent commit/branch/env where it works → diff
- Same call path with different input → what changes
- Sibling code doing similar thing successfully → what it does differently

### 4. Form a hypothesis
- Write it down: "I believe X happens because Y."
- Predict what evidence would falsify it
- Check that evidence before fixing

### 5. Minimal failing test
- Failing test or minimal repro in the repo (or `/tmp`) where practical
- Confirms understanding and prevents regression

### 6. Apply minimal fix
- Smallest change that addresses the root cause
- No reformatting, no unrelated cleanup, no "while I'm here" edits

### 7. Verify
- Original failing scenario → now passes (quote the output)
- New failing test → now passes
- Nearby test suite → no regression

### 8. Document if non-obvious
- One-line code comment only if the root cause would surprise a future reader
- Otherwise the commit message carries the story

## Forbidden phrasing in conclusions

"should work", "probably fixed", "likely the cause", "looks correct" — replace with verified evidence or explicit "unverified — manual steps:".

## Stack-specific evidence sources

- **Java / Spring Boot** — `mvn -q test -Dtest=ClassName#method`, `--debug-jvm`, `actuator/health`, Hibernate SQL log (`spring.jpa.show-sql=true`)
- **.NET / C#** — `dotnet test --logger "console;verbosity=detailed"`, EF Core SQL logging, `dotnet-counters` for runtime metrics
- **Flutter** — `flutter test --reporter=expanded`, `flutter run --verbose`, `flutter analyze`
- **Angular** — `ng test --watch=false` with `--source-map=true`, browser devtools console, network tab payloads
- **SQL (PG/MSSQL)** — `EXPLAIN (ANALYZE, BUFFERS)` (PG) / `SET STATISTICS IO, TIME ON` (MSSQL); compare against working query plan
- **Docker** — `docker compose logs <svc> --tail=200`, `docker inspect <container>`, `docker compose config` for resolved env, `docker compose exec <svc> env` for runtime env
- **AWS / ECS** — `aws logs tail <group> --follow`, `aws ecs describe-tasks --tasks <arn>` for `stoppedReason` + exit code, `aws ecs describe-task-definition` for env/secret diff, check IAM role permissions before assuming app bug

## Deployment / config troubleshooting recipe

1. Get the exact failure signal: container exit code, ECS `stoppedReason`, ALB 5xx, health-check failure.
2. Compare working vs broken environments: image tag, env vars, secrets, task definition revision, IAM role, security group, subnet.
3. Reproduce locally with the same image + env if possible (`docker run --env-file …`).
4. Change one variable at a time. Re-run after each.
5. Confirm root cause names a specific config/env/code line before fixing.
