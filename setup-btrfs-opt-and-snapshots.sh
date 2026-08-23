#!/bin/bash
# Sets up btrfs snapshots and an independent /opt subvolume. Run this
# separately from recreate-environment.sh, after it, on a btrfs install:
#
#   ./setup-btrfs-opt-and-snapshots.sh --all
#
# What it does:
#   --setup-snapshots  installs snapper (+ snap-pac for automatic pacman
#                       snapshots) and creates two independent configs:
#                       "root" for / and "home" for /home. They get their
#                       own retention timelines, so home snapshots (your
#                       files) and root snapshots (system/pacman state)
#                       don't share a policy.
#   --setup-opt         turns /opt into its own top-level btrfs subvolume
#                       (@opt), migrating any existing content. It is
#                       deliberately left OUT of both snapper configs, so
#                       nothing under /opt is ever pulled into a snapshot
#                       or a rollback -- meant for large/throwaway stuff
#                       like dev SDKs (this repo already uses /opt/esp)
#                       and Steam's library.
#   --steam-to-opt      installs steam and redirects ~/.local/share/Steam
#                       into /opt/steam via symlink (existing data is
#                       backed up first, not deleted). Implies --setup-opt.
#   --all               all of the above.
#
# This edits /etc/fstab and moves data on your root filesystem. Backups are
# made before anything destructive (fstab, and the pre-migration /opt), but
# review the output before rebooting. Safe to re-run: every step checks
# whether it already happened.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_SNAPSHOTS=0
DO_OPT=0
DO_STEAM=0

usage() {
  cat <<EOF
Usage: ${BASH_SOURCE[0]} [options]

  --setup-snapshots   set up snapper configs "root" (/) and "home" (/home)
  --setup-opt         move /opt to its own btrfs subvolume, excluded from
                      both snapper configs above
  --steam-to-opt      install steam, symlink ~/.local/share/Steam into
                      /opt/steam (implies --setup-opt)
  --all               shorthand for all of the above
  -h, --help          show this help
EOF
}

[ "$#" -eq 0 ] && { usage; exit 1; }
for arg in "$@"; do
  case "$arg" in
    --setup-snapshots) DO_SNAPSHOTS=1 ;;
    --setup-opt) DO_OPT=1 ;;
    --steam-to-opt) DO_STEAM=1; DO_OPT=1 ;;
    --all) DO_SNAPSHOTS=1; DO_OPT=1; DO_STEAM=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  echo "run this as your normal user, not root (it calls sudo where needed)" >&2
  exit 1
fi

log() { echo -e "\n==> $*"; }

if [ "$(findmnt -no FSTYPE /)" != "btrfs" ]; then
  echo "root filesystem is not btrfs, nothing to do here" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Snapshots: snapper configs for / and /home, decoupled from each other
# ---------------------------------------------------------------------------
setup_root_snapper_config() {
  if sudo snapper list-configs 2>/dev/null | awk '{print $1}' | grep -qx root; then
    echo "snapper 'root' config already exists"
    return
  fi
  log "creating snapper 'root' config for /"
  # archinstall's default btrfs layout mounts a separate @.snapshots
  # subvolume at /.snapshots -- hand it to snapper the documented way
  # instead of fighting it (this is a no-op if that isn't the case).
  if findmnt /.snapshots >/dev/null 2>&1; then
    sudo umount /.snapshots
  fi
  sudo rm -rf /.snapshots
  sudo snapper -c root create-config /
  sudo btrfs subvolume delete /.snapshots 2>/dev/null || true
  sudo mkdir -p /.snapshots
  sudo mount -a
  sudo chmod 750 /.snapshots
}

setup_home_snapper_config() {
  if sudo snapper list-configs 2>/dev/null | awk '{print $1}' | grep -qx home; then
    echo "snapper 'home' config already exists"
    return
  fi
  log "creating snapper 'home' config for /home"
  sudo snapper -c home create-config /home
}

