#!/usr/bin/env bash
# Clipboard history picker on top of cliphist.
# History is recorded by the `wl-paste --watch cliphist store` lines in sway/scroll config.
#
#   clipboard.sh          pick with fuzzel (default)
#   clipboard.sh rofi     pick with rofi (theme: ~/.config/rofi/config-clipboard.rasi)
#   clipboard.sh delete   pick an entry to delete
#   clipboard.sh wipe     clear the whole history
set -euo pipefail

picker=${1:-fuzzel}

pick() {
	case "$picker" in
	rofi) rofi -dmenu -i -p "clipboard" -config "$HOME/.config/rofi/config-clipboard.rasi" ;;
	*) fuzzel --dmenu --prompt "clip> " --width 80 --lines 15 ;;
	esac
}

case "$picker" in
wipe)
	cliphist wipe && notify-send "Clipboard" "History wiped"
	;;
delete)
	picker=fuzzel
	entry=$(cliphist list | pick) || exit 0
	cliphist delete <<<"$entry"
	;;
*)
	entry=$(cliphist list | pick) || exit 0
	cliphist decode <<<"$entry" | wl-copy
	;;
esac
