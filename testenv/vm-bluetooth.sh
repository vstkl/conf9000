#!/usr/bin/env bash
# Give the test VM a virtual Bluetooth adapter (no USB passthrough needed): a bumble-emulated
# controller on /dev/vhci (vm/vbt.py), run as vbt.service before bluetooth.service.
# Enough for bluetoothctl/bluetui/waybar's bluetooth module to see a powered adapter.
#   ./vm-bluetooth.sh          install + start (idempotent)
#   ./vm-bluetooth.sh --remove stop + remove
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

case "${1:-}" in
  -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
  --remove)
    vm_running || die "VM not running"
    vm_ssh 'sudo systemctl disable --now vbt.service 2>/dev/null; sudo rm -f /etc/systemd/system/vbt.service; sudo systemctl daemon-reload'
    info "virtual bluetooth adapter removed"; exit 0 ;;
esac

vm_running || die "VM not running (./start.sh or ./virt-manager.sh start)"
vm_ssh 'mkdir -p ~/.bumble && cat > ~/.bumble/vbt.py' <"$TESTENV_DIR/vm/vbt.py"
timeout 600 bash -c "$(declare -f vm_ssh ssh_opts); $(declare -p SSH_KEY SSH_PORT VM_USER); vm_ssh '
  set -e
  [ -x ~/.bumble/bin/python ] || python -m venv ~/.bumble
  ~/.bumble/bin/python -c \"import bumble\" 2>/dev/null || ~/.bumble/bin/pip install -q bumble
  sudo tee /etc/systemd/system/vbt.service >/dev/null <<UNIT
[Unit]
Description=Virtual Bluetooth adapter (bumble on /dev/vhci) for testenv
Before=bluetooth.service

[Service]
ExecStartPre=/usr/bin/modprobe hci_vhci
ExecStart=/home/$VM_USER/.bumble/bin/python /home/$VM_USER/.bumble/vbt.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
  sudo systemctl stop vbt.service 2>/dev/null || true
  sudo systemctl daemon-reload
  sudo systemctl enable --now vbt.service
  sleep 3
  sudo systemctl restart bluetooth.service
  sleep 2
  timeout 5 bluetoothctl list
'"
info "virtual bluetooth adapter ready"
