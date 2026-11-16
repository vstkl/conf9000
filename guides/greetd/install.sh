#!/bin/sh
# Install greetd + ReGreet-in-Hyprland login screen. Takes effect on next boot
# (restarting greetd would kill the running session).
set -e
cd "$(dirname -- "$0")"

# Refuse a Hyprland config Hyprland itself rejects (greetd would crash-loop at boot).
Hyprland --verify-config --config "$PWD/hyprland.lua"

sudo pacman -S --needed --noconfirm greetd-regreet
sudo systemd-tmpfiles --create   # ReGreet's /var/lib/regreet, /var/log/regreet (if the package ships them)
sudo install -d -o greeter -g greeter -m 755 /var/lib/regreet /var/log/regreet
sudo install -m 644 config.toml hyprland.lua regreet.toml /etc/greetd/
# Remove the old per-user session launcher (GNOME enforcement for k), if present.
sudo rm -f /usr/local/bin/greetd-session
grep -v '^#' /etc/greetd/config.toml | grep .
