# Hyprland (`hypr/`, 268 files, 49 MB, ENTIRELY UNTRACKED)

Origin: JaKooLit Hyprland-Dots → renamed KoolDots (github.com/LinuxBeginnings). Version markers: empty/near-empty files `hypr/v2.3.18`, `v2.3.20`, `v2.3.25` (latest = v2.3.25; older two are leftovers from upgrades, identical text). Hyprland binary installed on host; sessions `hyprland.desktop`, `hyprland-uwsm.desktop`.

## Active entry point: `hypr/hyprland.conf` (hyprlang)
Source order (`hyprland.conf:8-42`):
1. `exec-once initial-boot.sh` — no-op because `hypr/.initial_startup_done` exists (it would set wallust/awww wallpaper, Flat-Remix GTK, Bibata cursor, kvantum).
2. `configs/Keybinds.conf` (defaults, 158 binds)
3. `configs/Startup_Apps.conf` → `UserConfigs/Startup_Apps.conf`
4. `configs/ENVariables.conf` → `UserConfigs/ENVariables.conf`
5. `configs/Laptops.conf` → `UserConfigs/Laptops.conf` → `UserConfigs/LaptopDisplay.conf`
6. `configs/WindowRules.conf` → `UserConfigs/WindowRules.conf`
7. `configs/SystemSettings.conf`
8. `UserConfigs/UserDecorations.conf` (sources `hypr/wallust/wallust-hyprland.conf` for `$colorN`; rounding 10, blur, dim inactive), `UserAnimations.conf`, `UserKeybinds.conf` (only vars, 0 real binds), `UserSettings.conf`, `01-UserDefaults.conf` (EDITOR=nvim, `$term kitty`, `$files thunar`, Google search)
9. `monitors.conf` (nwg-displays: eDP-1 **1920x1200**@60 at 0,0; DP-1 1920x1080 at 1930,0), `workspaces.conf`.
Rule: `configs/` = upstream defaults (overwritten by KoolDots updates), `UserConfigs/` = user edits.

## Not loaded / experiments
- `hyprland.lua.disable` + `lua/*.lua` (21) + `hl.meta.lua` + `.luarc.json` + `UserConfigs/user_*.lua` + `configs/system_keybinds.lua` + `animations/*.lua` + `Monitor_Profiles/*.lua` + `monitors.lua`: KoolDots Lua-config path; disabled (file suffix `.disable`).
- `configs/{keybinds,startup,variables,window_rules,animations}.conf` (lowercase) — legacy pre-v2 files, not sourced. `configs/WindowRules-pre-53.conf`, `WindowRules-config-v3.conf` — alt versions, not sourced. `configs/LayerRules.conf`, `UserConfigs/LayerRules.conf`, `UserConfigs/WorkSpaceRules.conf` — NOT sourced anywhere (verified grep of `source` lines). Only nested sources: `configs/Keybinds.conf:12` → `01-UserDefaults.conf` (so it loads twice), `UserDecorations.conf:9` → wallust colors.
- `animations/*.conf` — presets copied into UserAnimations.conf by `scripts/Animations.sh`.
- `Monitor_Profiles/*.conf` — copied to monitors.conf by `scripts/MonitorProfiles.sh`.
- `hyprlock.conf.bk` — byte-identical to `hyprlock-2k.conf` (stale backup).
- `scripts/*.bk`, `UserScripts/RainbowBorders.bak.sh` — backups.
- `scripts/` contains case-duplicate pairs (`changeLayout.sh`/`ChangeLayout.sh`, `clipManager.sh`/`ClipManager.sh`, `refresh.sh`/`Refresh.sh`, `waybarLayout.sh`/`WaybarLayout.sh`, `waybarStyles.sh`/`WaybarStyles.sh`, `wallpaperSelect.sh`/`WallpaperSelect.sh`, `screenshot.sh`/`ScreenShot.sh`) — old lowercase = legacy.

## Key components
| concern | where | deps (host status) |
|---|---|---|
| autostart | `configs/Startup_Apps.conf`: awww-daemon, dbus/systemd env import, Dropterminal, nm-applet, nm-tray, swaync, waybar, `qs -c overview` (twice: `:28`,`:49`), hypridle, Hyprsunset, cliphist watchers, blueman-applet, KeybindsLayoutInit | awww, swaync, quickshell, wallust NOT installed |
| idle | `hypridle.conf`: notify 540 s, `loginctl lock-session` 600 s, lock before sleep | icon from `~/.config/swaync/images` (missing) |
| lock | `hyprlock.conf` → sources `~/.config/hyprlock/colors.conf` + `layouts/layout11.conf` + scripts — **dir `~/.config/hyprlock` not in repo**. Bind Ctrl+Alt+L → `scripts/LockScreen.sh` → `loginctl lock-session` | |
| wallpaper | `hyprpaper.conf` (`~/Pictures/wallpapers/Buildings.png`), awww via `$wallDIR=~/Pictures/wallpapers` | wallpapers not in repo |
| colors | `wallust/wallust-hyprland.conf` (generated) ; `waybar/wallust/colors-waybar.css` | |
| launcher/menus | rofi (`~/.config/rofi` missing) | |
| notifications | swaync (`~/.config/swaync` missing) | |

## Keybinds (configs/Keybinds.conf, S = Super)
S+D rofi drun · S+Return kitty · S+E thunar · S+B browser · S+A overview · S+Q kill · S+Shift+Q kill process · S+Space float · S+Shift+F fullscreen · S+Ctrl+F maximize · S+Shift+Return dropdown term · S+T wallust theme · S+H cheatsheet · S+Alt+V clipboard · S+W wallpaper · Ctrl+Alt+L lock · Ctrl+Alt+P powermenu · Ctrl+Alt+Del exit · S+Shift+N notif panel · S+Print / S+Shift+Print / S+Shift+S screenshots · Alt+Shift switch kb layout · S+Alt+L master/dwindle · Alt+Tab cycle. Full list: `grep ^bind hypr/configs/Keybinds.conf`.

## Other dirs referenced but missing from repo
rofi, swaync, wlogout, hyprlock, wallust (tool config), qt5ct, qt6ct, ghostty, cava, ags, kvantum.
