#!/usr/bin/env bash
# Network helper for the waybar network module.
#
#   network.sh menu    nmtui dropdown under the bar (sized to its main menu)
#
# nmtui lays a screen out only once, for the terminal size it has at that moment, so the
# dropdown shows nmtui's main menu itself (same newt widgets via whiptail, same colors) and
# grows the window *before* starting the chosen nmtui screen; leaving that screen returns
# to the small menu.
set -euo pipefail

# newt colors (nmtui + whiptail) without the blue background: terminal (base16) colors, box
# frame in brightmagenta (= base0E, the tooltip frame color), cyan highlight
export NEWT_COLORS='root=white,default;window=white,default;border=brightmagenta,default;shadow=default,default
title=brightmagenta,default;roottext=white,default;helpline=white,default
button=black,white;actbutton=black,cyan;compactbutton=white,default
listbox=white,default;actlistbox=white,default;sellistbox=cyan,default;actsellistbox=black,cyan
textbox=white,default;acttextbox=black,cyan;entry=white,default;disentry=gray,default
label=white,default;checkbox=white,default;actcheckbox=black,cyan;emptyscale=,default;fullscale=,cyan'

dir="$(dirname "$0")"

case "${1:-menu}" in
menu)
	# drops down under the bar; clicking the icon again closes it (dropdown.sh)
	# q closes it like bluetui (kitty/menu_q.py; still types q into text fields)
	exec "$dir/dropdown.sh" nm-menu 28 14 'map q kitten menu_q.py' -- "$0" loop
	;;
loop)
	# runs inside the dropdown
	while :; do
		"$dir/dropdown.sh" --resize nm-menu 28 14
		choice=$(whiptail --title "NetworkManager TUI" --notags --nocancel --ok-button Select \
			--menu "Please select an option" 13 28 5 \
			edit "Edit a connection" \
			connect "Activate a connection" \
			hostname "Set system hostname" \
			radio "Radio" \
			quit "Quit" 3>&1 1>&2 2>&3) || exit 0
		[ "$choice" = quit ] && exit 0
		"$dir/dropdown.sh" --resize nm-menu 62 22
		nmtui "$choice" || true
	done
	;;
*)
	echo "usage: $0 [menu]" >&2
	exit 1
	;;
esac
