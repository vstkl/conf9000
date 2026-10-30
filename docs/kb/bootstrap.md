# Bootstrap

## recreate-environment.sh (untracked, 262 l) — current, preferred
Run as normal user from repo clone after `archinstall`. `set -uo pipefail` (no `-e`: failures continue).
Flags (`:28-34`): `--skip-packages`, `--skip-dotfiles`, `--install-bootloader` (opt-in rEFInd), `--fix-home-paths`, `-h`. Refuses root (`:49`).
Flow `main()` (`:230-260`):
1. `setup_apple_t2` (`:76`) — always runs `sudo pacman -Sy pciutils`; if Apple PCI vendor 106b: appends `[arch-mact2]` repo **SigLevel=Never** to /etc/pacman.conf, installs linux-t2 etc.
2. `install_paru` (`:59`) — git+base-devel, clone AUR paru, makepkg.
3. `install_packages` (`:97`) — filters `packages` by regex `^[a-z0-9][a-z0-9@._+-]*$` (drops e.g. `Internationalized` at `packages:1033`), `paru -S --needed --noconfirm -`; on failure retries one-by-one and **truncates & rewrites `failed-packages.log` in the repo** (`:118-121`).
4. `git submodule update --init --recursive` (tmux/plugins/tpm).
5. `fix_home_paths` (`:181`, only with flag and `$HOME != /home/m`) — `grep -rl /home/m` over the whole repo (excl. .git, undodir), keeps files `file` says aren't binary, `sed -i s#/home/m#$HOME#g`. Rewrites repo files in place (dirty tree) and would also hit app-state text files (Signal/Bitwarden/mozilla LevelDB logs, kicad MRU lists).
6. `deploy_dotfiles` (`:149`) — for **every** top-level dir except `guides`/`.git`: `link_path ~/.config/<name>`; `dconf/user` copied. Loose files: bashrc→~/.bashrc, mimeapps.list, user-dirs.locale, wallpaper png. `link_path` (`:135`) moves existing target to `~/.config-backup-<ts>/<rel>`; idempotent if already the same link.
7. `enable_services` (`:198`) — `systemctl enable --now` for NetworkManager, bluetooth, gdm, docker, cronie, power-profiles-daemon, avahi-daemon, ModemManager if pkg installed; adds user to docker group.
8. `install_bootloader` (`:223`, opt-in) — `refind refind-btrfs`, `refind-install`. Does NOT copy `refind/refind-efifetch` theme to ESP.
Post-message (`:251-259`) mentions `lua/lazy-lock.json` (actual: `nvim/lazy-lock.json`).

## after-install.sh (tracked, 37 l) — legacy
No shebang. Detects Apple (`lspci -d 106B:`), appends arch-mact2 with literal `\` line continuations inside single quotes (`:5-8` → malformed pacman.conf). Builds paru in `~/paru`. Installs `parui gnome gnome-tweaks ranger firefox tmux neovim kitty bat devtools fzf refind` + **runs `refind-install` unconditionally** (`:24`). gdm enable heuristic `ps | grep gdm | wc -l > 6` (`:25`). Clones LazyVim starter into `~/.config/nvim` and tpm into `~/.config/tmux/plugins` (`:29-30`; wrong: should be `plugins/tpm`; conflicts with repo symlinks). `:32,35` `[[ $USR_SHELL -eq "bash" ]]` numeric compare on strings ⇒ always true ⇒ always bash branch. `:1` `grep $(id -u) /etc/passwd` matches uid digits anywhere.

## install_optdeps.sh (tracked)
`./install_optdeps.sh pkg…` → for each pkg, `paru|yay -Qi`, scrapes optional deps with a loose regex `'^\s*[0-z\-]*:'` (catches every `Field:` label too), installs with `-Syu --noconfirm`. Fragile; `SILENT` unused.

## packages (tracked, ~1478 lines)
Looks like full `pacman -Qq` (explicit + deps, incl. ~65 `lib32-*`, many `python-*`). GNOME-era (+ `bluetui`, `cliphist` added batch 1): contains gnome, gdm, kitty, tmux, neovim, nvm, ruby, fzf, rofi, yazi, nautilus, polkit-gnome, wl-clipboard, bitwarden, refind, paru. **Missing** everything for the current WMs: sway, sway-scroll, swayidle, swaylock, hyprland, hyprlock, hypridle, waybar, mako, fuzzel, grim, slurp, brightnessctl, playerctl, niri, swaync, wallust, awww, tinty, thunar, lazygit, zoxide, tailscale, cloudflare-warp, easyeffects.

## failed-packages.log (untracked, ~90 lines)
Output of a previous run: all lib32-* (multilib repo not enabled by script), linux-t2/apple-bcm-firmware (T2 only), electron33/34, AUR-only/renamed (hudkit, obsidian-cli-bin, qbittorrent-enhanced-nox-bin, gvfs-google, firefox-wayland-mode-hook…), `paru-debug`.

## refind/ {#refind}
`refind/refind-efifetch/` vendored theme (background, icons, theme.conf, LICENSE). Commit `ec8a687` replaced submodule with plain files. Symlinked to `~/.config/refind` by deploy (harmless, unused there); must be copied to ESP `EFI/refind/themes/` + `include` in refind.conf manually.

## Typical safe test sequence
`./recreate-environment.sh --skip-packages` in a throwaway user/VM (testenv/) — still runs T2 check + sudo pacman + service enables.
