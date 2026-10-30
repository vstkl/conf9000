#!/bin/sh
# Lock the screen with hyprlock, unless it is already locked.
# Returns once the lock is up, so swayidle's before-sleep doesn't suspend first.
pidof hyprlock >/dev/null && exit 0
hyprlock -c "$HOME/.config/sway/hyprlock.conf" &
sleep 1
