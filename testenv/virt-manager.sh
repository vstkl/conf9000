#!/usr/bin/env bash
# Run the test VM under libvirt's per-user session (qemu:///session, no root) so
# virt-manager can show its display. Uses the same overlay/seed as start.sh, so
# sync.sh / check.sh / ssh.sh keep working (ssh is forwarded to 127.0.0.1:$SSH_PORT via passt).
# The raw-QEMU VM (start.sh) and this domain share one disk: only one may run at a time.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

URI="$LIBVIRT_URI"
DOMAIN="$LIBVIRT_DOMAIN"
XML="$RUN_DIR/$DOMAIN.xml"
GL=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--gl] COMMAND

  up        define (if needed), start the domain, wait for ssh, open virt-manager
  define    (re)write the libvirt domain XML and define it in $URI
  start     start the domain (stops the raw-QEMU VM from start.sh first)
  open      open virt-manager on the domain's console
  stop      graceful shutdown (force off after 60s)
  undefine  stop and remove the domain from libvirt (disk images are kept)

  --gl      virtio-gpu with virgl 3D (needed for Hyprland; uses host OpenGL).
            Without it, start sway in the VM with: WLR_RENDERER=pixman sway

Console login: $VM_USER / test. ssh: ./ssh.sh
EOF
}

virsh_() { timeout 60 virsh -c "$URI" "$@"; }

preflight_libvirt() {
  preflight
  local t
  for t in virsh virt-manager passt; do
    command -v "$t" >/dev/null || die "preflight: missing $t (sudo pacman -S libvirt virt-manager passt)"
  done
  # qemu:///session spawns a per-user daemon on demand; a hang here means libvirt is broken/stuck.
  timeout 20 virsh -c "$URI" uri >/dev/null 2>&1 \
    || die "preflight: cannot reach $URI within 20s. Check: systemctl --user status virtqemud.socket; systemctl is-active libvirtd"
  [ -f "$OVERLAY" ] && [ -f "$SEED_ISO" ] || die "no overlay/seed yet -- run ./setup.sh first"
}

domain_exists() { virsh_ dominfo "$DOMAIN" >/dev/null 2>&1; }
domain_running() { [ "$(virsh_ domstate "$DOMAIN" 2>/dev/null)" = "running" ]; }

write_xml() {
  local video graphics
  if [ "$GL" = 1 ]; then
    video="<model type='virtio' heads='1' primary='yes'><acceleration accel3d='yes'/></model>"
    graphics="<graphics type='spice'><listen type='none'/><gl enable='yes'/></graphics>"
  else
    video="<model type='virtio' heads='1' primary='yes'/>"
    graphics="<graphics type='spice' autoport='yes'><listen type='address' address='127.0.0.1'/></graphics>"
  fi
  mkdir -p "$RUN_DIR"
  cat >"$XML" <<EOF
<domain type='kvm'>
  <name>$DOMAIN</name>
  <memory unit='MiB'>$VM_MEM</memory>
  <vcpu>$VM_CPUS</vcpu>
  <os><type arch='x86_64' machine='q35'>hvm</type><boot dev='hd'/></os>
  <features><acpi/><apic/></features>
  <cpu mode='host-passthrough'/>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' discard='unmap'/>
      <source file='$OVERLAY'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='$SEED_ISO'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>
    <interface type='user'>
      <!-- same MAC as raw QEMU's default NIC: cloud-init pinned the guest network config to it -->
      <mac address='52:54:00:12:34:56'/>
      <backend type='passt'/>
      <model type='virtio'/>
      <portForward proto='tcp' address='127.0.0.1'>
        <range start='$SSH_PORT' to='22'/>
      </portForward>
    </interface>
    <serial type='pty'><target port='0'/></serial>
    <console type='pty'><target type='serial' port='0'/></console>
    <channel type='spicevmc'><target type='virtio' name='com.redhat.spice.0'/></channel>
    <input type='tablet' bus='usb'/>
    <input type='keyboard' bus='virtio'/>
    $graphics
    <video>$video</video>
    <rng model='virtio'><backend model='random'>/dev/urandom</backend></rng>
  </devices>
</domain>
EOF
}

cmd_define() {
  if domain_exists; then
    domain_running && die "$DOMAIN is running; ./$(basename "$0") stop first"
    virsh_ undefine "$DOMAIN" >/dev/null
  fi
  write_xml
  virsh_ define "$XML" >/dev/null
  info "defined $DOMAIN in $URI ($([ "$GL" = 1 ] && echo 'virgl 3D' || echo '2D virtio-gpu'))"
}

cmd_start() {
  domain_exists || cmd_define
  domain_running && { info "$DOMAIN already running"; return; }
  if qemu_running; then
    info "stopping raw-QEMU VM (start.sh) -- it holds the same disk"
    timeout 120 "$TESTENV_DIR/stop.sh"
  fi
  virsh_ start "$DOMAIN" >/dev/null
  info "started $DOMAIN; waiting for ssh on 127.0.0.1:$SSH_PORT"
  local t=0
  until vm_ssh -o BatchMode=yes true 2>/dev/null; do
    domain_running || die "$DOMAIN stopped; see: virsh -c $URI console $DOMAIN"
    t=$((t + 3)); [ "$t" -ge 300 ] && die "ssh not reachable after 300s (open the console in virt-manager to see why)"
    sleep 3
  done
  info "VM ready: ./ssh.sh  (console login $VM_USER / test)"
}

cmd_open() {
  domain_exists || die "$DOMAIN not defined; run: $(basename "$0") up"
  setsid -f virt-manager --connect "$URI" --show-domain-console "$DOMAIN" >/dev/null 2>&1
  info "virt-manager opened on $DOMAIN"
}

cmd_stop() {
  domain_running || { info "$DOMAIN not running"; return; }
  virsh_ shutdown "$DOMAIN" >/dev/null || true
  local t=0
  while domain_running; do
    t=$((t + 2)); [ "$t" -ge 60 ] && { virsh_ destroy "$DOMAIN" >/dev/null; break; }
    sleep 2
  done
  info "$DOMAIN stopped"
}

cmd_undefine() {
  domain_exists || { info "$DOMAIN not defined"; return; }
  cmd_stop
  virsh_ undefine "$DOMAIN" >/dev/null
  info "undefined $DOMAIN (images kept)"
}

CMD=""
for arg in "$@"; do
  case "$arg" in
    --gl) GL=1 ;;
    -h|--help) usage; exit 0 ;;
    up|define|start|open|stop|undefine) CMD="$arg" ;;
    *) usage >&2; exit 1 ;;
  esac
done
[ -n "$CMD" ] || { usage >&2; exit 1; }

preflight_libvirt
case "$CMD" in
  up) [ "$GL" = 1 ] && cmd_define; cmd_start; cmd_open ;;
  define) cmd_define ;;
  start) cmd_start ;;
  open) cmd_open ;;
  stop) cmd_stop ;;
  undefine) cmd_undefine ;;
esac
