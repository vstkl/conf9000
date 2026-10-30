# sway

## Files (active vs not)
| file | status |
|---|---|
| `sway/config` (271 l, tracked, heavily modified uncommitted) | **ACTIVE**. Clean rewrite 2026-10-21 23:10 + batch-1 edits (cliphist, bt-menu, clipboard binds) |
| `sway/lock.sh` (untracked) | ACTIVE, used as `$lock` (`config:21`) |
| `sway/clipboard.sh` (new, batch 1) | ACTIVE: cliphist picker; args none=fuzzel, `rofi`, `delete`, `wipe`. Also used by waybar `custom/clipboard` (`waybar/ModulesCustom:20-26`) and scroll |
| `sway/hyprlock.conf` (untracked, 155 l) | ACTIVE, lock UI for lock.sh; self-contained (no external sources) |
| `sway/config.bak-20261021-225659`, `config.bak-20261021-230603` | STALE, byte-identical; = committed HEAD version, which was a copy of an older scroll config (`include /etc/scroll/config.d/*`, thunar, lxqt-policykit) |
| `sway/config.broken-230202` (332 l) | STALE failed port of scroll config → sway (swaylock, autostarts bitwarden/easyeffects/warp-taskbar) |
Live `~/.config/sway` == repo `sway/` before batch 1; now repo is ahead (repo not deployed).

## sway/config structure
- `:8-21` vars: `$mod Mod4`, hjkl, `$term kitty`, `$menu fuzzel`, `$filemanager nautilus`, `$browser firefox`, `$lock ~/.config/sway/lock.sh`.
- `:25` wallpaper line commented (no wallpaper set). `:26-30` `output eDP-1` 1920x1080 @ 0,0 scale 1.25.
- `:35-38` swayidle: lock 300 s, DPMS off 600 s, lock before-sleep.
- `:41-47` autostart: polkit-gnome agent, `~/.config/mako/battery.sh` (loop), `waybar -b 1`, `wl-paste --watch cliphist store` (text+image, `:46-47`). No mako/notification daemon exec (relies on D-Bus activation; mako not installed on host). No nm-applet.
- `:52-67` input: touchpad tap/natural scroll; keyboard `us,cz`, `altwin:prtsc_rwin`, repeat 200/30. No layout-toggle option set (no `grp:` option ⇒ can't switch to cz by key).
- `:70-76` border pixel 2, gaps 1/2, client colors (focused #15439e).
- `:79-83` for_window: inhibit idle fullscreen, float polkit "Authentication Required", XWayland title prefix, `bt-menu` (bluetui popup from waybar) floating 760x480 centered.
- `:271` `include /etc/sway/config.d/*` (Arch ships 50-systemd-user.conf).

## Keybinds ($mod = Super)
Return term · Space fuzzel · Shift+v clipboard pick · Ctrl+v clipboard delete · Ctrl+Shift+v clipboard wipe · Shift+e nautilus · Shift+f firefox · q kill · Ctrl+Backspace kill all on ws · Shift+c reload · Ctrl+q lock · Shift+x exit (swaynag) · hjkl/arrows focus · Ctrl+hjkl/arrows move · Shift+hjkl focus output · 1-0 ws · Shift+1-0 move+follow · Ctrl+1/2 move ws to output L/R · (Shift+)Page_Up/Down ws prev/next (on output) · Tab / Ctrl+z back_and_forth · 4-finger swipe ws next/prev · Shift+comma/period/Ctrl+period output scale 1/1.5/1.25 · `[` splith `]` splitv · s stacking · w tabbed · e toggle split · f fullscreen · Ctrl+f fullscreen global · v float · y focus mode_toggle · a parent · Shift+a child · Shift+Ctrl+a sticky · Shift+z → scratchpad · z show scratchpad · minus/equal (Shift) resize 10ppt · Shift+r mode resize · b / Shift+b modes setsizeh/setsizev (digits = % presets) · XF86 audio/media/brightness (`--locked`, call `~/.config/mako/{volume,brightness}.sh`) · Shift+s `grim` full screenshot (saves to grim default dir, no clipboard).

## Lock chain
swayidle / `$mod+Ctrl+q` → `sway/lock.sh` (exit if hyprlock running; `hyprlock -c ~/.config/sway/hyprlock.conf &`; `sleep 1`). Requires hyprlock (installed on host, not in `packages`).
