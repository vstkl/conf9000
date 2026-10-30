#!/usr/bin/env bash
# Boot the test VM (rootless QEMU, user-mode networking, ssh on 127.0.0.1:2222).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

GUI=0
GL=0
DISPLAY_BACKEND="gtk"
WAIT=1

usage() {
  cat <<EOF
Usage: $(basename "$0") [--gui [--gl] [--display gtk|sdl]] [--no-wait]

Starts the VM in the background (pidfile: run/qemu.pid, serial console: logs/serial.log).

  --gui             open a window with a virtio-vga display (for sway/hyprland/waybar);
                    log in on the console as '$VM_USER' / password 'test'
  --gl              use virtio-vga-gl + display gl=on (needs working host OpenGL;
                    required by Hyprland; sway also works without it via WLR_RENDERER=pixman)
  --display NAME    QEMU display backend for --gui: gtk (default) or sdl
  --no-wait         don't wait for ssh to come up
  -h, --help        show this help

Settings: memory ${VM_MEM}M, ${VM_CPUS} vCPUs, ssh port $SSH_PORT (TESTENV_MEM/CPUS/SSH_PORT override).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --gui) GUI=1 ;;
    --gl) GL=1 ;;
    --display) DISPLAY_BACKEND="${2:?}"; shift ;;
    --no-wait) WAIT=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

preflight
if qemu_running; then
  info "VM already running (pid $(cat "$PIDFILE"))"
  exit 0
fi
libvirt_running && die "the libvirt VM is running on the same disk; ./virt-manager.sh stop first"
[ -f "$OVERLAY" ] && [ -f "$SEED_ISO" ] || die "no overlay/seed yet -- run ./setup.sh first"
mkdir -p "$RUN_DIR" "$LOGS_DIR"
rm -f "$PIDFILE" "$MONITOR_SOCK"

if (exec 3<>"/dev/tcp/127.0.0.1/$SSH_PORT") 2>/dev/null; then
  die "port $SSH_PORT already in use (set TESTENV_SSH_PORT=...)"
fi

args=(
  -name conf9000-testenv
  -m "$VM_MEM" -smp "$VM_CPUS"
  -drive "file=$OVERLAY,if=virtio,format=qcow2,discard=unmap"
  -drive "file=$SEED_ISO,if=virtio,media=cdrom,readonly=on"
  -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22"
  -device virtio-net-pci,netdev=n0
  -device virtio-rng-pci
  -serial "file:$SERIAL_LOG"
  -monitor "unix:$MONITOR_SOCK,server,nowait"
  -pidfile "$PIDFILE"
)
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  args+=(-accel kvm -cpu host)
else
  echo "warning: no /dev/kvm access, using TCG (slow)" >&2
  args+=(-accel tcg -cpu max)
fi

if [ "$GUI" -eq 1 ]; then
  if [ "$GL" -eq 1 ]; then
    args+=(-device virtio-vga-gl -display "$DISPLAY_BACKEND,gl=on")
  else
    args+=(-device virtio-vga -display "$DISPLAY_BACKEND")
  fi
  args+=(-device qemu-xhci -device usb-tablet -device usb-kbd)
else
  args+=(-display none -vga none)
fi

info "starting VM ($( [ "$GUI" -eq 1 ] && echo gui || echo headless ))"
setsid nohup qemu-system-x86_64 "${args[@]}" >"$LOGS_DIR/qemu.log" 2>&1 < /dev/null &

for _ in $(seq 1 50); do
  [ -s "$PIDFILE" ] && break
  kill -0 $! 2>/dev/null || { cat "$LOGS_DIR/qemu.log" >&2; die "qemu failed to start"; }
  sleep 0.2
done
qemu_running || { cat "$LOGS_DIR/qemu.log" >&2; die "qemu failed to start"; }
info "qemu pid $(cat "$PIDFILE"); serial log: $SERIAL_LOG"

if [ "$WAIT" -eq 1 ]; then
  info "waiting for ssh on 127.0.0.1:$SSH_PORT"
  wait_for_ssh 300
  info "waiting for cloud-init (first boot also runs pacman -Syu, a few minutes)"
  wait_for_cloud_init
  # first boot runs pacman -Syu; if that replaced the running kernel, its modules
  # are gone (modprobe fails) -> reboot once into the new kernel
  if ! vm_ssh 'test -d "/usr/lib/modules/$(uname -r)"'; then
    info "kernel was upgraded during first boot -- rebooting the VM once"
    old_boot="$(vm_ssh cat /proc/sys/kernel/random/boot_id)"
    vm_ssh 'sudo systemctl reboot' >/dev/null 2>&1 || true
    for _ in $(seq 1 100); do
      b="$(vm_ssh -o BatchMode=yes cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)"
      [ -n "$b" ] && [ "$b" != "$old_boot" ] && break
      qemu_running || die "VM exited during reboot; see $SERIAL_LOG"
      sleep 3
    done
    wait_for_ssh 300
  fi
  info "VM ready: ./ssh.sh"
fi
