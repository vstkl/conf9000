#!/usr/bin/env bash
# ssh into the test VM with the VM-only key (never your ~/.ssh keys/config).
#   ./ssh.sh                 interactive shell
#   ./ssh.sh CMD ARGS...     run a command
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

case "${1:-}" in
  -h|--help)
    echo "Usage: $(basename "$0") [ssh-args] [command...]  (user $VM_USER @ 127.0.0.1:$SSH_PORT)"
    exit 0 ;;
esac
vm_running || die "VM not running (./start.sh)"
[ -f "$SSH_KEY" ] || die "no VM ssh key (./setup.sh)"
vm_ssh "$@"
