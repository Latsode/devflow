# Plan: <title>

> Slug: `<kebab-slug>` · Spec: `docs/devflow/specs/<slug>.md` · Date: <YYYY-MM-DD>

## Overview
<One paragraph linking back to the spec's goal.>

## Assumptions
- <Assumption 1>
- <Assumption 2>

## Tasks

- [ ] **T1: <verb-led goal>**
  - Files: `path/one`, `path/two`
  - Verify: `<command for this task>`
- [ ] **T2: <verb-led goal>**
  - Files: `path/three`
  - Verify: `<command>`
- [ ] **T3: <verb-led goal>**
  - Files: `path/four`
  - Verify: `<command>`

## Files touched
- `path/one`
- `path/two`
- `path/three`
- `path/four`

## Test commands
- Unit: `<full unit command>`
- Lint: `<lint command>`
- Typecheck: `<typecheck command>`
- Build: `<build command>`
- Integration / e2e (if any): `<command>`

## Rollback plan
<How to undo: revert commit hash, feature flag off, migration down, etc.>

## Completion criteria
- [ ] All tasks above checked
- [ ] All acceptance criteria in spec checked
- [ ] Full test suite green (quoted output)
- [ ] Self-review pass via `devflow-code-review`
