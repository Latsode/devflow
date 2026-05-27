# Changelog

All notable changes to devflow are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-27

### Added
- Six slash commands: `/devflow`, `/devflow-plan`, `/devflow-execute`, `/devflow-debug`, `/devflow-review`, `/devflow-finish`.
- Five subagents: `devflow-planner`, `devflow-implementer`, `devflow-debugger`, `devflow-reviewer`, `devflow-tester`.
- Nine skills covering the full lifecycle: adaptive routing, discovery, spec writing, plan writing, task execution, systematic debugging, code review, verification, finishing.
- Four document templates: spec, plan, review, handoff.
- Optional `SessionStart` hook printing the command cheat sheet.
- Cross-platform installers (`install.ps1`, `install.sh`) with user/project scope and uninstallers.
- Comprehensive README with architecture, model routing matrix, customization recipes, and worked examples.
