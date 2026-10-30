# testenv — disposable VM for testing conf9000 changes

A rootless QEMU/KVM virtual machine running the official Arch Linux cloud image.
Config changes from this repo are copied into it, deployed with
`recreate-environment.sh` and smoke-tested, without touching the real system
(your `~/.config`, `~/.ssh` and the host package set are never used or modified).

- Base: `Arch-Linux-x86_64-cloudimg-<version>.qcow2` from
  `https://geo.mirror.pkgbuild.com/images/latest/`, SHA256-verified, kept read-only.
- All VM writes go to `images/overlay.qcow2` (copy-on-write). Reset = delete it.
- cloud-init (NoCloud seed ISO built with xorriso) creates user **m** (same as the
  real machine, so hardcoded `/home/m` paths behave), passwordless sudo, ssh key-only,
  and runs `pacman -Syu rsync git base-devel python` on first boot.
- Networking: QEMU user mode; ssh is forwarded to `127.0.0.1:2222`.
- A dedicated key pair is generated in `testenv/ssh/` (gitignored). ssh runs with
  `-F /dev/null`, `IdentitiesOnly=yes` and no agent, so your own keys and config are never used.
- Headless by default; `--gui` opens a virtio-vga window for sway, Hyprland or waybar.
- No sudo is needed and libvirt is not used, so libvirtd does not need to be running.

## Quick start

```bash
cd testenv
./setup.sh          # once: download + verify image, ssh key, seed ISO, overlay (~550 MB)
./start.sh          # boot headless, wait for ssh + cloud-init (first boot ~3-4 min, reboots once if the kernel was upgraded)
./sync.sh           # copy the repo working tree into the VM at ~/conf9000 (see exclusions below)
./run-bootstrap.sh  # minimal packages + recreate-environment.sh --skip-packages, log -> logs/
./check.sh          # smoke tests inside the VM, PASS/FAIL per check, log -> logs/
./stop.sh           # shut down
```

Iterating on a change: edit the repo, then run `./sync.sh && ./check.sh`. The
`~/.config` entries in the VM are symlinks into `~/conf9000`, so a resync is
enough. Re-run `run-bootstrap.sh` only when you add a new top-level directory or package.

## Scripts (all support `--help`)

| script | what it does |
|---|---|
| `setup.sh [--refresh] [--image-version V]` | Preflight, then ssh key, image download and verify, seed ISO, overlay. Safe to re-run. |
| `start.sh [--gui [--gl] [--display gtk\|sdl]] [--no-wait]` | Preflight, then boots the VM in the background (`run/qemu.pid`; serial console in `logs/serial.log`). |
| `stop.sh [--force]` | Shuts down with `systemctl poweroff` over ssh, then ACPI powerdown, then kill. |
| `reset.sh [--to SNAP] [--stop]` | Deletes the overlay and recreates it from the clean base, or reverts to a saved snapshot. |
| `snapshot.sh save\|list\|delete NAME` | Manages internal qcow2 snapshots (VM must be stopped), e.g. `save pkgs` after a slow install. |
| `ssh.sh [cmd...]` | Opens a shell or runs a command in the VM as `m`. |
| `sync.sh [--dry-run]` | `rsync -a --delete --delete-excluded --exclude-from=sync-exclude.txt`, then a leak check and removal of dangling `~/.config` links. |
| `run-bootstrap.sh [--minimal\|--full] [--build-paru] [-- ARGS]` | Runs `recreate-environment.sh` in the VM. It never passes `--install-bootloader`. |
| `check.sh [--local] [--no-gui-tests]` | Copies itself into the VM and runs the smoke tests there. |
| `nspawn-alternative.sh` | Optional container alternative that needs root. **You** run it with sudo; the agents never do. |

### Preflight
`setup.sh` and `start.sh` first call `preflight` (in `lib.sh`), which checks that
`qemu-system-x86_64`, `qemu-img` and `ssh` exist and that `/dev/kvm` exists and is
readable and writable by you. If `/dev/kvm` is missing or not accessible, it prints the fix
(`sudo usermod -aG kvm $USER`, or enable VT-x and load `kvm_intel`/`kvm_amd`), and the VM then
runs under slow TCG. This testenv calls QEMU directly, so it never needs **libvirtd**.
If a libvirt-based script (virsh or virt-install) is ever added, it must check
`systemctl is-active libvirtd` and tell the user to run `sudo systemctl start libvirtd`.
Every wait has a bound: ssh uses `ConnectTimeout=5`, and the boot, ssh and reboot waits
time out after 300 s and point you to `logs/serial.log`.