setup_snapshots() {
  log "installing snapper, snap-pac"
  paru -S --needed --noconfirm snapper snap-pac

  setup_root_snapper_config
  setup_home_snapper_config

  log "tuning retention (root: system state via pacman hooks; home: your files)"
  sudo snapper -c root set-config \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
    TIMELINE_LIMIT_WEEKLY=2 TIMELINE_LIMIT_MONTHLY=1 TIMELINE_LIMIT_YEARLY=0 \
    NUMBER_CLEANUP=yes NUMBER_LIMIT=20 NUMBER_LIMIT_IMPORTANT=10

  sudo snapper -c home set-config \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=12 TIMELINE_LIMIT_DAILY=14 \
    TIMELINE_LIMIT_WEEKLY=4 TIMELINE_LIMIT_MONTHLY=3 TIMELINE_LIMIT_YEARLY=0 \
    NUMBER_CLEANUP=yes NUMBER_LIMIT=50 NUMBER_LIMIT_IMPORTANT=10 \
    ALLOW_USERS="$USER"

  sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

  log "snapshots ready"
  echo "  - /opt is intentionally NOT part of either config (see --setup-opt)"
  echo "  - refind-btrfs is already in ./packages for bootable snapshot entries;"
  echo "    it still needs /etc/refind-btrfs.json reviewed for your disk layout"
  echo "    and 'sudo systemctl enable --now refind-btrfs.service' -- left manual"
  echo "    since it's boot-loader config specific to your partitions"
}

# ---------------------------------------------------------------------------
# /opt: independent top-level subvolume, outside any snapper config
# ---------------------------------------------------------------------------
setup_opt_subvolume() {
  if sudo btrfs subvolume show /opt >/dev/null 2>&1; then
    echo "/opt is already its own subvolume"
    return
  fi

  log "moving /opt to its own btrfs subvolume (@opt)"
  local root_src root_dev root_uuid fstab_opts topmnt

  root_src="$(findmnt -no SOURCE /)"
  root_dev="${root_src%%\[*}"
  root_uuid="$(findmnt -no UUID /)"
  fstab_opts="$(findmnt -no OPTIONS / | tr ',' '\n' \
    | grep -Ev '^subvolid=|^subvol=' | paste -sd, -),subvol=/@opt"

  topmnt="$(mktemp -d)"
  sudo mount -o subvolid=5 "$root_dev" "$topmnt"

  if ! sudo btrfs subvolume show "$topmnt/@opt" >/dev/null 2>&1; then
    sudo btrfs subvolume create "$topmnt/@opt" >/dev/null
  fi

  if [ -d /opt ] && [ -n "$(ls -A /opt 2>/dev/null)" ]; then
    log "backing up existing /opt content before migrating it in"
    sudo rsync -aHAX /opt/ "$topmnt/@opt/"
    sudo mv /opt "/opt.bak-$(date +%Y%m%d%H%M%S)"
    echo "  kept the original at /opt.bak-* -- safe to delete once you've verified"
  fi
  sudo mkdir -p /opt

  sudo umount "$topmnt"
  rmdir "$topmnt"

  if ! grep -q ' /opt btrfs ' /etc/fstab; then
    sudo cp /etc/fstab "/etc/fstab.bak-$(date +%Y%m%d%H%M%S)"
    echo "UUID=$root_uuid /opt btrfs $fstab_opts 0 0" | sudo tee -a /etc/fstab >/dev/null
  fi

  sudo mount -a
  if ! mountpoint -q /opt; then
    echo "failed to mount /opt from fstab -- check /etc/fstab and the backup dir above" >&2
    return 1
  fi
  echo "/opt is now its own subvolume, mounted and outside snapper's reach"
}

# ---------------------------------------------------------------------------
# Steam -> /opt/steam
# ---------------------------------------------------------------------------
setup_steam() {
  log "installing steam"
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo cp /etc/pacman.conf "/etc/pacman.conf.bak-$(date +%Y%m%d%H%M%S)"
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
  fi
  paru -S --needed --noconfirm steam

  log "redirecting ~/.local/share/Steam into /opt/steam"
  sudo mkdir -p /opt/steam
  sudo chown "$USER:$USER" /opt/steam

  local target="$HOME/.local/share/Steam" source="/opt/steam"
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    echo "already linked"
    return
  fi
  mkdir -p "$HOME/.local/share"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="$REPO_DIR/steam-backup-$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "moved existing Steam data to $backup, merge it into /opt/steam if needed"
  fi
  ln -s "$source" "$target"
  echo "linked $target -> $source"
}

# ---------------------------------------------------------------------------
main() {
  [ "$DO_OPT" -eq 1 ] && setup_opt_subvolume
  [ "$DO_STEAM" -eq 1 ] && setup_steam
  [ "$DO_SNAPSHOTS" -eq 1 ] && setup_snapshots
  log "done"
}

main
