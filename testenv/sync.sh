#!/usr/bin/env bash
# Copy this repo (working tree, incl. uncommitted changes) into the VM at
# ~/conf9000, skipping everything listed in sync-exclude.txt.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

EXCLUDES="$TESTENV_DIR/sync-exclude.txt"
DRY=0
usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run]

rsync $REPO_DIR/ -> VM:$REMOTE_REPO/
Exclusions (secrets, app state, VM images): $EXCLUDES
Files in the VM copy that are gone (or excluded) locally are deleted.

  --dry-run   only list what would be transferred
  -h, --help  show this help
EOF
}
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

vm_running || die "VM not running (./start.sh)"
[ -f "$EXCLUDES" ] || die "missing $EXCLUDES"

mapfile -t opts < <(ssh_opts)
rsh="ssh $(printf '%q ' "${opts[@]}")"

flags=(-a --delete --delete-excluded --exclude-from="$EXCLUDES" --info=stats1)
[ "$DRY" -eq 1 ] && flags+=(--dry-run --itemize-changes)

vm_ssh "mkdir -p '$REMOTE_REPO'"
info "syncing $REPO_DIR -> $VM_USER@vm:$REMOTE_REPO"
rsync "${flags[@]}" -e "$rsh" "$REPO_DIR/" "$VM_USER@127.0.0.1:$REMOTE_REPO/"

# belt and braces: make sure nothing sensitive slipped through
leak="$(vm_ssh "cd '$REMOTE_REPO' && find . -maxdepth 2 \\( -path ./Bitwarden -o -path ./Signal -o -path ./mozilla -o -path ./gh \\
  -o -path ./github-copilot -o -path ./opencode -o -path ./dconf -o -path ./nvim/undodir -o -path ./testenv/ssh \\) -print | head -5;
  find . \\( -iname '*token*' -o -name '*.pem' -o -name '*.key' \\) -print | head -5")"
[ -z "$leak" ] || die "sensitive paths present in VM copy after sync: $leak"

# recreate-environment.sh symlinks every top-level repo dir into ~/.config; when a
# dir becomes excluded, --delete-excluded removes it and leaves a dangling link.
# Remove such links (only ones pointing into the synced repo).
removed="$(vm_ssh "if [ -d ~/.config ]; then find ~/.config -maxdepth 1 -xtype l -lname '$REMOTE_REPO/*' -print -delete; fi")"
[ -z "$removed" ] || { echo "removed dangling ~/.config links to excluded dirs:"; echo "$removed" | sed 's/^/  /'; }
# local tinty templates are built inside the repo (gitignored), so --delete just removed the
# build; rebuild it so `tinty apply` keeps working in the VM
vm_ssh 'command -v tinty >/dev/null && [ -d ~/.config/tinted-theming/conf9000-templates ] &&
  tinty build ~/.config/tinted-theming/conf9000-templates --quiet' || true
# same for tmux plugins (installed by tpm into the repo copy, gitignored)
# tpm itself is a git submodule that is empty in an uninitialized host checkout: init it in the VM
vm_ssh "git -C '$REMOTE_REPO' submodule update --init --quiet" || true
# (tpm's installer uses the "default" tmux server: give it a private one via TMUX_TMPDIR, which
# loads tmux.conf and so tpm, without touching sessions that are running in the VM)
vm_ssh 'i=~/.config/tmux/plugins/tpm/bin/install_plugins; [ -x "$i" ] || exit 0
  d=$(mktemp -d); export TMUX_TMPDIR=$d
  tmux new-session -d -s install && sleep 1 && "$i" >/dev/null 2>&1
  tmux kill-server 2>/dev/null; rm -rf "$d"; true' || true
info "sync done"
