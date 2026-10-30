#!/usr/bin/env bash
# Bluetooth helpers for the waybar bluetooth module.
#
#   bluetooth.sh menu     bluetui dropdown under the bar (scan, pair, connect)
#   bluetooth.sh toggle   power the adapter on/off
set -euo pipefail

case "${1:-menu}" in
toggle)
	# bluetoothctl waits forever when there is no adapter / bluetoothd, so cap every call
	if ! state=$(timeout 3 bluetoothctl show 2>/dev/null) || ! grep -q '^Controller' <<<"$state"; then
		notify-send "Bluetooth" "No adapter found (is bluetooth.service running?)" 2>/dev/null || true
		exit 1
	fi
	if grep -q 'Powered: yes' <<<"$state"; then
		timeout 5 bluetoothctl power off
	else
		rfkill unblock bluetooth 2>/dev/null || true
		timeout 5 bluetoothctl power on
	fi
	;;
menu)
	# drops down under the bar; clicking the icon again closes it (dropdown.sh); q = bluetui quit.
	# If bluetui can't start (no adapter / bluetooth.service down) the window stays open with
	# the reason instead of flashing shut.
	exec "$(dirname "$0")/dropdown.sh" bt-menu 64 17 -- \
		bash -c 'bluetui || { printf "\nbluetui could not start: no adapter or bluetooth.service not running\n  systemctl status bluetooth\n\n"; read -rsn1 -p "press any key to close"; }'
	;;
*)
	echo "usage: $0 [menu|toggle]" >&2
	exit 1
	;;
esac
