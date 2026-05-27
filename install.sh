#!/usr/bin/env bash
# devflow installer (macOS / Linux / WSL).
#
# Copies devflow commands, agents, skills, hooks, and templates into
# Claude Code's config directory.
#
# Default behavior: forcibly overwrite all devflow-owned files in the target
# (commands/devflow*.md, agents/devflow-*.md, skills/devflow-*, devflow/ tree).
# Non-devflow files in the target are never read or modified.
#
# Usage:
#   ./install.sh                       # user-global install (~/.claude), overwrite devflow files
#   ./install.sh --scope project       # project-local install (./.claude)
#   ./install.sh --no-force            # skip devflow files that already exist (keep local edits)
#   ./install.sh --install-hook        # wire the SessionStart hint hook

set -eu

SCOPE="user"
FORCE=1
INSTALL_HOOK=0

while [ $# -gt 0 ]; do
  case "$1" in
    --scope)        SCOPE="$2"; shift 2 ;;
    --force)        FORCE=1; shift ;;
    --no-force)     FORCE=0; shift ;;
    --install-hook) INSTALL_HOOK=1; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

SOURCE="$(cd "$(dirname "$0")" && pwd)"

case "$SCOPE" in
  user)    TARGET="$HOME/.claude" ;;
  project) TARGET="$(pwd)/.claude" ;;
  *) echo "scope must be 'user' or 'project'" >&2; exit 2 ;;
esac

echo "devflow installer"
echo "  source : $SOURCE"
echo "  target : $TARGET"
echo "  scope  : $SCOPE"
echo

mkdir -p \
  "$TARGET/commands" \
  "$TARGET/agents" \
  "$TARGET/skills" \
  "$TARGET/devflow/hooks" \
  "$TARGET/devflow/templates" \
  "$TARGET/devflow/docs"

copy_dir() {
  local from="$1" to="$2" label="$3"
  [ -d "$from" ] || return 0
  for entry in "$from"/*; do
    [ -e "$entry" ] || continue
    local base; base="$(basename "$entry")"
    local dest="$to/$base"
    if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
      printf "  skip  (%s) %s — exists\n" "$label" "$base"
      continue
    fi
    if [ -d "$entry" ]; then
      rm -rf "$dest"
      cp -R "$entry" "$dest"
    else
      cp "$entry" "$dest"
    fi
    printf "  copy  (%s) %s\n" "$label" "$base"
  done
}

copy_dir "$SOURCE/commands"  "$TARGET/commands"          "cmd  "
copy_dir "$SOURCE/agents"    "$TARGET/agents"            "agent"
copy_dir "$SOURCE/skills"    "$TARGET/skills"            "skill"
copy_dir "$SOURCE/hooks"     "$TARGET/devflow/hooks"     "hook "
copy_dir "$SOURCE/templates" "$TARGET/devflow/templates" "tmpl "
copy_dir "$SOURCE/docs"      "$TARGET/devflow/docs"      "doc  "

chmod +x "$TARGET/devflow/hooks"/*.sh 2>/dev/null || true

if [ "$INSTALL_HOOK" -eq 1 ]; then
  SETTINGS="$TARGET/settings.json"
  echo
  echo "Wiring SessionStart hook into $SETTINGS"

  if ! command -v jq >/dev/null 2>&1; then
    echo "  jq not installed — skipping. Add this manually to $SETTINGS:"
    cat <<'EOF'
  "hooks": {
    "SessionStart": [
      { "matcher": "startup",
        "hooks": [{ "type": "command",
                    "command": "bash ~/.claude/devflow/hooks/session-start.sh" }] }
    ]
  }
EOF
  else
    if [ -f "$SETTINGS" ]; then
      cp "$SETTINGS" "$SETTINGS.devflow.bak"
      echo "  backed up existing settings.json -> $SETTINGS.devflow.bak"
    else
      echo '{}' > "$SETTINGS"
    fi
    tmp="$(mktemp)"
    jq '.hooks.SessionStart = [
          { matcher: "startup",
            hooks: [{ type: "command",
                      command: "bash ~/.claude/devflow/hooks/session-start.sh" }] }
        ]' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "  hook installed"
  fi
fi

echo
echo "Done. Restart Claude Code (or just open a new conversation)."
echo "Try: /devflow help me refactor the order service"
