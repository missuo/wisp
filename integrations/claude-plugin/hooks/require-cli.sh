#!/bin/sh
# PreToolUse(Skill): do not load the wisp skill on a machine where the CLI is missing.
# The skill's own first step is to check, but by then its body is already in the context
# window and the turn ends in this same message, so answer before it expands.
set -u

input=$(cat)

# Other skills are none of this hook's business.
echo "$input" | grep -Eq '"skill"[[:space:]]*:[[:space:]]*"(wisp:)?wisp"' || exit 0
command -v wisp >/dev/null 2>&1 && exit 0

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "The `wisp` command is not installed on this machine, so the wisp skill cannot run. Tell the user to install it with `brew install --cask owo-network/brew/wisp` (this installs Wisp.app and the CLI together), then open Wisp.app once and grant Accessibility in System Settings > Privacy & Security; `wisp doctor` reports what is still missing. Do not fall back to AppleScript, osascript or other input tools."
  }
}
JSON
