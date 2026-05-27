#!/usr/bin/env bash
# Remove devflow from Claude Code.
set -eu

SCOPE="${1:-user}"
case "$SCOPE" in
  user)    TARGET="$HOME/.claude" ;;
  project) TARGET="$(pwd)/.claude" ;;
  *) echo "usage: $0 [user|project]" >&2; exit 2 ;;
esac

echo "devflow uninstaller — target: $TARGET"

for f in devflow.md devflow-plan.md devflow-execute.md devflow-debug.md devflow-review.md devflow-finish.md; do
  [ -f "$TARGET/commands/$f" ] && rm -f "$TARGET/commands/$f" && echo "  removed commands/$f"
done

for f in devflow-planner.md devflow-implementer.md devflow-debugger.md devflow-reviewer.md devflow-tester.md; do
  [ -f "$TARGET/agents/$f" ] && rm -f "$TARGET/agents/$f" && echo "  removed agents/$f"
done

for d in "$TARGET"/skills/devflow-*; do
  [ -d "$d" ] && rm -rf "$d" && echo "  removed skills/$(basename "$d")"
done

[ -d "$TARGET/devflow" ] && rm -rf "$TARGET/devflow" && echo "  removed devflow/"

echo "Done."
echo "Note: SessionStart hook (if installed) was NOT auto-removed — edit settings.json manually."
