# conf9000 — state & progress log

Living log for the conf9000 effort. Every agent working on this repo appends to
**Progress log** (newest at the bottom) with date, who, what, and outcome.
Knowledge base for agents: `docs/kb/` (start at `docs/kb/INDEX.md`).
Test environment: `testenv/` (start at `testenv/README.md`).

## Initial state (snapshot 2026-10-30, before any agent work)

**Repo**: `~/junk/conf9000` → `github.com/vstkl/conf9000`, branch `live` (main branch: `main`),
32 commits, last `ec8a687 added refind wihtout submodule`. ~713 MB on disk.
It is a copy/clone of the user's `~/.config` plus install scripts.

**Purpose (README)**: "9000th attempt to configure my linux right." `guides/` holds
how-to notes/scripts (ssh-agent, network audio, package proxy, TLS cert generation).

**Host**: Arch Linux, kernel 7.2.7-arch1-1. Tooling present: qemu-system-x86_64,
virt-install, pacstrap, arch-chroot, systemd-nspawn. `sudo` requires a password
(agents cannot do root steps unattended).

**Install/bootstrap scripts**
- `recreate-environment.sh` (untracked) — main bootstrap after `archinstall`:
  installs from `packages`, symlinks dotfiles into `$HOME` with backup,
  opt-in `--install-bootloader` (rEFInd), `--fix-home-paths` (rewrites `/home/m`).
- `after-install.sh` — older bootstrap: Apple T2 detection + `arch-mact2` repo,
  builds paru, installs GNOME/kitty/tmux/neovim/refind, LazyVim starter, tpm.
  Has a bug: `[[ $USR_SHELL -eq "bash" ]]` uses numeric compare on strings.
- `install_optdeps.sh`, `packages` (1476 package names), `failed-packages.log`
  (~90 packages that failed: lib32-*, linux-t2, AUR-only items, etc.).

**Shell**: bash. `bashrc` sets aliases (ls/ll/llo/grep), plain `PS1`, fzf bash
integration, `MANPAGER=nvim`, nvm, gem/cargo/.local PATH (hardcoded `/home/m`),
ESP-IDF path, then **sources every file in `~/.config/scripts/`** (aliases,
completions, idf, helpers — including non-shell `.ac` files).

**Desktop / WM configs**: sway, scroll (sway fork), hypr (Hyprland, large
JaKooLit-style tree incl. lua experiment), niri, waybar (many module files),
mako, fuzzel, kitty, tmux (+tpm submodule), nvim, yazi, gtk-2/3/4, lxqt, dconf,
refind. Several stray backups: `sway/config.bak-*`, `sway/config.broken-230202`,
`scroll/config.bak-*`, `hypr/hyprlock.conf.bk`.

**App state dirs (likely sensitive, untracked)**: Bitwarden, Signal, gh,
github-copilot, evolution, mozilla, pulse, ibus, wireshark, libreoffice, etc.
These may contain tokens/keys and must not be committed or copied into test images.

**Working tree**: uncommitted modifications to `dconf/user`, `mimeapps.list`,
`scripts/alias.sh`, `scroll/config`, `sway/config` (−~450 lines), `waybar/style.css`;
~45 untracked paths (see `git status`).

## Plan
1. Knowledge base for agents (`docs/kb/`) — subagent A.
2. Reproducible test environment (VM / chroot) in `testenv/` — subagent B.
3. Next: user-provided list of change instructions (e.g. shell behaviour),
   each tested in the test env before touching the real machine.

## Progress log

- 2026-10-30 — main agent: captured initial state (this file). Launched
  subagent A (knowledge base) and subagent B (test environment) in parallel.
