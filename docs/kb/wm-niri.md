# niri (`niri/config.kdl`, 616 l, tracked)

Status: **INACTIVE / experiment**. niri not installed on host, not in `packages`, no session file. Config is essentially the upstream default with small edits:
- `:9-26` input: xkb block empty (falls back to localectl), numlock; touchpad tap + natural-scroll.
- `:78` `/-output "eDP-1"` — whole output block disabled (KDL `/-` comment); inside: scale 0.5 (would be wrong if enabled).
- `:112-263` layout: gaps 2, presets 1/3,1/2,2/3, default width 0.5, focus-ring off, border width 4.
- `:271` `spawn-at-startup "waybar"` (waybar `config` is Hyprland-oriented → hyprland/* modules fail under niri).
- `:286` prefer-no-csd; `:291` screenshots → `~/Pictures/Screenshots/`.
- Window rules: wezterm, Firefox PiP float; KeePassXC block-out disabled.

Keybinds (`:349-616`, Mod = Super): T/Return kitty · Space fuzzel · Super+Alt+L swaylock · O overview · Q close · hjkl/arrows focus · Ctrl+hjkl move · Shift+hjkl focus monitor · U/I/PgUp/PgDn workspace · 1-9 ws, Ctrl+1-9 move column · `[`/`]` consume/expel · R preset width · F maximize · Shift+F fullscreen · C center · V float · W tabbed · minus/equal width ±10% · Print/Ctrl+Print/Alt+Print screenshot · Shift+E / Ctrl+Alt+Del quit · Shift+P monitors off. Volume via `wpctl` (unlike sway/scroll which use pactl).
No idle/lock daemon, no polkit agent, no notification daemon configured.
