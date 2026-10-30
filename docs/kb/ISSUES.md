# Issues found (2026-10-30; line numbers after main-agent batch 1). Severity: H = breaks something now / on fresh install, M = wrong/surprising, L = cosmetic/cleanup.

## Bootstrap / repo hygiene
| # | sev | where | problem |
|---|---|---|---|
| B1 | H | `recreate-environment.sh:153-168` | Exclude list is only `guides .git` ⇒ symlinks `docs/`, `testenv/` (550 MB), `Signal/`, `Bitwarden/`, `mozilla/`, `gh/`, … into `~/.config`, replacing a fresh install's app state with the repo copy (and backing the new one up). Needs an allowlist or exclude of untracked/state dirs. |
| B2 | H | `packages` | No sway, sway-scroll, swayidle, swaylock, hyprland, hyprlock, hypridle, waybar, mako, fuzzel, grim, slurp, brightnessctl, playerctl, swaync, wallust, awww, tinty, thunar, zoxide, lazygit, tailscale. Fresh install gets GNOME only; WM configs reference missing binaries. |
| B3 | H | `packages` (~65 `lib32-*`), `failed-packages.log` | multilib not enabled by script ⇒ batch install fails ⇒ slow per-package fallback. `packages` is full `-Qq` (deps included, all marked explicit). Non-package line `packages:1033` `Internationalized` (filtered by script). |
| B4 | H | `recreate-environment.sh:184-190` | `--fix-home-paths` seds every non-binary file under repo, incl. Signal/Bitwarden/mozilla LevelDB `.log`/IndexedDB text files ⇒ can corrupt app state; also dirties tracked files. `--exclude=dconf/user` is ineffective (`--exclude` matches basenames). |
| B5 | M | `recreate-environment.sh:118-119` | Truncates and rewrites `failed-packages.log` inside the repo. |
| B6 | L | `recreate-environment.sh:255` | Says `lua/lazy-lock.json`; file is `nvim/lazy-lock.json`. |
| B7 | M | `recreate-environment.sh:83-84` | Adds arch-mact2 repo with `SigLevel = Never` (unsigned). Same in `after-install.sh:8`. |
| B8 | H | `after-install.sh:32,35` | `[[ $USR_SHELL -eq "bash" ]]` numeric compare on strings ⇒ always true. |
| B9 | H | `after-install.sh:5-8` | Single-quoted string with literal `\` continuations ⇒ writes malformed `[arch-mact2]` block to pacman.conf. |
| B10 | M | `after-install.sh:24,29-30` | Unconditional `refind-install`; clones LazyVim starter over `~/.config/nvim`; tpm cloned into `tmux/plugins` instead of `tmux/plugins/tpm`. No shebang (`:1`). |
| B11 | M | repo root | No `.gitignore`; ~45 untracked paths incl. secrets (SENSITIVE.md). |
| B12 | M | `sway/config:21` (tracked) | Depends on untracked `sway/lock.sh` + `sway/hyprlock.conf`; committing config alone breaks locking on clone. Same for `waybar/config` (untracked) shadowing tracked `config.jsonc`, and waybar → untracked `hypr/` scripts. |

## Shell
| # | sev | where | problem |
|---|---|---|---|
| S1 | H | `scripts/paint.sh:15,17` | Runs `tinty apply $COLOR` on every interactive shell; tinty not installed ⇒ "command not found" each shell. `color.scheme` empty ⇒ arg empty. `paint()` writes new target but exports the old `$COLOR` (`:10-11`). |
| S2 | M | `bashrc:18` vs `scripts/idf.sh:2-6` vs `scripts/esp-ctx.sh:61` | Three different `IDF_TOOLS_PATH`s (v5.1, v6.0, /opt/esp/tools). `idf.sh:4` `[ -n $IDF_TOOLS_PATH ]` unquoted ⇒ always true ⇒ always overrides. Live machine already archived idf*.sh and commented that line (repo is stale). |
| S3 | M | `bashrc:23`, `scripts/completion-fzf.sh`, `scripts/fzf.ac` | fzf keybindings/completion loaded 3× (two different upstream versions). |
| S4 | L | `scripts/warp.ac`, `scripts/completion-cloudflare.sh` | Duplicate 250 KB warp-cli completions; plus spotify-player 64 KB ⇒ slow shell start. |
| S5 | M | `bashrc:36` | Hardcoded `/home/m/.cargo/bin:/home/m/.local/bin`, appended (system binaries shadow user ones). |
| S6 | M | `bashrc:17` | `SSH_AUTH_SOCK` points to systemd-user ssh-agent socket; unit not in repo ⇒ dead socket on fresh install. Live bashrc overrides to `~/.bitwarden-ssh-agent.sock` (not in repo). |
| S7 | L | `bashrc:39-46` | `for SCRIPT in $(ls …)` unquoted; sources any file type, including non-shell. |
| S8 | L | `scripts/alias.sh:5-6` | Writes to `~/.config/states/` (missing dir) ⇒ alias fails after connect. `:1` hardcoded `/home/m/code/tlp-switcher2`. |
| S9 | L | `scripts/torrent.sh:2` | Sets global `BROWSER=firefox` in every shell. |
| S10 | L | `scripts/since.sh:19-31` | Debug echoes; wrong arithmetic for negative day diff. `scripts/backup.sh`, `idf2.sh` fully commented (dead). |

## WMs
| # | sev | where | problem |
|---|---|---|---|
| W1 | H | `scroll/config:48,50,193` | `swaylock --fingerprint` — unsupported by installed swaylock 1.8.6 ⇒ idle/before-sleep/manual lock all fail on scroll. |
| W2 | H | `scroll/config:599,602` | `$(date+\'…\')` missing space ⇒ `date+: command not found`, file saved as `.png`. |
| W3 | M | `scroll/config:53-69` vs `:92-108` | Duplicate input blocks (uncommitted add); natural_scroll enabled then disabled — later wins. |
| W4 | M | `scroll/config:81,125` | `lxqt-policykit-agent` not installed ⇒ no polkit agent under scroll (sway uses polkit-gnome). |
| W5 | L | `scroll/config.d/50-systemd-user.conf` vs `scroll/config:644` | Repo copy never included (config includes `/etc/scroll/config.d/*`). |
| W6 | M | `sway/config:41-47`, `scroll/config:76-89` | No notification daemon started; mako not installed ⇒ notify-send (volume/brightness/battery/screenshot) goes nowhere. |
| W7 | L | `sway/config:63-64`, `scroll/config:65-66` | Layout `us,cz` without any `grp:` toggle option ⇒ cz unreachable by key. |
| W8 | M | `hypr/hyprlock.conf:1-15` | Sources `~/.config/hyprlock/{colors.conf,layouts/layout11.conf,scripts/*}` — dir not in repo ⇒ Hyprland lock broken on fresh install. |
| W9 | M | `hypr/configs/Startup_Apps.conf:11,22,23,28,49` | awww, swaync, quickshell not installed; `nm-tray` (Ubuntu) also launched; `qs -c overview` launched twice. |
| W10 | L | `hypr/configs/Keybinds.conf:12` + `hypr/hyprland.conf:38` | `01-UserDefaults.conf` sourced twice. |
| W11 | L | `hypr/monitors.conf:3` vs `sway/config:26-30` | eDP-1 1920x1200 scale 1 (Hyprland) vs 1920x1080 scale 1.25 (sway/scroll) — one is from another machine. |
| W12 | L | `niri/config.kdl:91` | (disabled block) eDP-1 scale 0.5. niri itself not installed. |
| W13 | M | refs from hypr/, waybar/ | Missing config dirs: rofi, swaync, wlogout, hyprlock, wallust, qt5ct, qt6ct, ghostty, cava, ags, states. |

## Bar / apps
| # | sev | where | problem |
|---|---|---|---|
| A1 | H | `waybar/config` vs `waybar/config.jsonc` | `config` (Hyprland modules, untracked) takes precedence ⇒ under sway/scroll hyprland/* modules are dead; tracked sway bar config never loads. (Lookup order per Waybar defaults — confirm with `waybar -l debug`.) |
| A2 | M | `waybar/config.jsonc:233-235` | (only matters if config.jsonc is ever loaded) clipboard module runs `scrollmsg exec '$clipboard'` — `$clipboard*` vars not defined in scroll config. Effective `waybar/ModulesCustom:20-26` now uses `sway/clipboard.sh` (batch 1). |
| A3 | L | `waybar/scripts/wg-status.sh:5`, `wg-update.sh:5` | Named WireGuard but checks `tailscale0`; `>/dev/null 1>&0` redirect is nonsense (stdout→stdin). |
| A4 | M | `waybar/scripts/claude-usage.sh:3` | Reads `~/.claude/.credentials.json` OAuth token; writes cache to world-readable `/tmp`. |
| A5 | M | `yazi/yazi.toml:13` | Default folder opener uses `hyprctl` + nemo — fails outside Hyprland, nemo not installed. |
| A6 | M | `nvim/lua/config/keymaps.lua:13` | `<leader>n` → `NvimTreeToggle`; nvim-tree not installed. |
| A7 | L | `nvim/lua/config/keymaps.lua:21` vs `nvim/lua/plugins/git.lua:72,88` | `<leader>gr` mapped twice (LSP refs vs gitsigns reset). keymaps loaded before LazyVim, which also maps `gr`. |
| A8 | L | `nvim/lazy.lua` | Unused file. `nvim/lua/plugins/ui.lua` empty. |
| A9 | M | `nvim/undodir/` (11 tracked files) | Undo histories of personal files committed (content leak); config uses `~/.local/share/nvim/undodir` anyway. |
| A10 | L | `mimeapps.list:18` | `application/x-bittorrent=torrent` — invalid desktop id, missing `;`. |
| A11 | L | `gtk-3.0/bookmarks`, `lsp-plugins/bookmarks.json`, `yazi/keymap.toml:39-56`, `user-dirs.dirs` | Three dir naming schemes (lowercase / Czech / English XDG). `user-dirs.dirs` not deployed. |
| A12 | L | `gtk-3.0/settings.ini:13,16`, `gtk-4.0/settings.ini` | Breeze/light + KDE gtk-modules vs dconf Adwaita/prefer-dark/Qogir — conflicting themes. |
| A13 | L | `mako/config.critical` | Not referenced anywhere. |

## Stale backups / experiments (safe-to-delete candidates; ask user)
- `sway/config.bak-20261021-225659` ≡ `sway/config.bak-20261021-230603` (identical; = HEAD sway/config which was an old scroll config).
- `sway/config.broken-230202` — failed scroll→sway port.
- `scroll/config.bak-20261021-225659` ≡ current `scroll/config`.
- `hypr/hyprlock.conf.bk` ≡ `hypr/hyprlock-2k.conf`.
- `hypr/scripts/ScreenShot.sh.bk`, `hypr/scripts/Volume.sh.bk`, `hypr/UserScripts/RainbowBorders.bak.sh`, lowercase case-duplicate scripts in `hypr/scripts/`, `hypr/configs/{keybinds,startup,variables,window_rules,animations}.conf`, `WindowRules-pre-53.conf`, `WindowRules-config-v3.conf`.
- `hypr/v2.3.18`, `hypr/v2.3.20` (old version markers; current `v2.3.25`).
- `hypr/hyprland.lua.disable` + `hypr/lua/` (Lua experiment, disabled).
- `scripts/archive/`, `scripts/idf.sh`, `scripts/idf2.sh`, `scripts/backup.sh`.

## Drift repo ↔ live (D1)
Live `~/.config/*` are real dirs (not symlinks). Differences at snapshot: `~/.bashrc` (SSH_AUTH_SOCK bitwarden, IDF line commented); `~/.config/scripts` lacks `idf.sh`, `idf2.sh`. sway/, scroll/config, waybar/, hypr/ were identical before main-agent batch 1; repo is now ahead for bashrc, sway/, scroll/config, waybar/, rofi/, packages.
