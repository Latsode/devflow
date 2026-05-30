# devflow session-start hook (Windows, OPTIONAL).
#
# Windows twin of session-start.sh — for boxes without a working bash.
# Wire into settings.json under hooks.SessionStart if you want a one-line
# reminder of available devflow commands at every session start.
#
# install.ps1 -InstallHook wires this automatically:
#   "hooks": {
#     "SessionStart": [
#       { "matcher": "startup", "hooks": [{ "type": "command",
#         "command": "powershell -NoProfile -File \"<...>\\devflow\\hooks\\session-start.ps1\"" }] }
#     ]
#   }
#
# The hook is non-blocking; it just prints a short hint.

Write-Output 'devflow ready - /devflow | /devflow-plan | /devflow-execute | /devflow-debug | /devflow-review | /devflow-finish'
