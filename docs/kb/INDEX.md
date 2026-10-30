# conf9000 KB — start here

Snapshot 2026-10-30, branch `live`. Line numbers match the working tree **after main-agent change batch 1** (see PROGRESS.md); they drift — re-grep before editing.

**What**: copy of user `m`'s Arch `~/.config` + bootstrap scripts. Host: ThinkPad T490 (BAT0, eDP-1 1920x1080, `easyeffects/output/t490*.json`), bash, Wayland. Sessions installed on host: sway, scroll (`sway-scroll` pkg), Hyprland, GNOME (`/usr/share/wayland-sessions`). niri is NOT installed.
**Daily driver**: sway (just rewritten 2026-10-21) and scroll; Hyprland = JaKooLit/KoolDots tree; GNOME settings live in dconf.
**Live vs repo**: `~/.config/*` on host are real dirs, NOT symlinks to this repo. Repo drifts from live (see ISSUES.md #D1).
**No `.gitignore`** exists. ~45 paths untracked, incl. secret-bearing app dirs → SENSITIVE.md.

## Mapping to $HOME (from `recreate-environment.sh:149-179`)
| repo | deployed as | how |
|---|---|---|
| every top-level **dir** except `guides`, `.git` | `~/.config/<dir>` | symlink (old target moved to `~/.config-backup-<ts>/`) |
| `dconf/user` | `~/.config/dconf/user` | **copied** (not linked) |
| `bashrc` | `~/.bashrc` | symlink |
| `mimeapps.list`, `user-dirs.locale`, `arch-hero-wallpaper-free.png` | `~/.config/<same>` | symlink |
| `user-dirs.dirs`, `color.scheme`, `QtProject.conf`, `pavucontrol.ini` | — | **not deployed** |
Caveat: the dir loop also links `docs/`, `testenv/`, `Signal/`, `Bitwarden/`, `mozilla/`… (ISSUES #B1).

## Top-level map
| path | purpose | detail |
|---|---|---|
| `bashrc`, `scripts/` | shell rc; every non-dir file in scripts/ is sourced | shell.md |
| `sway/` | sway config (active, 271 lines) + lock.sh + hyprlock.conf + clipboard.sh + 3 stale backups | wm-sway.md |
| `scroll/` | scroll (sway fork, scrolling layout) config + identical .bak | wm-scroll.md |
| `hypr/` | Hyprland, JaKooLit/KoolDots v2.3.x tree, untracked, 49 MB | wm-hyprland.md |
| `niri/config.kdl` | near-stock niri config (niri not installed) | wm-niri.md |
| `waybar/` | bar; `config` (Hyprland/JaKooLit) shadows `config.jsonc` (sway) | waybar.md |
| `mako/` | notification config + battery/volume/brightness notify scripts | waybar.md#mako |
| `fuzzel/` | launcher | waybar.md#fuzzel |
| `rofi/` | `config.rasi`, `config-clipboard.rasi` (added batch 1; alt clipboard picker) | waybar.md#fuzzel |
| `kitty/`, `tmux/`, `nvim/`, `yazi/` | terminal, multiplexer, editor (LazyVim), file manager | terminal-editor.md |
| `gtk-2.0/ gtk-3.0/ gtk-4.0/ lxqt/ dconf/ color.scheme QtProject.conf` | theming / desktop settings | theming.md |
| `mimeapps.list`, `user-dirs.*` | default apps, XDG dirs | theming.md#xdg |
| `recreate-environment.sh after-install.sh install_optdeps.sh packages failed-packages.log` | bootstrap | bootstrap.md |
| `refind/refind-efifetch/` | rEFInd theme (vendored, no submodule) | bootstrap.md#refind |
| `guides/` | how-to notes/scripts (not deployed) | guides.md |
| `ardour8 corectrl easyeffects kicad lsp-plugins neofetch ventoy …` | app configs | apps.md |
| `Bitwarden Signal mozilla gh github-copilot evolution pulse ibus …` | app STATE, secrets | SENSITIVE.md |
| `docs/` | PROGRESS.md + this KB | — |
| `testenv/` | test VM/chroot harness (subagent B, 550 MB images) | testenv/README.md |

## Where to change X
| X | file |
|---|---|
| prompt PS1 | `bashrc:50-73` (`__prompt` via PROMPT_COMMAND + git-prompt.sh) |
| aliases | `bashrc:8-12`, `scripts/alias.sh`, `scripts/*.sh` (one alias/function per file) |
| PATH / env | `bashrc:17-36`; ESP-IDF: `scripts/esp-ctx.sh` (`esp use <tag>`) vs `scripts/idf.sh` |
| keybinds sway | `sway/config:85-269` ($mod=Super) |
| keybinds scroll | `scroll/config:166-605` |
| keybinds Hyprland | `hypr/configs/Keybinds.conf` (defaults), `hypr/UserConfigs/UserKeybinds.conf` (user) |
| keybinds niri | `niri/config.kdl:349-616` |
| keybinds GNOME | dconf `org/gnome/settings-daemon/plugins/media-keys`, `org/gnome/shell/keybindings` |
| bar | `waybar/config` (effective) / `waybar/config.jsonc`; style `waybar/style.css`; Modules* files; bluetooth click actions `waybar/Modules:87+` → `waybar/scripts/bluetooth.sh` |
| notifications | `mako/config` (mako NOT installed on host); Hyprland uses swaync (missing) |
| launcher | fuzzel: `fuzzel/fuzzel.ini`, bound `$mod+Space` (sway/scroll/niri); Hyprland: rofi `Super+D` |
| terminal | `kitty/kitty.conf`; `$term` in sway/scroll, `hypr/UserConfigs/01-UserDefaults.conf` |
| theme/colors | GTK `gtk-3.0/settings.ini`, dconf `org/gnome/desktop/interface`; WM borders `sway/config:68-70`, `scroll/config:113-115`; Hyprland colors from `hypr/wallust/wallust-hyprland.conf`; shell/tmux/nvim base16 via `color.scheme`+tinty (broken) |
| lockscreen / idle | sway: `sway/config:21,35-38` → `sway/lock.sh` → hyprlock w/ `sway/hyprlock.conf`; scroll: `scroll/config:47-50,193` (swaylock); Hyprland: `hypr/hypridle.conf`, `hypr/hyprlock.conf` |
| monitors | sway `sway/config:26-30`; scroll `scroll/config:30-45`; Hyprland `hypr/monitors.conf` (nwg-displays); niri `niri/config.kdl:78` (disabled) |
| autostart | sway `sway/config:41-47`; scroll `scroll/config:76-89`; Hyprland `hypr/configs/Startup_Apps.conf`+`UserConfigs/Startup_Apps.conf`; niri `config.kdl:271` |
| default apps | `mimeapps.list`; WM vars `$term/$menu/$filemanager/$browser` (sway:15-20) |
| clipboard | `sway/clipboard.sh` (cliphist + fuzzel/rofi); watchers `sway/config:46-47`, `scroll/config:88-89`; binds `$mod+Shift+v` / `+Ctrl+v` / `+Ctrl+Shift+v` |
| input (kbd us,cz / touchpad) | sway `:52-67`, scroll `:53-69` and `:92-108` (dup) |
| services enabled | `recreate-environment.sh:198-221` |

## Files in this KB
shell.md · wm-sway.md · wm-scroll.md · wm-hyprland.md · wm-niri.md · waybar.md · terminal-editor.md · theming.md · bootstrap.md · apps.md · guides.md · ISSUES.md · SENSITIVE.md
