#!/usr/bin/env bash
# Run recreate-environment.sh inside the VM (as user m, never with
# --install-bootloader) and capture the output to testenv/logs/.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

MODE=minimal
BUILD_PARU=0
EXTRA=()
# What "minimal" installs before running the bootstrap with --skip-packages:
# the tools the configs/check.sh need, plus what bashrc hard-requires (gem -> ruby).
MINIMAL_PKGS=(bash bash-completion fzf neovim sway swaybg waybar kitty tmux git shellcheck
              hyprland jq python ruby which file pciutils
              cliphist wl-clipboard bluetui bluez bluez-utils fuzzel rofi
              networkmanager swaync libnotify
              ttf-nerd-fonts-symbols ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji adwaita-fonts)
# AUR extras, each installed individually and best-effort (a failure is logged, not fatal):
#   nvm: bashrc sources /usr/share/nvm/init-nvm.sh;  sway-scroll: provides `scroll` (compiles, slow)
MINIMAL_AUR=(nvm sway-scroll)

usage() {
  cat <<EOF
Usage: $(basename "$0") [--full | --minimal] [--build-paru] [-- EXTRA_ARGS...]

  --minimal     (default) pacman -Syu + a small package set
                (${MINIMAL_PKGS[*]} + AUR: ${MINIMAL_AUR[*]}),
                then: recreate-environment.sh --skip-packages
  --full        recreate-environment.sh with the full ./packages list (1476 pkgs, slow, GBs)
  --build-paru  let the bootstrap compile paru from source; default pre-installs
                the prebuilt paru-bin from the AUR to save ~10 minutes
  -- ARGS       extra args for recreate-environment.sh (e.g. -- --skip-dotfiles)
  -h, --help    show this help

The VM user is '$VM_USER' with HOME=/home/$VM_USER, so --fix-home-paths is not
needed (it is a no-op there). Run ./sync.sh first. Log: logs/bootstrap-<mode>-<time>.log
EOF
}
while [ $# -gt 0 ]; do
  case "$1" in
    --full) MODE=full ;;
    --minimal) MODE=minimal ;;
    --build-paru) BUILD_PARU=1 ;;
    --) shift; EXTRA=("$@"); break ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done
for a in "${EXTRA[@]}"; do
  [ "$a" = "--install-bootloader" ] && die "refusing --install-bootloader in the test VM"
done

vm_running || die "VM not running (./start.sh)"
vm_ssh "test -x '$REMOTE_REPO/recreate-environment.sh'" || die "repo not in VM yet (./sync.sh)"
mkdir -p "$LOGS_DIR"
LOG="$LOGS_DIR/bootstrap-$MODE-$(date +%Y%m%d-%H%M%S).log"

args=()
[ "$MODE" = minimal ] && args+=(--skip-packages)
args+=("${EXTRA[@]}")
remote_args="$(printf '%q ' "${args[@]}")"

remote_script=$(cat <<EOS
set -uo pipefail
cd '$REMOTE_REPO'
echo "### testenv bootstrap: mode=$MODE host=\$(uname -n) \$(date -Is)"
echo "### waiting for first-boot provisioning"
for i in \$(seq 1 120); do [ -e /var/lib/testenv-provisioned ] && break; sleep 5; done
if [ "$MODE" = minimal ]; then
  echo "### pacman -Syu + minimal package set"
  sudo pacman -Syu --needed --noconfirm ${MINIMAL_PKGS[*]} || exit 1
fi
if [ "$BUILD_PARU" -eq 0 ] && ! command -v paru >/dev/null; then
  echo "### pre-installing paru-bin (prebuilt) from the AUR"
  tmp=\$(mktemp -d)
  git clone -q https://aur.archlinux.org/paru-bin.git "\$tmp/paru-bin" \
    && (cd "\$tmp/paru-bin" && makepkg -si --noconfirm) \
    && paru --version || { echo "### paru-bin unusable, removing; bootstrap will build paru"; sudo pacman -Rns --noconfirm paru-bin 2>/dev/null; }
  rm -rf "\$tmp"
fi
if [ "$MODE" = minimal ]; then
  echo "### AUR extras: ${MINIMAL_AUR[*]}"
  for p in ${MINIMAL_AUR[*]}; do
    paru -S --needed --noconfirm "\$p" || echo "### WARNING: AUR package \$p failed to install"
  done
fi
echo "### ./recreate-environment.sh $remote_args"
./recreate-environment.sh $remote_args
rc=\$?
echo "### recreate-environment.sh exit code: \$rc"
if [ "$MODE" = minimal ] && pacman -Qq networkmanager >/dev/null 2>&1 && systemctl is-enabled -q systemd-networkd 2>/dev/null; then
  # like the real machine: NetworkManager owns the NIC (nmtui works). Reboot is detached +
  # delayed so this ssh session ends cleanly.
  echo "### handing the network from systemd-networkd to NetworkManager"
  # networkd is socket-activated by several units, so plain disable doesn't stick: mask it and reboot.
  sudo systemctl mask systemd-networkd.service
  sudo systemctl disable systemd-networkd.socket systemd-networkd-varlink.socket \\
    systemd-networkd-varlink-metrics.socket systemd-networkd-resolve-hook.socket 2>/dev/null
  sudo systemctl enable NetworkManager.service
  echo "### rebooting VM so NetworkManager takes over (ssh is back in ~30s)"
  sudo systemd-run --quiet --on-active=3 systemctl reboot
fi
exit \$rc
EOS
)

info "running bootstrap ($MODE) in VM, log: $LOG"
set +e
# upload first, then run with stdin from /dev/null (pacman/makepkg must not eat the script)
vm_ssh "cat > /tmp/testenv-bootstrap.sh" <<<"$remote_script"
vm_ssh "bash /tmp/testenv-bootstrap.sh </dev/null" 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
set -e
info "bootstrap finished with exit code $rc (log: $LOG)"
exit "$rc"
