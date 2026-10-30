#!/usr/bin/env bash
# Save/list/delete named snapshots inside overlay.qcow2 (VM must be stopped).
# Typical use: after a slow package install, `./snapshot.sh save packages`,
# then `./reset.sh --to packages` gets you back there in a second.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") save NAME | list | delete NAME

  save NAME    snapshot the current overlay state (VM must be stopped)
  list         list snapshots
  delete NAME  remove a snapshot
Revert with: ./reset.sh --to NAME     (plain ./reset.sh drops all snapshots)
EOF
}
cmd="${1:-}"
case "$cmd" in
  -h|--help|"") usage; [ -n "$cmd" ]; exit $? ;;
esac
[ -f "$OVERLAY" ] || die "no overlay -- run ./setup.sh first"
case "$cmd" in
  list) qemu-img snapshot -l "$OVERLAY" ;;
  save|delete)
    name="${2:?$cmd needs a NAME}"
    vm_running && die "stop the VM first (./stop.sh)"
    if [ "$cmd" = save ]; then
      qemu-img snapshot -l "$OVERLAY" | awk 'NR>2{print $2}' | grep -qx "$name" \
        && qemu-img snapshot -d "$name" "$OVERLAY"   # idempotent: replace same-named snapshot
      qemu-img snapshot -c "$name" "$OVERLAY"
      info "saved snapshot '$name'"
    else
      qemu-img snapshot -d "$name" "$OVERLAY"
      info "deleted snapshot '$name'"
    fi
    ;;
  *) echo "unknown command: $cmd" >&2; usage >&2; exit 1 ;;
esac
