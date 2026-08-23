#!/bin/bash
# Recreates this machine's environment from a fresh `archinstall` install.
#
# Run this as your normal user (not root) from inside a clone of this repo,
# after the base archinstall + reboot, once you have a network connection:
#
#   git clone https://github.com/vstkl/conf9000 ~/conf9000
#   cd ~/conf9000
#   git submodule update --init --recursive
#   ./recreate-environment.sh
#
# It is safe to re-run: package installs use --needed, and dotfiles are
# symlinked with any pre-existing file backed up first.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"

SKIP_PACKAGES=0
SKIP_DOTFILES=0
INSTALL_BOOTLOADER=0
FIX_HOME_PATHS=0

usage() {
  cat <<EOF
Usage: ${BASH_SOURCE[0]} [options]

  --skip-packages       don't install packages from the 'packages' file
  --skip-dotfiles       don't symlink dotfiles into \$HOME
  --install-bootloader  also install/refresh refind (skipped by default:
                         touches the boot loader, opt in explicitly)
  --fix-home-paths      rewrite hardcoded /home/m paths (from the original
                         machine) to \$HOME in this repo's text configs
  -h, --help             show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-dotfiles) SKIP_DOTFILES=1 ;;
    --install-bootloader) INSTALL_BOOTLOADER=1 ;;
    --fix-home-paths) FIX_HOME_PATHS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  echo "run this as your normal user, not root (it calls sudo where needed)" >&2
  exit 1
fi

log() { echo -e "\n==> $*"; }

