#!/usr/bin/env bash
# Show SHORTCUTS.md (used by tmux: prefix F1 and the prefix ? menu).
# glow -> bat -> less, whichever is installed.
f="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/SHORTCUTS.md"
if command -v glow >/dev/null 2>&1; then
  exec glow -p "$f"
elif command -v bat >/dev/null 2>&1; then
  exec bat --paging=always --style=plain --language=markdown "$f"
else
  exec less -R "$f"
fi