- 2026-10-30 — main agent: **change batch 1** (user requests 1–3), edited in repo only
  (repo is NOT symlinked into the live ~/.config, so the real system is untouched).
  - Bluetooth: `waybar/Modules` bluetooth module gains right-click → floating
    `bluetui` (`waybar/scripts/bluetooth.sh menu`, kitty `--class bt-menu`) and
    middle-click → power toggle; left-click still blueman-manager. Float rule
    `for_window [app_id="bt-menu"]` added to sway + scroll. Network module untouched.
  - Clipboard: root cause = no `wl-paste --watch cliphist store` in sway/scroll
    (only hypr had it), `cliphist` missing from `packages`, waybar button called
    hypr's rofi script with no rofi config in repo. Fix: watchers added to sway +
    scroll, new `sway/clipboard.sh` (fuzzel default, `rofi`, `delete`, `wipe`),
    binds `$mod+Shift+v` / `$mod+Ctrl+v` / `$mod+Ctrl+Shift+v`, rofi variants kept
    commented in sway/scroll; new `rofi/config.rasi` + `rofi/config-clipboard.rasi`;
    waybar clipboard: left = fuzzel, right = rofi.
  - Shell: `bashrc` PS1 replaced by `__prompt` (PROMPT_COMMAND) using git's
    git-prompt.sh — colored user@host path, git branch + `*+%$` state + upstream,
    red ✗<code> on failure, `❯` on second line.
  - `packages`: + bluetui, + cliphist (both in extra).
  - Host checks: `sway -C` on sway/config passes; prompt renders as
    `m@host ~/junk/conf9000 (live *%=)` / `❯`. shellcheck not installed on host.
  - Found: `packages` line 1031 contains `Internationalized` (not a package).
  - Pending: run in the VM (sync → bootstrap minimal → check) once testenv is ready.
- 2026-10-30 — KB subagent: built `docs/kb/` (read-only survey; line numbers re-synced to
  the tree after main-agent change batch 1). Files: `INDEX.md` (entry point, $HOME mapping,
  where-to-change table), `shell.md`, `wm-sway.md`, `wm-scroll.md`, `wm-hyprland.md`,
  `wm-niri.md`, `waybar.md` (+mako, fuzzel, rofi), `terminal-editor.md` (kitty, tmux,
  nvim, yazi), `theming.md` (gtk, dconf, base16/tinty, wallust, mimeapps, XDG dirs),
  `bootstrap.md`, `apps.md`, `guides.md`, `ISSUES.md` (~45 items), `SENSITIVE.md`
  (+ recommended .gitignore). Top 5 issues:
  1. `recreate-environment.sh:153-168` links EVERY top-level dir (Signal, Bitwarden,
     mozilla, docs, testenv…) into ~/.config; `--fix-home-paths` (`:184-190`) seds
     app-state text files too.
  2. `packages` lacks sway/scroll/hyprland/waybar/mako/fuzzel/swayidle/swaylock/grim…;
     ~65 lib32-* fail (multilib not enabled).
  3. `scroll/config:48,50,193` `swaylock --fingerprint` unsupported by swaylock 1.8.6 →
     scroll never locks; `scroll/config:599,602` `$(date+…)` breaks screenshots.
  4. `waybar/config` (untracked, Hyprland modules) shadows tracked `config.jsonc`; waybar
     depends on untracked `hypr/` scripts. mako not installed → no notifications on sway.
  5. `scripts/paint.sh:15,17` runs `tinty apply` (not installed) in every shell; three
     conflicting IDF_TOOLS_PATH (bashrc:18, scripts/idf.sh, scripts/esp-ctx.sh).
