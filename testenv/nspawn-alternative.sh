#!/usr/bin/env bash
# OPTIONAL root-requiring alternative to the QEMU VM: an Arch container built
# with pacstrap and run with systemd-nspawn. Faster than a VM, but no kernel /
# DRM / bluetooth / real seat, so GUI checks are limited to headless sway.
#
# YOU run this with sudo (the agents never do):
#   sudo ./nspawn-alternative.sh create     # pacstrap base system + user m (once)
#   sudo ./nspawn-alternative.sh sync       # copy repo in (same excludes as sync.sh)
#   sudo ./nspawn-alternative.sh bootstrap  # recreate-environment.sh --skip-packages as m
#   sudo ./nspawn-alternative.sh check      # check.sh --local as m
#   sudo ./nspawn-alternative.sh shell      # interactive login shell as m
#   sudo ./nspawn-alternative.sh destroy    # delete the container tree
set -euo pipefail

TESTENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TESTENV_DIR/.." && pwd)"
ROOT="${NSPAWN_ROOT:-$TESTENV_DIR/images/nspawn-root}"
PKGS=(base base-devel sudo git rsync python bash-completion fzf neovim sway waybar kitty tmux
      shellcheck jq ruby cliphist wl-clipboard bluez bluez-utils fuzzel rofi which file)

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; }

cmd="${1:-}"
case "$cmd" in -h|--help|"") usage; [ -n "$cmd" ]; exit $? ;; esac
[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

as_m() { systemd-nspawn -q -D "$ROOT" --user=m --chdir=/home/m --setenv=HOME=/home/m "$@"; }

case "$cmd" in
  create)
    if [ -x "$ROOT/usr/bin/bash" ]; then echo "container already exists at $ROOT"; exit 0; fi
    mkdir -p "$ROOT"
    pacstrap -c -K "$ROOT" "${PKGS[@]}"
    systemd-nspawn -q -D "$ROOT" bash -c '
      id m >/dev/null 2>&1 || useradd -m -G wheel -s /bin/bash m
      echo "m ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/m; chmod 440 /etc/sudoers.d/m
      echo conf9000-nspawn > /etc/hostname'
    echo "created $ROOT"
    ;;
  sync)
    mkdir -p "$ROOT/home/m/conf9000"
    rsync -a --delete --delete-excluded --exclude-from="$TESTENV_DIR/sync-exclude.txt" \
      "$REPO_DIR/" "$ROOT/home/m/conf9000/"
    systemd-nspawn -q -D "$ROOT" chown -R m:m /home/m/conf9000
    ;;
  bootstrap)
    as_m bash -c 'cd ~/conf9000 && ./recreate-environment.sh --skip-packages' 2>&1 \
      | tee "$TESTENV_DIR/logs/nspawn-bootstrap-$(date +%Y%m%d-%H%M%S).log"
    ;;
  check)
    install -m 755 "$TESTENV_DIR/check.sh" "$ROOT/opt/testenv-check.sh"   # testenv/ itself is not synced
    as_m bash /opt/testenv-check.sh --local 2>&1 \
      | tee "$TESTENV_DIR/logs/nspawn-check-$(date +%Y%m%d-%H%M%S).log"
    ;;
  shell) as_m bash -l ;;
  destroy) rm -rf --one-file-system "$ROOT"; echo "removed $ROOT" ;;
  *) echo "unknown command: $cmd" >&2; usage >&2; exit 1 ;;
esac
