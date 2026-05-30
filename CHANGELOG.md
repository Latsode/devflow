# Changelog

All notable changes to devflow are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-30

### Added
- Optional graphify integration. When the `graphify` CLI and a
  `graphify-out/graph.json` are both present in the repo, the discovery,
  debugging, and code-review skills (and the planner/reviewer/debugger agents)
  use graphify's `query`/`affected`/`path`/`explain` verbs as a cheap,
  token-saving first pass before reading files. Fully self-disabling: with
  graphify absent, devflow behaves exactly as before. Results are treated as
  unverified hints (confirmed against source), queries fall back to
  Glob/Grep/Read on empty/ambiguous results, and the raw `graph.json` is never
  read directly. devflow never auto-builds the graph — it only suggests
  `graphify update .` when the CLI is present but no graph exists.

## [1.0.0] - 2026-05-27

### Added
- Six slash commands: `/devflow`, `/devflow-plan`, `/devflow-execute`, `/devflow-debug`, `/devflow-review`, `/devflow-finish`.
- Five subagents: `devflow-planner`, `devflow-implementer`, `devflow-debugger`, `devflow-reviewer`, `devflow-tester`.
- Nine skills covering the full lifecycle: adaptive routing, discovery, spec writing, plan writing, task execution, systematic debugging, code review, verification, finishing.
- Four document templates: spec, plan, review, handoff.
- Optional `SessionStart` hook printing the command cheat sheet.
- Cross-platform installers (`install.ps1`, `install.sh`) with user/project scope and uninstallers.
- Comprehensive README with architecture, model routing matrix, customization recipes, and worked examples.