- 2026-10-30 — testenv subagent: **built `testenv/`**, a rootless QEMU/KVM VM based on the
  official Arch cloud image (SHA256-verified). It uses a cloud-init NoCloud seed (user `m`,
  passwordless sudo, VM-only ssh key), a disposable qcow2 overlay plus named snapshots, and
  ssh on 127.0.0.1:2222. GUI mode is optional. No sudo and no libvirt are needed. There is
  also an optional `nspawn-alternative.sh`, which needs sudo; the user runs it, not the agents.
  Usage: `cd testenv && ./setup.sh && ./start.sh` | `./sync.sh && ./run-bootstrap.sh && ./check.sh` |
  `./stop.sh`, `./reset.sh` (back to clean). See `testenv/README.md`.
  `sync-exclude.txt` keeps secrets and app state out of the VM (needed because the bootstrap
  links every dir), and sync uses `--delete --delete-excluded` plus a leak check.
  Verified on a clean reset: boot OK, sync OK, minimal bootstrap exit 0, check.sh
  287 pass / 16 fail / 42 warn. Batch 1 results:
  - Pass: prompt (branch in repo, none outside, ✗code), sway -C, scroll -C, headless sway
    started the cliphist watcher from the config and wl-copy appeared in cliphist, all waybar
    Modules* files are valid JSONC, and clipboard.sh and bluetooth.sh are clean under
    bash -n and shellcheck.
  - Fail: `bash -ic` stderr (paint.sh → tinty missing, color.scheme not deployed),
    Hyprland 0.57 rejects hyprland.conf (parsed as Lua), waybar configs SummitSplit(-glass)
    invalid JSONC, shellcheck errors in scripts/idf.sh, scripts/since.sh and 8 hypr/scripts.
  - Warn: `bluetooth.sh toggle` hangs with no bluetoothd/adapter (`bluetoothctl` waits forever).
  The VM is left stopped.
- 2026-10-30 — main agent: fixed `bluetooth.sh toggle` hang found by testenv run
  (bluetoothctl blocks forever without an adapter). Now `timeout 3 bluetoothctl show`,
  exits 1 + notify-send "No adapter found" when no Controller. Verified in VM:
  returns rc=1 after 3 s, shellcheck clean. VM stopped. **Batch 1 fully verified in VM**
  (prompt, sway/scroll -C, cliphist round-trip, waybar JSONC, scripts). Not yet applied
  to the live ~/.config — awaiting user approval.
- 2026-10-30 — main agent: **virt-manager access** to the test VM. New `testenv/virt-manager.sh`
  (libvirt `qemu:///session`, passt ssh forward 2222, spice display, optional `--gl` virgl).
  First boot had no guest network: libvirt's random MAC didn't match cloud-init's MAC-pinned
  config → pinned MAC 52:54:00:12:34:56 (raw QEMU default); ssh now works. `lib.sh` split
  `vm_running` into `qemu_running` + `libvirt_running`, so ssh/sync/check/bootstrap work with
  both; start.sh/stop.sh/reset.sh refuse/redirect when the other flavour holds the disk.
  The user's manually started raw-QEMU VM was stopped by the script before libvirt booted.
  Verified: console login shows the new prompt; sway, waybar, bluetui, cliphist, fuzzel present.
  Noted: interactive login prints `tinty: command not found` (scripts/paint.sh, known issue).
