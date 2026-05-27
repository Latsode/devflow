#!/usr/bin/env bash
# devflow session-start hook (OPTIONAL).
#
# Wire into settings.json under hooks.SessionStart if you want a one-line
# reminder of available devflow commands at every session start.
#
# Example settings.json entry:
#   "hooks": {
#     "SessionStart": [
#       { "matcher": "startup", "hooks": [{ "type": "command",
#         "command": "bash ~/.claude/devflow/hooks/session-start.sh" }] }
#     ]
#   }
#
# The hook is non-blocking; it just prints a short hint.

set -eu

cat <<'EOF'
devflow ready — /devflow <task> · /devflow-plan · /devflow-execute · /devflow-debug · /devflow-review · /devflow-finish
EOF
