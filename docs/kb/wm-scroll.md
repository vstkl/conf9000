# scroll (sway fork with scrolling/column layout; host pkg `sway-scroll` 1.12.21, binary `scroll`, IPC `scrollmsg`)

## Files
| file | status |
|---|---|
| `scroll/config` (644 l, tracked, uncommitted edits) | **ACTIVE** (live copy == pre-batch-1 version; repo now ahead) |
| `scroll/config.bak-20261021-225659` | byte-identical to the pre-batch-1 config → redundant |
| `scroll/config.d/50-systemd-user.conf` (tracked) | **UNUSED**: config includes `/etc/scroll/config.d/*` (`:644`), not this dir. Same content as the /etc copy (sets XDG_CURRENT_DESKTOP=scroll, imports SCROLLSOCK/WAYLAND_DISPLAY) |

## scroll/config structure
- `:10-23` vars same as sway (`$term kitty`, `$menu fuzzel`, nautilus, firefox). No `$lock` var.
- `:29` wallpaper commented. `:32-33` external monitors commented (DP-5 was active in HEAD). `:37-45` eDP-1 1920x1080@59.999, pos 0,1080 (expects a monitor above), scale 1.25, scale_filter smart.
- `:47-50` swayidle → `swaylock --fingerprint` (flag unsupported by installed swaylock 1.8.6 → lock fails).
- `:53-69` input block #1 (natural_scroll **enabled**) — added uncommitted; `:92-108` input block #2 (natural_scroll **disabled**) — later wins.
- `:76-89` autostart: bitwarden-desktop, easyeffects -w, warp-taskbar, lxqt-policykit-agent (not installed on host), mako/battery.sh, `waybar -b 1`, cliphist watchers (`:88-89`, batch 1).
- `:114-128` borders/gaps/colors as sway; float lxqt-policykit-agent, `bt-menu`.
- `:129-164` scroll-specific: layout_default_width 0.5, widths/heights presets, cursor_shake_magnify, animations block.
- `:644` include `/etc/scroll/config.d/*`.

## Keybinds ($mod = Super) — scroll-specific beyond sway set
Shift+v / Ctrl+v / Ctrl+Shift+v clipboard (`sway/clipboard.sh`, `:176-178`) · Shift+Backspace kill unfocused · Ctrl+Backspace kill all · Ctrl+q swaylock · o/i opacity ± · `[`/`]` set_mode h/v · Home/End focus beginning/end · Alt+hjkl move nomode · Shift+comma/period scale_workspace ± (also Shift+wheel) · Tab / mouse button8 overview · `/` jump (Shift container, Ctrl workspaces, Alt floating) · comma/period scale_content ± · Alt+f fullscreen_application · Shift+y layout_transpose · a / Shift+a pin beginning/end · Insert selection ops · Alt+z scratchpad jump · backslash mode "modifiers" · minus/equal cycle_size · b/Shift+b setsize modes · t/Shift+t toggle_size · Ctrl+t/Ctrl+Shift+t togglesize modes · c align mode · w fit_size mode · `;`/Shift+`;` trailmark/trail modes · g spaces mode (save/load/restore layouts) · Ctrl+s full screenshot / Shift+Ctrl+s region → `~/Pictures/Screenshots/` + wl-copy (both broken: `$(date+…)` missing space, `:599,602`) · swipe 4 up → overview.
No `$mod+Shift+s` screenshot here (sway has it).

## Differences vs sway/config (for porting)
sway uses hyprlock via lock.sh, polkit-gnome, `[workspace=__focused__] kill`, layout stacking/tabbed; scroll uses swaylock --fingerprint, lxqt-policykit-agent, extra autostarts (bitwarden, easyeffects, warp-taskbar), brightness step 10% vs 5%.
