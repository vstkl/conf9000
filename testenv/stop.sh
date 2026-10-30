#!/usr/bin/env bash
# Shut the test VM down (graceful via ssh/ACPI, then kill as last resort).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FORCE=0
usage() {
  cat <<EOF
Usage: $(basename "$0") [--force]

  --force    kill qemu immediately (no clean guest shutdown)
  -h, --help show this help
EOF
}
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if libvirt_running && ! qemu_running; then
  info "the running VM is the libvirt one; use ./virt-manager.sh stop"
  exit 0
fi
if ! qemu_running; then
  info "VM not running"
  rm -f "$PIDFILE" "$MONITOR_SOCK"
  exit 0
fi
pid="$(cat "$PIDFILE")"

wait_gone() {
  local i
  for i in $(seq 1 "$1"); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 1
  done
  return 1
}

if [ "$FORCE" -eq 0 ]; then
  info "requesting guest poweroff"
  vm_ssh -o BatchMode=yes 'sudo systemctl poweroff' >/dev/null 2>&1 || true
  if ! wait_gone 60 && [ -S "$MONITOR_SOCK" ] && command -v python3 >/dev/null; then
    info "ssh poweroff timed out, sending ACPI powerdown"
    python3 - "$MONITOR_SOCK" <<'PY' || true
import socket, sys
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); s.sendall(b"system_powerdown\n"); s.close()
PY
    wait_gone 30 || true
  fi
fi
if kill -0 "$pid" 2>/dev/null; then
  info "killing qemu ($pid)"
  kill "$pid" 2>/dev/null || true
  wait_gone 10 || kill -9 "$pid" 2>/dev/null || true
fi
rm -f "$PIDFILE" "$MONITOR_SOCK"
info "VM stopped"