# ---------------------------------------------------------------------------
# 1. AUR helper (paru)
# ---------------------------------------------------------------------------
install_paru() {
  if command -v paru >/dev/null; then
    log "paru already installed"
    return
  fi
  log "installing paru"
  sudo pacman -Sy --needed --noconfirm git base-devel
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# 2. Apple T2 mirror (only relevant on T2 Macs, matches after-install.sh)
# ---------------------------------------------------------------------------
setup_apple_t2() {
  sudo pacman -Sy --needed --noconfirm pciutils
  if [ "$(lspci -d 106b: 2>/dev/null | wc -l)" -gt 0 ]; then
    log "Apple T2 hardware detected"
    if ! grep -q '\[arch-mact2\]' /etc/pacman.conf; then
      printf '%s\n' \
        '[arch-mact2]' \
        'Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release' \
        'SigLevel = Never' \
        | sudo tee -a /etc/pacman.conf >/dev/null
      sudo pacman -Sy
    fi
    sudo pacman -S --needed --noconfirm \
      linux-t2 linux-t2-headers apple-t2-audio-config apple-bcm-firmware \
      linux-firmware iwd efibootmgr t2fanrd
  fi
}

# ---------------------------------------------------------------------------
# 3. Multilib (needed for the lib32-* packages in ./packages, and for Steam)
# ---------------------------------------------------------------------------
enable_multilib() {
  if grep -q '^\[multilib\]' /etc/pacman.conf; then
    return
  fi
  log "enabling the multilib repo"
  sudo cp /etc/pacman.conf "/etc/pacman.conf.bak-$(date +%Y%m%d%H%M%S)"
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy
}

# ---------------------------------------------------------------------------
# 4. Packages (mix of official repo + AUR, one per line in ./packages)
# ---------------------------------------------------------------------------
install_packages() {
  log "installing packages from ./packages (this will take a while)"
  # drop anything that isn't a plausible pacman package name (letters/digits/
  # @._+- only, lowercase-starting) -- a stray non-package line here would
  # otherwise abort the *entire* pacman/paru transaction with nothing installed.
  local filtered
  filtered="$(mktemp)"
  grep -E '^[a-z0-9][a-z0-9@._+-]*$' "$REPO_DIR/packages" | sort -u > "$filtered"
  local dropped
  dropped="$(comm -23 <(sort -u "$REPO_DIR/packages") "$filtered")"
  if [ -n "$dropped" ]; then
    echo "skipping non-package lines from packages file:"
    echo "$dropped" | sed 's/^/  /'
  fi

  if paru -S --needed --noconfirm - < "$filtered"; then
    rm -f "$filtered"
    return
  fi

  log "batch install failed (likely a renamed/removed package) -- retrying one by one"
  local failed_log="$REPO_DIR/failed-packages.log"
  : > "$failed_log"
  while read -r pkg; do
    paru -S --needed --noconfirm "$pkg" || echo "$pkg" >> "$failed_log"
  done < "$filtered"
  rm -f "$filtered"

  if [ -s "$failed_log" ]; then
    log "the following packages could not be installed, see $failed_log"
    cat "$failed_log"
  fi
}

# ---------------------------------------------------------------------------
# 5. Dotfiles: symlink every top-level config dir into ~/.config, plus the
#    loose files that live at the repo root.
# ---------------------------------------------------------------------------
link_path() {
  local target="$1" source="$2"
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${target#"$HOME"/}")"
    mv "$target" "$BACKUP_DIR/${target#"$HOME"/}"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  echo "linked $target -> $source"
}

deploy_dotfiles() {
  log "linking dotfiles into \$HOME"
  mkdir -p "$HOME/.config"

  local exclude=(guides .git)
  local dir name skip
  for dir in "$REPO_DIR"/*/; do
    name="$(basename "$dir")"
    skip=0
    for e in "${exclude[@]}"; do [ "$name" = "$e" ] && skip=1; done
    [ "$skip" -eq 1 ] && continue
    if [ "$name" = "dconf" ]; then
      # copy, don't symlink: this is a live GVariant DB and shouldn't write
      # back into the git repo on every settings change.
      mkdir -p "$HOME/.config/dconf"
      cp "$REPO_DIR/dconf/user" "$HOME/.config/dconf/user"
      echo "restored dconf settings to $HOME/.config/dconf/user"
      continue
    fi
    link_path "$HOME/.config/$name" "${dir%/}"
  done

  link_path "$HOME/.bashrc" "$REPO_DIR/bashrc"
  link_path "$HOME/.config/mimeapps.list" "$REPO_DIR/mimeapps.list"
  link_path "$HOME/.config/user-dirs.locale" "$REPO_DIR/user-dirs.locale"
  link_path "$HOME/.config/arch-hero-wallpaper-free.png" "$REPO_DIR/arch-hero-wallpaper-free.png"

  if [ -d "$BACKUP_DIR" ]; then
    log "existing files were backed up to $BACKUP_DIR"
  fi
}

fix_home_paths() {
  [ "$HOME" = "/home/m" ] && return
  log "rewriting /home/m -> $HOME in tracked text configs"
  grep -rlZ --exclude-dir=.git --exclude-dir=undodir --exclude=dconf/user \
    "/home/m" "$REPO_DIR" 2>/dev/null \
    | xargs -0 -r file --mime-encoding \
    | grep -v 'binary' \
    | cut -d: -f1 \
    | while read -r f; do
        sed -i "s#/home/m#$HOME#g" "$f"
        echo "updated $f"
      done
}

# ---------------------------------------------------------------------------
# 6. Services (enabled only when the matching package was actually installed)
# ---------------------------------------------------------------------------
enable_services() {
  log "enabling services"
  declare -A svc=(
    [networkmanager]=NetworkManager.service
    [bluez]=bluetooth.service
    [gdm]=gdm.service
    [docker]=docker.service
    [cronie]=cronie.service
    [power-profiles-daemon]=power-profiles-daemon.service
    [avahi]=avahi-daemon.service
    [modemmanager]=ModemManager.service
  )
  local pkg
  for pkg in "${!svc[@]}"; do
    if pacman -Qq "$pkg" &>/dev/null; then
      sudo systemctl enable --now "${svc[$pkg]}" 2>/dev/null \
        && echo "enabled ${svc[$pkg]}"
    fi
  done
  if pacman -Qq docker &>/dev/null && ! groups "$USER" | grep -q '\bdocker\b'; then
    sudo usermod -aG docker "$USER"
    echo "added $USER to the docker group (re-login to take effect)"
  fi
}

install_bootloader() {
  log "installing refind"
  sudo pacman -S --needed --noconfirm refind refind-btrfs
  sudo refind-install
}

# ---------------------------------------------------------------------------
main() {
  setup_apple_t2
  install_paru

  if [ "$SKIP_PACKAGES" -eq 0 ]; then
    enable_multilib
    install_packages
  fi

  git -C "$REPO_DIR" submodule update --init --recursive

  [ "$FIX_HOME_PATHS" -eq 1 ] && fix_home_paths

  if [ "$SKIP_DOTFILES" -eq 0 ]; then
    deploy_dotfiles
  fi

  enable_services

  [ "$INSTALL_BOOTLOADER" -eq 1 ] && install_bootloader

  log "done"
  cat <<EOF
Next steps:
  - log out/in (or reboot) to pick up dconf settings, group membership and
    the new shell session
  - launch nvim once to let lazy.nvim sync plugins from lua/lazy-lock.json
  - the niri/sway/scroll configs assume they're started from your display
    manager or a TTY session -- pick whichever compositor you want as your
    session
  - on a btrfs install, run ./setup-btrfs-opt-and-snapshots.sh to set up
    snapper (root + home) and move /opt to its own subvolume for Steam and
    dev tooling -- it's a separate, opt-in script since it edits fstab
EOF
}

main
