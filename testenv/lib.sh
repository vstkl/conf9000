# shellcheck shell=bash
# Shared settings/helpers for the testenv scripts. Sourced, not executed.
# Every value can be overridden from the environment (e.g. TESTENV_MEM=8192).

TESTENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TESTENV_DIR/.." && pwd)"

IMAGES_DIR="$TESTENV_DIR/images"
LOGS_DIR="$TESTENV_DIR/logs"
RUN_DIR="$TESTENV_DIR/run"
SSH_DIR="$TESTENV_DIR/ssh"

IMAGE_BASE_URL="${TESTENV_IMAGE_BASE_URL:-https://geo.mirror.pkgbuild.com/images/latest}"
IMAGE_FLAVOR="${TESTENV_IMAGE_FLAVOR:-Arch-Linux-x86_64-cloudimg}"

BASE_LINK="$IMAGES_DIR/base.qcow2"          # symlink -> pinned, checksum-verified image
OVERLAY="$IMAGES_DIR/overlay.qcow2"         # all VM writes land here (disposable)
SEED_ISO="$IMAGES_DIR/seed.iso"             # cloud-init NoCloud seed

SSH_KEY="$SSH_DIR/id_ed25519"
SSH_PORT="${TESTENV_SSH_PORT:-2222}"
VM_USER="m"                                 # same name as the real machine -> /home/m paths behave
VM_HOSTNAME="${TESTENV_HOSTNAME:-conf9000-test}"
VM_MEM="${TESTENV_MEM:-4096}"
VM_CPUS="${TESTENV_CPUS:-4}"
VM_DISK_SIZE="${TESTENV_DISK_SIZE:-40G}"
REMOTE_REPO="${TESTENV_REMOTE_REPO:-/home/$VM_USER/conf9000}"

PIDFILE="$RUN_DIR/qemu.pid"
MONITOR_SOCK="$RUN_DIR/monitor.sock"
SERIAL_LOG="$LOGS_DIR/serial.log"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

ssh_opts() {
  # -F /dev/null: ignore the user's ~/.ssh/config; IdentitiesOnly: never offer
  # the user's agent keys. Host key changes on every reset -> don't record it.
  printf '%s\n' -F /dev/null -i "$SSH_KEY" -p "$SSH_PORT" \
    -o IdentitiesOnly=yes -o IdentityAgent=none \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=15
}

vm_ssh() {
  local opts; mapfile -t opts < <(ssh_opts)
  ssh "${opts[@]}" "$VM_USER@127.0.0.1" "$@"
}

# raw QEMU started by start.sh
qemu_running() {
  [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

# libvirt domain started by virt-manager.sh (same disk, same ssh port)
LIBVIRT_URI="qemu:///session"
LIBVIRT_DOMAIN="conf9000-testenv"
libvirt_running() {
  command -v virsh >/dev/null &&
    [ "$(timeout 10 virsh -c "$LIBVIRT_URI" domstate "$LIBVIRT_DOMAIN" 2>/dev/null)" = "running" ]
}

# either flavour: ssh.sh / sync.sh / check.sh / run-bootstrap.sh work with both
vm_running() { qemu_running || libvirt_running; }

wait_for_ssh() {
  local timeout="${1:-300}" t=0
  while ! vm_ssh -o BatchMode=yes true 2>/dev/null; do
    qemu_running || die "VM process exited; see $SERIAL_LOG"
    t=$((t + 3)); [ "$t" -ge "$timeout" ] && die "ssh not reachable after ${timeout}s; see $SERIAL_LOG"
    sleep 3
  done
}

wait_for_cloud_init() {
  # cloud-init status --wait exits 0 (done) or 2 (done with recoverable errors)
  vm_ssh 'command -v cloud-init >/dev/null && cloud-init status --wait >/dev/null; rc=$?; [ $rc -eq 0 ] || [ $rc -eq 2 ]' \
    || echo "warning: cloud-init reported an error (see: ./ssh.sh sudo cloud-init status --long)" >&2
}

# Preflight: host requirements for the rootless QEMU path. This testenv calls
# qemu-system-x86_64 directly -- it does NOT use libvirt/virsh/virt-install,
# so libvirtd does not need to be running. (If you add a libvirt-based script,
# check `systemctl is-active libvirtd` there and tell the user to run
# `sudo systemctl start libvirtd`.)
preflight() {
  local t
  for t in qemu-system-x86_64 qemu-img ssh; do
    command -v "$t" >/dev/null || die "preflight: missing $t (sudo pacman -S qemu-full openssh)"
  done
  if [ ! -e /dev/kvm ]; then
    echo "preflight: /dev/kvm missing -> slow TCG emulation. Fix: enable VT-x/AMD-V in firmware; sudo modprobe kvm_intel (or kvm_amd)" >&2
  elif [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    echo "preflight: /dev/kvm not accessible to $(id -un) -> slow TCG emulation. Fix: sudo usermod -aG kvm $(id -un) (then re-login)" >&2
  else
    info "preflight: /dev/kvm accessible (hardware acceleration)"
  fi
}