- 2026-10-30 — main agent: user reports VM GUI missing icons + no nmtui (virt-manager issue was
  the user's missing user-session connection, not the VM).
  - Icons: waybar style asks for "JetBrainsMono Nerd Font", which is NOT installed on the real
    machine either (fc-match → Noto Sans Mono); real icons come from ttf-nerd-fonts-symbols
    fallback. VM lacked it. Installed in VM: ttf-nerd-fonts-symbols, noto-fonts,
    noto-fonts-emoji, adwaita-fonts (fuzzel uses Adwaita Mono). Candidate fix for the repo:
    add ttf-jetbrains-mono-nerd to `packages` or change waybar font-family — not done yet.
  - nmtui: installed networkmanager in VM; NetworkManager now owns eth0 (systemd-networkd
    masked — it is socket-activated by 4 units, plain disable didn't stick), rebooted, ssh OK.
  - `testenv/run-bootstrap.sh` minimal set + NM handoff (mask networkd, enable NM, reboot)
    updated so a reset VM gets the same result.
- 2026-10-30 — main agent: **change batch 2** (user: bluetui doesn't work, nmtui too big / blue,
  add mono nerd font). Verified in the libvirt VM with screenshots of the user's sway session.
  - bluetui "didn't work" because the VM has no adapter → bluetooth.service never starts →
    bluetui exits → kitty window flashes shut. Fixes: `bluetooth.sh menu` now keeps the window
    open with the reason if bluetui fails; new `testenv/vm-bluetooth.sh` (+ `vm/vbt.py`) gives
    the VM a virtual adapter (bumble on /dev/vhci, `vbt.service`). bluetui now shows hci0, On.
  - New `waybar/scripts/network.sh menu`: floating kitty `nm-menu`, 42x17 cells, nmtui with
    `NEWT_COLORS` (terminal default bg, cyan highlight — no blue). waybar `network` module
    gets `on-click-right` (waybar/config). bt menu sized 64x17 cells. Both: opaque
    background, padding 2, `remember_window_size=no`.
  - sway + scroll: `for_window` rules for bt-menu and nm-menu are now float + center only (the
    size comes from kitty, the old `resize set 760 480` was removed).
  - `packages`: + ttf-jetbrains-mono-nerd (the font waybar/style.css asks for; it wasn't
    installed anywhere). Installed in the VM; fc-match resolves it. Also in the minimal VM set.
  - Checks in VM: shellcheck on both scripts, `sway -C` OK.
- 2026-10-30 — main agent: **change batch 3** (user: menus should drop down from waybar like the
  calendar, no animation; q closes both menus). Verified in the libvirt VM (screenshots + wtype).
  - New `waybar/scripts/dropdown.sh APP_ID COLS ROWS [kitty -o...] -- CMD`: kitty in waybar's
    tooltip colors (bg #0F1419, fg #F3F4F5, purple #D2A6FF as color13), no padding, opaque;
    top aligned to the bar's bottom edge (focused workspace rect.y + 2), centered on the clicked
    icon, clamped to the screen edge; clicking the icon again closes it. `--resize` lets the
    app inside change size while staying anchored. sway/scroll `for_window`: float, `border
    none`, `move position cursor, move down 42 px` (no visible jump). Note: sway `move position`
    is relative to the usable area -> the script uses `move absolute position`.
  - nmtui lays out a screen only once, for the size it has at that moment (resize and Ctrl+L
    don't relayout), so `network.sh` shows nmtui's main menu itself via whiptail (same libnewt,
    same NEWT_COLORS; frame/title in tooltip purple, no blue) at 28x14, grows the window to
    62x22 *before* running `nmtui edit|connect|hostname|radio`, and shrinks back on return.
  - q: bluetui quits on q natively. nmtui gets `map q kitten menu_q.py` (`kitty/menu_q.py`):
    closes on screens without a text field (main menu, lists with <Back>/<Quit>/<Activate>),
    types a literal q where there is one (password, profile name, hostname).
  - Tested: placement 253x281 at y=42 under the bar; Activate screen 558x440 fully visible;
    Esc -> back to small menu; q closes from the main menu and the Activate screen; bt-menu
    577x341 clamped to the right edge, q closes; no leftover processes; sway -C / scroll -C
    (headless) OK; shellcheck clean.
  - Incident: during keystroke tests the user's own kitty terminal in the VM sway session closed.
    Cause unknown: the user says they may have closed it themselves while clicking around;
    stray synthetic keys are the other possibility. Test harness now focuses the target window
    explicitly and aborts if it isn't focused.
- 2026-10-30 — main agent: **waybar tooltip covered the dropdown** (hover tooltip of the clicked
  icon appears under the bar, on top of the menu). Options given to the user: (1) move the pointer
  into the menu when it opens, (2) `"tooltip": false` on network/bluetooth, (3) hide the tooltip
  only while open (needs a waybar reload, flickers), (4) Hyprland integration (doesn't fix it, the
  tooltip is waybar's). Implemented (1): `dropdown.sh` puts the pointer 12px inside the top of the
  menu right after placing it (once, not on --resize). Verified in VM: tooltip shown before the
  click is gone with the menu open, for nm-menu and bt-menu. Also: whiptail menu shows only
  <Select> (`--nocancel`). Hyprland support for the dropdown not done (offered separately).
- 2026-10-30 — main agent: user chose option 2: **tooltips off** for the network
  (`waybar/config`) and bluetooth (`waybar/Modules`) modules (`"tooltip": false`). The pointer
  warp from option 1 is removed from `dropdown.sh`, so the pointer never moves. Verified in VM:
  waybar loads config + all includes with no errors; hovering either icon shows no tooltip;
  the nmtui dropdown opens with the pointer still on the icon and nothing covering it.
- 2026-10-30 — main agent: **notifications: mako and swaync side by side** for the user to try.
  Found: no notification daemon was installed at all; waybar's workspace/window modules are
  `hyprland/*`, so they show nothing on sway/scroll (workspace task pending the user's choice).
  - `sway/notify.sh`: `start` (autostart in sway + scroll config, starts the daemon chosen last,
    default mako; state in ~/.local/state/conf9000/notify-daemon), `use mako|swaync` (switch
    live), `which`, `panel`, `dnd`, `clear`, `status` (waybar JSON; same alt states for both).
  - waybar `custom/notification` bell (ModulesCustom, added before custom/claude in
    modules-right): left = panel (swaync center / mako restore last), right = DND, middle =
    clear all; count shown only when > 0.
  - mako/config: tooltip theme (bg #0F1419, fg #F3F4F5, 1px #D2A6FF, radius 10, JetBrainsMono
    Nerd Font) + `[mode=do-not-disturb] invisible=1`; existing rules kept.
  - New `swaync/` (config.json + style.css importing the packaged theme, recolored the same
    way; popups top-center like mako, center panel top-right under the bar; transition-time 0
    = no animation; critical framed red; rules: category bat -> critical, volume/brightness
    transient). mako/volume.sh + brightness.sh send `x-canonical-private-synchronous` so a new
    value replaces the old popup (swaync honors it, mako ignores it).
  - `packages`: + mako, + swaync. testenv minimal set: + mako swaync libnotify. In the running VM
    `~/.config/swaync` was linked by hand (the bootstrap links new top-level dirs on its next run).
  - Verified in VM (screenshots): mako popups + red critical, bell count; swaync popups, panel
    with Clear all / DND, red critical; DND on/off and clear-all via notify.sh for both daemons;
    sway -C / scroll -C OK; waybar loads with no warnings; shellcheck clean.
  - Left for the user to try: swaync active, notifications cleared.
- 2026-10-30 — main agent: **swaync only** (user's choice): sway/scroll `exec swaync`; waybar bell
  calls swaync-client directly (`restart-interval` 1); `sway/notify.sh` deleted; mako removed from
  `packages` (mako/ kept for volume/brightness/battery scripts; its config is now unused).
- 2026-10-30 — main agent: **unified base16 theming with tinty** (tinted-theming), default
  `base16-ayu-dark` (the palette waybar/tmux already used).
  - `tinted-theming/tinty/config.toml` items + reload hooks: shell (tinted-shell), fzf (tinted-fzf),
    kitty (tinted-terminal themes/kitty; SIGUSR1), tmux (tinted-tmux; source-file), waybar
    (base16-waybar -> ~/.config/waybar/colors.css; SIGUSR2), and local templates in
    `tinted-theming/conf9000-templates` (built by `tinty build`, output gitignored) for sway/scroll
    (client.* colors; reload), swaync (CSS vars -> ~/.config/swaync/colors.css; `-rs`), fuzzel.
    Theme files: ~/.local/share/tinted-theming/tinty/artifacts/<name>-<dir>-file.*.
  - Configs: kitty.conf include; tmux.conf source-file (old base16-tmux plugin + @colors-base16
    removed); sway/scroll include after fallback client.* lines; fuzzel.ini include= ([colors]
    values commented); waybar/style.css `@import "colors.css"` and 22 hex colors -> @base00..0F
    (77 uses); swaync/style.css uses var(--baseXX); dropdown.sh no longer hardcodes colors
    (kitty theme); nvim base.lua reads tinty `current_scheme` + FocusGained re-check (tinted-vim).
  - bash: `scripts/paint.sh` rewritten (old one ran `tinty apply` in every shell -> the
    "tinty: command not found" error): sources shell + fzf theme files, `theme [scheme]` (fzf
    picker); bashrc enables tinty completion when installed; stale BASE16_THEME comments removed.
  - `recreate-environment.sh`: new `apply_theme` step (tinty install, build local templates,
    apply current or ayu-dark). `packages` + tinty-git (only AUR option; cargo build ~10 min).
    `.gitignore`: waybar/colors.css, swaync/colors.css.
  - Verified in VM: tinty 0.35.0 install/build (361 schemes)/apply; all 8 artifacts written;
    ayu-dark and gruvbox-dark switch live: kitty (incl. already-open windows), sway border,
    waybar, tmux status, swaync popups, fuzzel; nvim colors_name follows (base16-gruvbox-dark);
    sway -C / scroll -C OK; new shells start without tinty errors; shellcheck clean. VM left on
    ayu-dark.
  - Notes: killing waybar (not SIGUSR2 reload) orphans the bell's swaync-client pipeline;
    theme reloads don't. nvim first-run errors in the VM (mason race, Copilot without node) are
    unrelated to theming. `color.scheme` (repo root) is now unused.
- 2026-10-30 — main agent: **more tinty integrations + Tab completion fixes.**
  - New tinty items: rofi (base16-rofi `colors`, imported by rofi/config.rasi, which now maps
    bg/fg/accent/urgent to @background/@foreground/@blue/@red), yazi (tinted-yazi flavor ->
    ~/.config/yazi/flavors/tinted-scheme.yazi/flavor.toml, gitignored; theme.toml selects it),
    Claude Code (tinted-claude-code static JSON -> ~/.claude/themes/tinty.json; select "tinty"
    once in /theme, it hot-reloads after that), bat (`BAT_THEME=base16` = terminal palette).
    Verified: all 11 artifacts written; rofi -dump-theme shows ayu colors; Claude theme "Ayu Dark".
  - `theme` completion: `complete -F _theme_complete theme`, names read from tinty's scheme
    files (361 base16 without prefix, 242 base24 as base24-*); `theme ayu-dark` = base16-ayu-dark.
    Real Tab in tmux: `theme ayu-<Tab><Tab>` -> ayu-dark ayu-light ayu-mirage.
  - git completion: works in fresh shells on the host and in the VM (subcommands, branches,
    flags, files for `git add`) -- fzf 0.74 loads bash-completion on demand. What lists files are
    aliases (bash doesn't complete aliases): new `_complete_alias` at the end of bashrc expands
    simple aliases and hands off to `_comp_command_offset`; `gitlog --on<Tab>` -> --oneline,
    `page bas<Tab>` -> bashrc. Asked the user for the exact git case if one still fails.
  - fzf was loaded 3x (bashrc eval + scripts/completion-fzf.sh + scripts/fzf.ac, copies of fzf's
    own scripts); the copies moved to scripts/archive/ (not sourced). Startup 168 -> 148 ms.
  - testenv/sync.sh rebuilds the local tinty templates after sync (rsync --delete removed the
    gitignored build, which made `tinty apply` fail for all items).
- 2026-10-30 — tmux subagent: **tmux tuned for nvim + helper menu + cheat sheet.**
  - `tmux/tmux.conf`: default-terminal tmux-256color; terminal-features `xterm*:RGB`,
    `xterm-kitty:usstyle` (undercurl), guarded so reloads don't append duplicates (replaces the
    `xterm*:Tc` override); escape-time 10, focus-events on, set-clipboard on, allow-passthrough on
    (image.nvim), history 50000, set-titles. New keys: `P |`/`P -` splits (`"`/`%` kept, now also
    current path), `P H/J/K/L` repeatable resize (was: L = last session), `P Tab` last window
    (`P l` is pane right), `P C-l` clear screen (C-l = navigator), `P </>` move window, `P v` copy
    mode, copy-mode-vi `V` select line, `P r` reload. tpm `run` moved to the end (tmux-yank's
    `y` -> wl-copy now wins), tinty source-file last.
  - Helper menu `P ?` (display-menu; tmux's list-keys is menu item `k`), `P F1` popup with
    `tmux/SHORTCUTS.md` via `tmux/scripts/cheatsheet.sh` (glow -> bat -> less).
    `tmux/.gitignore` ignores tpm-installed plugins except the tpm submodule.
  - nvim: new `nvim/lua/plugins/tmux.lua` (christoomey/vim-tmux-navigator via lazy `keys`, so
    LazyVim's C-h/j/k/l window maps step aside); no conflicts in config/keymaps.lua.
  - Verified in VM (tmux 3.8, private `-L t` servers only): config loads + sources twice without
    errors, options/keys as listed, tpm installs the 3 plugins, menu opened via
    `send-keys -K` on a pty client and its z/| items act, F1 popup shows the sheet, `P r` message,
    repeatable resize; shellcheck clean. nvim: C-h/j/k/l/C-\ map to the navigator.
    Pre-existing, unrelated: nvim headless prints "Too many rounds of missing plugins" with or
    without the new spec. Note: testenv sync.sh `--delete` wipes VM-installed tmux plugins.
- 2026-10-30 — main agent: **Tab completion survey, 40 commands** (real Tab Tab in a private tmux
  pane; harness in the session scratchpad, cases: git (5), systemctl/journalctl/sudo, pacman,
  man, ssh-keygen, kill, cd, tmux, nmcli, bluetoothctl, ip, swaymsg, tar, rsync, curl, chmod,
  which, export, ls, nvim, theme, tinty, gh, kitty, claude, cargo, npm, pip, docker, yazi).
  - Host (current live config): 32/39 pass. Failures: gitlog alias + theme (fixed earlier in
    repo), 2 test-line mistakes (systemctl stops at the common prefix `bluetooth.`, kill uses
    -TERM not -SIGTERM; both pass when re-checked), and 3 tools that ship NO bash completion:
    nvim, claude, bluetoothctl.
  - VM (new config): 31/34 pass + 6 skipped (not installed); `cd ~/.conf` stops at `.config`
    because ~/.config-backup-* exists (correct).
  - Conclusion: no general breakage; completion gaps came from aliases, our own `theme`, and
    tools without completion. New `scripts/completions.sh`: nvim + claude long options via
    bash-completion's `_comp_complete_longopt` (parses --help), bluetoothctl commands/on|off/
    device MACs. Verified: VM nvim/bluetoothctl pass; host (private shell sourcing the file)
    bluetoothctl connect -> MACs, claude --mod -> --model, nvim --hea -> --headless.
  - Started background subagent for tmux (nvim-friendly bindings, tmux/SHORTCUTS.md, in-tmux
    help menu); it appends its own entry.
- 2026-10-30 — main agent: reviewed the tmux subagent's work (spot-checked in VM: config loads
  without errors, prefix ?, F1, |, -, H (repeatable), r present, escape-time 10). Fixed
  testenv/sync.sh so tmux plugins survive a sync: the host repo's tpm submodule was never
  initialized (`git submodule status` shows `-`, folder empty), so rsync --delete wiped tpm and
  the plugins in the VM; sync now runs `git submodule update --init` in the VM and installs
  plugins with tpm against a private tmux server (TMUX_TMPDIR), leaving running sessions alone.
  Verified: after sync, plugins = tpm, tmux-sensible, vim-tmux-navigator, tmux-yank.
  Open question for the user (from the subagent): P L (last session) is now resize-right;
  last session moved to P ( / P ).