### Bootstrap modes
- `--minimal` (default): runs `pacman -Syu` plus bash, bash-completion, fzf, neovim,
  sway, swaybg, waybar, kitty, tmux, git, shellcheck, hyprland, jq, python, ruby, which, file,
  pciutils, cliphist, wl-clipboard, bluetui, bluez, bluez-utils, fuzzel and rofi.
  It installs the prebuilt `paru-bin` from the AUR, then the AUR packages `nvm` (bashrc
  sources it) and `sway-scroll` (provides `scroll`; it is compiled, which takes about 5 min).
  Then it runs `recreate-environment.sh --skip-packages`.
- `--full`: installs the whole `packages` list (1476 packages). This is slow and downloads
  several GB. Afterwards, save the state with `./stop.sh && ./snapshot.sh save full`.
- `--fix-home-paths` is not needed, because the VM user is `m` with `HOME=/home/m`.

### GUI via virt-manager (libvirt user session, no root)
`./virt-manager.sh up` defines the domain `conf9000-testenv` in `qemu:///session`, stops the
raw-QEMU VM if it runs (same disk!), boots it, waits for ssh and opens virt-manager on its console.
Other commands: `define`, `start`, `open`, `stop`, `undefine`; `--gl` = virgl 3D (for Hyprland).
- Networking is passt with ssh forwarded to 127.0.0.1:2222, so `ssh.sh`/`sync.sh`/`check.sh` work unchanged.
- The NIC MAC is pinned to `52:54:00:12:34:56` (raw QEMU's default), because cloud-init bound the
  guest network config to it; with a random MAC the guest has no network and ssh times out.
- In virt-manager the VM is listed under the "QEMU/KVM User session" connection
  (File -> Add Connection -> QEMU/KVM user session, if it isn't there).
- Log in as `m` / `test`, then `WLR_RENDERER=pixman sway` (or plain `sway` with `--gl`).
- Only one of `start.sh` / `virt-manager.sh` may run at a time; each refuses while the other runs.

### Virtual Bluetooth adapter
`./vm-bluetooth.sh` installs `vbt.service` in the VM: a bumble-emulated controller on
`/dev/vhci` (`vm/vbt.py`, python venv in `~/.bumble`), started before `bluetooth.service`.
bluetoothctl / bluetui / waybar then see a powered `hci0`. It is LE-only emulation: scans find
no devices, so it tests the UI, not pairing. `--remove` uninstalls it.

### GUI testing
`./start.sh --gui` opens a GTK window. Log in on the console as `m` with password `test`
(the password works on the console only; ssh accepts keys only). To start sway, run
`WLR_RENDERER=pixman sway`, or `sway` if you used `--gl`. Hyprland needs
`./start.sh --gui --gl`, which requires working host OpenGL.

## sync-exclude.txt: why it matters
`recreate-environment.sh` **symlinks every top-level directory of the repo into
`~/.config`**. Anything that reaches the VM's repo copy ends up in the VM's config,
so `sync-exclude.txt` is the only thing that keeps the following out of the VM:
- app state that may hold secrets: Bitwarden, Signal, gh, github-copilot, evolution,
  mozilla, pulse, ibus, wireshark, libreoffice, totem, vlc, GIMP, inkscape, freerouting,
  goa-1.0, `opencode/` (service.json holds a plaintext password), wordcraft, OpenSCAD,
  fstl-app, `nvim/undodir`, `dconf/` (location data and virt-manager URIs), and user-dirs.dirs
- the repo meta directories `docs/` and `testenv/`
- any file whose name matches `*token*`, `*.key`, `*.pem`, `id_rsa*`, `id_ed25519*` or `.env`
- `.git` hooks and logs (the rest of `.git` is kept so that `git submodule update` works)

`sync.sh` uses `--delete --delete-excluded`, so a path you add to the list is removed
from the VM on the next sync. The dangling `~/.config` links that this leaves are
deleted too. After every sync it also checks that no sensitive path is present in the VM.
Keep this list in sync with any new app-state directory that appears in `~/.config`.

## Files
`images/` (base image, overlay, seed ISO), `logs/`, `run/` and `ssh/` are gitignored
(see `.gitignore`). `lib.sh` holds the shared settings, which you can override with
`TESTENV_MEM`, `TESTENV_CPUS`, `TESTENV_SSH_PORT`, `TESTENV_DISK_SIZE` and `TESTENV_REMOTE_REPO`.

## Last verified run

**2026-10-30** (testenv subagent). Host: Arch, kernel 7.2.7, KVM. Image:
`Arch-Linux-x86_64-cloudimg-20261015.611680.qcow2`, SHA256
`08754e28d91b1680086c6211ef4df13559e766fff7cdb4006489b14b5d281f08` (verified).
Repo working tree included change batch 1 (prompt, clipboard, bluetooth).

Flow: `reset.sh` → `start.sh` → `sync.sh` → `run-bootstrap.sh` (minimal) → `check.sh` → `stop.sh`.
- `start.sh`: first boot plus cloud-init `pacman -Syu` took about 3.5 min. It updated the
  kernel from 7.2.9 to 7.2.11, so the automatic reboot ran. The root filesystem grew to 40 G.
- `sync.sh`: 56 MB copied in about 2 s. Afterwards, none of the excluded paths were present
  in `~/conf9000` or `~/.config` in the VM (verified, including `nvim/undodir`, `dconf`, `docs`,
  `testenv`, `opencode` and `wordcraft`).
- `run-bootstrap.sh --minimal`: exit 0. It installed paru-bin, nvm and sway-scroll (built from
  the AUR), and `recreate-environment.sh --skip-packages` returned 0.
- `check.sh`: **287 pass, 16 fail, 42 warn, 1 skip** (`logs/check-20261030-122539.log`).

| check | result |
|---|---|
| bash -n: bashrc, bootstrap scripts, scripts/*, sway/clipboard.sh, waybar/scripts/bluetooth.sh | PASS |
| bash -n hypr/scripts/RofiEmoji.sh | FAIL. The emoji data follows the code, and `bash -n` parses it. This is most likely harmless at runtime. |
| shellcheck -S error: sway/clipboard.sh, waybar/scripts/bluetooth.sh, recreate-environment.sh | PASS (no warnings either) |
| shellcheck -S error: scripts/idf.sh (SC1113, SC2070), scripts/since.sh (SC1102, SC2071), and 8 vendored hypr/scripts | FAIL |
| `bash -ic exit` / `bash -lic exit` stderr empty | **FAIL**. `scripts/paint.sh` is sourced by bashrc. It runs `tinty apply`, but tinty is not installed and not in `packages`, and it reads `~/.config/color.scheme`, which the bootstrap does not link. |
| prompt: branch shown in a git repo (temp repo and synced repo `live`), path without branch outside a repo, `✗3` after a failure | PASS |
| dotfile symlinks (31 in `~/.config` + `~/.bashrc`) | PASS |
| `sway -C` / `scroll -C` (headless backend) | PASS |
| `Hyprland --verify-config` (VM has Hyprland **0.57.0**, host has 0.56.2) | **FAIL**: `hyprland.conf:2: unexpected symbol near '#'`. 0.57 parses `hyprland.conf` as Lua, so this config breaks on the next Hyprland upgrade. |
| waybar JSONC: config, config.jsonc, Modules, ModulesCustom, ModulesGroups, ModulesVertical, ModulesWorkspaces, UserModules, 42 of 44 configs/* | PASS |
| waybar configs `[TOP & BOT] SummitSplit` and `SummitSplit-glass` | FAIL ("Extra data": text after the closing `]`) |
| tmux source-file | PASS |
| headless sway with the real config; config starts `wl-paste --type text --watch cliphist store`; `wl-copy` text appears in `cliphist list` | PASS |
| `bluetooth.sh toggle` | WARN. There is no syntax error, but the command **hangs** (killed by `timeout` after 15 s, rc 124). With no adapter, bluetoothd does not run, and `bluetoothctl show` waits forever. The waybar middle-click would hang the same way. |

Not verified: `--full` bootstrap (1476 packages), `--gui` mode (needs a desktop
session, so it was not run by the agent), `nspawn-alternative.sh` (needs sudo).
