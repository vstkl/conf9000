#!/usr/bin/env bash
# Small kitty "dropdown" under waybar, laid out like the calendar tooltip (no animation).
# Colors come from the kitty base16 theme (tinty), same palette as waybar's tooltip.
#
#   dropdown.sh APP_ID COLS ROWS [KITTY_OPTION...] -- COMMAND...
#   dropdown.sh --resize APP_ID COLS ROWS     (from inside the dropdown: change its size,
#                                             it stays under the bar, centered on the icon)
#
# Running it again while open closes it (click the icon again). The for_window rule in
# sway/scroll config floats APP_ID at the cursor 42px down; this script then aligns its top
# to just below the bar of the focused output, whatever the bar height is.
set -euo pipefail

msg=swaymsg
[ -n "${SCROLLSOCK:-}" ] && command -v scrollmsg >/dev/null && msg=scrollmsg
wm_ok() { command -v "$msg" >/dev/null && command -v jq >/dev/null && "$msg" -t get_version >/dev/null 2>&1; }
geom_file() { echo "${XDG_RUNTIME_DIR:-/tmp}/dropdown-$1.geom"; }

if [ "${1:-}" = --resize ]; then
	app_id=$2 cols=$3 rows=$4
	wm_ok && [ -r "$(geom_file "$app_id")" ] || exit 0
	read -r center top cw ch ox ow <"$(geom_file "$app_id")"
	w=$((cols * cw)) h=$((rows * ch))
	x=$((center - w / 2))
	[ $((x + w)) -gt $((ox + ow)) ] && x=$((ox + ow - w))
	[ "$x" -lt "$ox" ] && x=$ox
	"$msg" "[app_id=\"$app_id\"] resize set $w $h, move absolute position $x $top" >/dev/null
	# wait until the terminal has the new size, so the next program lays out for it
	for _ in $(seq 1 20); do
		[ "$(tput lines 2>/dev/null)" = "$rows" ] && break
		sleep 0.05
	done
	exit 0
fi

app_id=$1 cols=$2 rows=$3
shift 3
opts=()
while [ $# -gt 0 ] && [ "$1" != "--" ]; do
	opts+=(-o "$1")
	shift
done
shift

pkill -f "^kitty --class $app_id( |$)" && exit 0

kitty --class "$app_id" \
	-o remember_window_size=no -o initial_window_width="${cols}c" -o initial_window_height="${rows}c" \
	-o window_padding_width=0 -o background_opacity=1 \
	"${opts[@]}" "$@" &
kitty_pid=$!

if wm_ok; then
	rect=""
	for _ in $(seq 1 50); do
		rect=$("$msg" -t get_tree | jq -r --arg id "$app_id" \
			'first(.. | objects | select(.app_id? == $id) | "\(.rect.x) \(.rect.width) \(.rect.height)") // empty')
		[ -n "$rect" ] && break
		sleep 0.1
	done
	if [ -n "$rect" ]; then
		read -r x w h <<<"$rect"
		top=$(("$("$msg" -t get_workspaces | jq -r 'first(.[] | select(.focused)) | .rect.y')" + 2))
		"$msg" "[app_id=\"$app_id\"] move absolute position $x $top" >/dev/null
		# geometry for --resize: icon center, top edge, cell size, output span
		read -r ox ow < <("$msg" -t get_outputs | jq -r 'first(.[] | select(.focused)) | "\(.rect.x) \(.rect.width)"')
		echo "$((x + w / 2)) $top $((w / cols)) $((h / rows)) $ox $ow" >"$(geom_file "$app_id")"
	fi
fi

wait "$kitty_pid" || true
rm -f "$(geom_file "$app_id")"
