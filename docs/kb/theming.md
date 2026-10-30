# Theming, desktop settings, XDG

Four competing theme systems; none is authoritative:
1. **GTK ini files** (`gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, tracked): Breeze theme, breeze icons/cursors 24, Noto Sans 10, prefer-dark=false, `gtk-modules=colorreload-gtk-module:window-decorations-gtk-module` (KDE/plasma-integration style; modules likely absent). `colors.css` + `window_decorations.css` + `gtk.css` (`@import 'colors.css'`) — KDE-generated. `gtk-3.0/assets/` (24 files). `gtk-2.0/gtkfilechooser.ini` filechooser state only.
2. **dconf** (`dconf/user`, binary GVariant, copied not linked): GNOME settings. `org/gnome/desktop/interface`: Adwaita, icon Qogir-Dark, **prefer-dark**, accent teal, 24h clock w/ seconds, battery %. Input sources us + cz+qwerty. Background bitday timed xml. Keybinds: Super+q close, Super+Return kitty (custom0), Ctrl+Super+e/f/q home/www/lock, Shift+Super+s screenshot. ~15 GNOME Shell extensions enabled (openbar, Vitals, appindicator, clipboard-indicator, simple-weather, …). Also virt-manager (33 sections), easyeffects (`com/github/wwmm`), nautilus, evince, etc. Under sway/scroll GTK apps read `org/gnome/desktop/interface` via xdg-desktop-portal/gsettings → dconf wins over settings.ini for GTK4/libadwaita.
   Inspect without touching live DB: `mkdir -p $T/dconf && cp dconf/user $T/dconf/ && XDG_CONFIG_HOME=$T dconf dump /`.
3. **base16 / tinty**: `color.scheme` (1 byte, empty) read by `scripts/paint.sh` → `tinty apply`; tmux `@colors-base16 'ayu-dark'`; nvim colorscheme `$BASE16_THEME`; bashrc BASE16 lines commented. tinty not installed ⇒ dead.
4. **wallust** (Hyprland): `hypr/wallust/wallust-hyprland.conf`, `waybar/wallust/colors-waybar.css`; `hypr/initial-boot.sh` would set Flat-Remix-GTK-Blue-Dark / Bibata-Modern-Ice / kvantum catppuccin. wallust not installed.
Others: `lxqt/lxqt.conf` icon_theme=oxygen; `fuzzel` icon Qogir-dark; `QtProject.conf` (untracked) = Qt file-dialog history only (no theme; no qt5ct/qt6ct dirs). WM border colors hardcoded in sway/scroll.

## Default apps {#mimeapps}
`mimeapps.list` (tracked, symlinked to ~/.config): http/https/html → firefox; mailspring, bitwarden, claude-cli URL handlers; stl → fstl; png → Loupe; mkv → vlc; jpeg → gimp (added); `application/x-bittorrent=torrent` (invalid: not a .desktop id, `mimeapps.list:18`). WM-level defaults: sway/scroll `$filemanager nautilus`, Hyprland `$files thunar` (thunar not in packages).

## XDG dirs {#xdg}
- `user-dirs.dirs` (untracked, NOT deployed): English `$HOME/Desktop, Downloads, Templates, Public, Documents, Music, Pictures, Videos` + `XDG_PROJECTS_DIR=$HOME/Projects`.
- `user-dirs.locale` (tracked, deployed): `en_US`.
- Conflicts: `gtk-3.0/bookmarks` → lowercase `/home/m/{pictures,junk,share,documents,proj,videos,downloads}`; `lsp-plugins/bookmarks.json` same lowercase; yazi keymap → Czech `~/Stažené, ~/Obrázky, ~/Dokumenty, ~/Videa, ~/Projekty`; scroll/niri screenshots → `~/Pictures/Screenshots`; ardour → `/home/m/music`.
