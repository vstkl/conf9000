# Bar, notifications, launcher

## waybar (`waybar/`, only 3 files tracked: `config.jsonc`, `power_menu.xml`, `style.css`)
Started by: sway `config:41` and scroll `config:85` as `waybar -b 1`; Hyprland `configs/Startup_Apps.conf` (`waybar`); niri `config.kdl:271`.

**Which config loads**: waybar looks for `config` then `config.jsonc` in `~/.config/waybar/` (Waybar v0.15 default order; verify with `waybar -l debug`). Both exist ⇒ **untracked `waybar/config` (JaKooLit "Default Laptop – Top", Hyprland modules) wins over tracked `config.jsonc` (sway modules)**. Under sway/scroll the `hyprland/window`, `hyprland/workspaces#rw`, `hyprland/language` modules don't work.

| file | role |
|---|---|
| `config` (untracked) | effective config. includes `Modules`, `ModulesWorkspaces`, `ModulesCustom`, `ModulesGroups`, `UserModules`. Left: playerctl, hyprland/window. Center: hyprland/workspaces#rw, clock, custom/weather, custom/clipboard. Right: network, bluetooth, custom/wireguard, backlight, hyprland/language, custom/claude, power-profiles-daemon, battery |
| `config.jsonc` (tracked) | older sway bar: sway/workspaces/mode/scratchpad, sway/window, clipboard(scrollmsg), idle_inhibitor, pulseaudio, network, ppd, cpu, memory, temperature, custom/fan (`sensors thinkpad-isa-0000`), backlight, sway/language, battery, clock, custom/warp (warp-cli), custom/power (`power_menu.xml`), tray |
| `configs/` | ~40 JaKooLit layout presets + `configs/vojta` (user's own: hyprland/workspaces, wireguard, pulseaudio…) — selected by `hypr/scripts/WaybarLayout.sh` (copies to `config`) |
| `style.css` (tracked, uncommitted: now JaKooLit "Half Moon" style) | effective style |
| `style/` | ~35 JaKooLit themes (+ `catppuccin-themes/`) — chosen by `hypr/scripts/WaybarStyles.sh` |
| `Modules*`, `UserModules` | module definitions. `UserModules` = `custom/claude` |
| `wallust/colors-waybar.css` | wallust-generated palette |
| `scripts/claude-usage.sh` | reads `~/.claude/.credentials.json` (OAuth token!) to query Claude usage API; caches `/tmp/claude-usage.json` |
| `scripts/bluetooth.sh` (batch 1) | bluetooth menu/power helper |
| `scripts/wg-status.sh`, `wg-update.sh` | "wireguard" module actually checks/toggles **tailscale0** (`tailscale up/down`) |
| `power_menu.xml`, `speaker.xml` | GTK menu definitions |
Batch 1: `bluetooth` (`Modules:87+`): left blueman-manager, right `scripts/bluetooth.sh menu` (bluetui in kitty `--class bt-menu`), middle power toggle. `custom/clipboard` (`ModulesCustom:20-26`): left `sway/clipboard.sh` (fuzzel), right `… rofi`.
Cross-dir deps: `custom/weather` → `~/.config/hypr/UserScripts/Weather.py`; clipboard → `~/.config/sway/clipboard.sh`; others → `hypr/scripts/{Hypridle,Hyprsunset,WaybarCava}.sh`, swaync-client. **waybar depends on the untracked hypr/ tree.**

## mako (`mako/`, tracked) {#mako}
- `config`: timeout 15 s, top-center, overlay, width 400; `[urgency=high]` red border; `[category=bat]` red, no timeout; `[category=volume]`/`[app-name=brightness]` progress bars, history=0. `config.critical`: alt config (not referenced anywhere).
- `battery.sh`: infinite loop, reads `/sys/class/power_supply/BAT0/capacity` every 120 s; ≤5 % → notify (category bat), then sleeps 12000 s. Started by sway/scroll `exec`.
- `volume.sh`, `brightness.sh`: notify-send with `int:value` hint; called from XF86 binds.
- **mako binary not installed on host** and not in `packages` ⇒ notifications under sway/scroll currently go nowhere (unless another daemon is D-Bus activated).

## fuzzel (`fuzzel/fuzzel.ini`, tracked) {#fuzzel}
font "Adwaita Mono", icon theme Qogir-dark, match-mode fzf, width 100, overlay layer, colors bg 111111dd / text white, border 4 r10. Bound to `$mod+Space` in sway/scroll/niri; also default clipboard picker. Not in `packages`.

## rofi (`rofi/`, added batch 1)
`config.rasi`, `config-clipboard.rasi` (theme for `sway/clipboard.sh rofi`). Hyprland's rofi menus expect many more files (`~/.config/rofi/...` themes, wallust) — still missing.
