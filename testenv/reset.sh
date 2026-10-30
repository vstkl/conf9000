#!/usr/bin/env bash
# Throw away VM state: back to the pristine base image, or to a saved snapshot.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TO=""
STOP=0
usage() {
  cat <<EOF
Usage: $(basename "$0") [--to SNAPSHOT] [--stop]

Without --to: delete overlay.qcow2 (and all snapshots in it) and recreate it
from the clean base image. Next ./start.sh re-runs cloud-init first-boot setup.

  --to NAME   instead revert the overlay to a snapshot saved with ./snapshot.sh save NAME
  --stop      stop the VM first if it is running (otherwise reset refuses)
  -h, --help  show this help
EOF
}
while [ $# -gt 0 ]; do
  case "$1" in
    --to) TO="${2:?--to needs a snapshot name}"; shift ;;
    --stop) STOP=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if vm_running; then
  [ "$STOP" -eq 1 ] || die "VM is running; use ./stop.sh (or ./virt-manager.sh stop) first or pass --stop"
  qemu_running && "$TESTENV_DIR/stop.sh"
  libvirt_running && "$TESTENV_DIR/virt-manager.sh" stop
fi
[ -e "$BASE_LINK" ] || die "no base image -- run ./setup.sh first"

if [ -n "$TO" ]; then
  [ -f "$OVERLAY" ] || die "no overlay to revert"
  info "reverting overlay to snapshot '$TO'"
  qemu-img snapshot -a "$TO" "$OVERLAY"
else
  info "discarding overlay"
  rm -f "$OVERLAY"
  qemu-img create -q -f qcow2 -F qcow2 -b "$(readlink "$BASE_LINK")" "$OVERLAY" "$VM_DISK_SIZE"
fi
info "reset done"
