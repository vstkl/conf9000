#!/usr/bin/env bash
# Download + verify the Arch Linux cloud image, generate the VM ssh key,
# build the cloud-init seed ISO and create the disposable qcow2 overlay.
# Rootless. Safe to re-run: finished steps are skipped.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REFRESH=0
PIN_VERSION=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--refresh] [--image-version VERSION]

Prepares testenv/images/:
  base.qcow2     -> pinned Arch cloud image (SHA256-verified, read-only base)
  seed.iso       cloud-init NoCloud seed (user '$VM_USER', passwordless sudo, VM-only ssh key)
  overlay.qcow2  copy-on-write overlay ($VM_DISK_SIZE virtual); the VM only ever writes here

  --refresh                look up the newest image on the mirror even if a base
                           image is already present (an existing overlay is kept;
                           run ./reset.sh afterwards to rebase onto the new image)
  --image-version VERSION  pin a specific image build, e.g. 20261015.611680
  -h, --help               show this help

Environment overrides: TESTENV_IMAGE_BASE_URL, TESTENV_DISK_SIZE, TESTENV_MEM,
TESTENV_CPUS, TESTENV_SSH_PORT (see lib.sh).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --refresh) REFRESH=1 ;;
    --image-version) PIN_VERSION="${2:?--image-version needs a value}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

preflight
need() { command -v "$1" >/dev/null || die "missing host tool: $1"; }
for t in qemu-system-x86_64 qemu-img curl sha256sum ssh-keygen ssh rsync; do need "$t"; done

mkdir -p "$IMAGES_DIR" "$LOGS_DIR" "$RUN_DIR" "$SSH_DIR"
chmod 700 "$SSH_DIR"

# --- 1. dedicated ssh key (never the user's ~/.ssh) ---------------------------
if [ ! -f "$SSH_KEY" ]; then
  info "generating VM-only ssh key $SSH_KEY"
  ssh-keygen -q -t ed25519 -N '' -C "conf9000-testenv" -f "$SSH_KEY"
fi

# --- 2. base image -----------------------------------------------------------
fetch_base() {
  local version="$PIN_VERSION" name
  if [ -z "$version" ]; then
    info "looking up newest $IMAGE_FLAVOR on $IMAGE_BASE_URL"
    version="$(curl -fsSL "$IMAGE_BASE_URL/" \
      | grep -oE "${IMAGE_FLAVOR}-[0-9]+\.[0-9]+\.qcow2\"" \
      | sed -E "s/^${IMAGE_FLAVOR}-//; s/\.qcow2\"$//" | sort -V | tail -1)" \
      || true
    [ -n "$version" ] || die "could not determine image version from $IMAGE_BASE_URL/ (use --image-version)"
  fi
  name="${IMAGE_FLAVOR}-${version}.qcow2"
  local img="$IMAGES_DIR/$name" sum="$IMAGES_DIR/$name.SHA256"

  if [ ! -f "$img" ]; then
    # an explicit old pin may no longer be under /latest -> try the archive
    local url="$IMAGE_BASE_URL"
    if ! curl -fsSI "$url/$name" >/dev/null 2>&1; then
      url="https://archive.archlinux.org/images/$version"
    fi
    info "downloading $name.SHA256"
    curl -fsSL -o "$sum" "$url/$name.SHA256"
    info "downloading $name (~550 MB, resumable)"
    curl -fL -# --retry 3 -C - -o "$img.part" "$url/$name"
    info "verifying SHA256"
    (cd "$IMAGES_DIR" && sed "s#  .*#  $name.part#" "$name.SHA256" | sha256sum -c --quiet -) \
      || { rm -f "$img.part"; die "checksum mismatch for $name (partial download removed, re-run)"; }
    mv "$img.part" "$img"
    chmod a-w "$img"
  else
    info "base image $name already present"
  fi
  ln -sfn "$name" "$BASE_LINK"
}

if [ ! -e "$BASE_LINK" ] || [ "$REFRESH" -eq 1 ] || [ -n "$PIN_VERSION" ]; then
  fetch_base
else
  info "using existing base image $(readlink "$BASE_LINK")"
fi
base_name="$(readlink "$BASE_LINK")"
if [ -f "$IMAGES_DIR/$base_name.SHA256" ]; then
  info "re-verifying base image checksum"
  (cd "$IMAGES_DIR" && sha256sum --quiet -c "$base_name.SHA256") || die "base image checksum mismatch: $base_name"
fi

# --- 3. cloud-init seed --------------------------------------------------------
build_seed() {
  local tmp; tmp="$(mktemp -d)"
  local pubkey; pubkey="$(cat "$SSH_KEY.pub")"
  cat > "$tmp/user-data" <<UD
#cloud-config
hostname: $VM_HOSTNAME
ssh_pwauth: false
disable_root: true
users:
  - name: $VM_USER
    gecos: conf9000 test user
    groups: [wheel]
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: false
    ssh_authorized_keys:
      - $pubkey
chpasswd:
  expire: false
  users:
    - {name: $VM_USER, password: test, type: text}
growpart: {mode: auto, devices: ["/"]}
resize_rootfs: true
runcmd:
  - [sh, -c, "pacman -Syu --noconfirm --needed rsync git sudo base-devel python > /var/log/testenv-firstboot.log 2>&1; echo rc=\$? >> /var/log/testenv-firstboot.log"]
  - [touch, /var/lib/testenv-provisioned]
UD
  local iid; iid="conf9000-$(sha256sum "$tmp/user-data" | cut -c1-12)"
  printf 'instance-id: %s\nlocal-hostname: %s\n' "$iid" "$VM_HOSTNAME" > "$tmp/meta-data"

  rm -f "$SEED_ISO.new"
  if command -v cloud-localds >/dev/null; then
    cloud-localds "$SEED_ISO.new" "$tmp/user-data" "$tmp/meta-data"
  elif command -v xorriso >/dev/null; then
    xorriso -as mkisofs -quiet -output "$SEED_ISO.new" -volid cidata -joliet -rock \
      "$tmp/user-data" "$tmp/meta-data" 2>/dev/null
  elif command -v genisoimage >/dev/null; then
    genisoimage -quiet -output "$SEED_ISO.new" -volid cidata -joliet -rock "$tmp/user-data" "$tmp/meta-data"
  elif command -v mkisofs >/dev/null; then
    mkisofs -quiet -output "$SEED_ISO.new" -volid cidata -joliet -rock "$tmp/user-data" "$tmp/meta-data"
  else
    rm -rf "$tmp"
    die "need one of cloud-localds, xorriso, genisoimage, mkisofs (e.g. pacman -S libisoburn)"
  fi
  mv "$SEED_ISO.new" "$SEED_ISO"
  rm -rf "$tmp"
}
info "building cloud-init seed $SEED_ISO"
build_seed

# --- 4. overlay -------------------------------------------------------------------
if [ ! -f "$OVERLAY" ]; then
  info "creating overlay $OVERLAY ($VM_DISK_SIZE) on top of $base_name"
  qemu-img create -q -f qcow2 -F qcow2 -b "$base_name" "$OVERLAY" "$VM_DISK_SIZE"
else
  info "overlay already exists (use ./reset.sh to discard it)"
fi

if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  info "KVM available: VM will be hardware accelerated"
else
  echo "warning: /dev/kvm not accessible -> VM falls back to slow TCG emulation" >&2
fi
info "setup done. Next: ./start.sh && ./sync.sh && ./run-bootstrap.sh && ./check.sh"
