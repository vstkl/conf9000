#!/usr/bin/env bash
# Smoke test of the deployed dotfiles, run INSIDE the VM.
#   ./check.sh            (host) upload this script to the VM, run it there, log to logs/
#   ./check.sh --local    (inside the VM, or any machine you dare) run the checks here
# Prints PASS/FAIL/WARN/SKIP per check; exit code 1 if any FAIL.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [--local] [--repo DIR] [--no-gui-tests]

  --local         run the checks on this machine instead of in the VM
  --repo DIR      repo location inside the VM (default: ~/conf9000)
  --no-gui-tests  skip the headless sway/clipboard test
  -h, --help      show this help
Checks: bash -n + shellcheck on bashrc/scripts, interactive & login shell start
with empty stderr, prompt rendering (git branch / exit code), dotfile symlinks,
sway -C / scroll -C / Hyprland --verify-config, waybar JSONC, tmux config,
cliphist via headless sway, bluetooth.sh toggle.
EOF
}

LOCAL=0
REPO=""
GUI_TESTS=1
ARGS=("$@")
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1 ;;
    --repo) REPO="${2:?}"; shift ;;
    --no-gui-tests) GUI_TESTS=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# host side: ship ourselves to the VM
# ---------------------------------------------------------------------------
if [ "$LOCAL" -eq 0 ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
  vm_running || die "VM not running (./start.sh)"
  mkdir -p "$LOGS_DIR"
  LOG="$LOGS_DIR/check-$(date +%Y%m%d-%H%M%S).log"
  vm_ssh "cat > /tmp/testenv-check.sh" < "${BASH_SOURCE[0]}"
  set +e
  extra=""; [ ${#ARGS[@]} -gt 0 ] && extra="$(printf '%q ' "${ARGS[@]}")"
  vm_ssh "bash /tmp/testenv-check.sh --local $extra </dev/null" 2>&1 | tee "$LOG"
  rc=${PIPESTATUS[0]}
  set -e
  echo "log: $LOG"
  exit "$rc"
fi

# ---------------------------------------------------------------------------
# VM side
# ---------------------------------------------------------------------------
REPO="${REPO:-$HOME/conf9000}"
CFG="$HOME/.config"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
NPASS=0 NFAIL=0 NWARN=0 NSKIP=0

# report STATUS NAME [DETAIL...]
report() {
  local st="$1" name="$2"; shift 2
  case "$st" in
    PASS) NPASS=$((NPASS + 1)) ;; FAIL) NFAIL=$((NFAIL + 1)) ;;
    WARN) NWARN=$((NWARN + 1)) ;; SKIP) NSKIP=$((NSKIP + 1)) ;;
  esac
  printf '%-4s  %s\n' "$st" "$name"
  local d
  for d in "$@"; do
    [ -n "$d" ] && printf '%s\n' "$d" | head -n 15 | sed 's/^/        | /'
  done
  return 0
}
have() { command -v "$1" >/dev/null 2>&1; }

# run a command in a pseudo-terminal (so `bash -i` behaves like a real
# terminal: no "no job control" noise). Writes stdout to $1, stderr to $2.
in_pty() {
  local out="$1" err="$2"; shift 2
  local cmd; cmd="$(printf '%q ' "$@")"
  script -qec "$cmd >$(printf '%q' "$out") 2>$(printf '%q' "$err")" /dev/null >/dev/null 2>&1 </dev/null
}

echo "### conf9000 smoke test on $(uname -n) ($(uname -r)) as $USER, repo=$REPO, $(date -Is)"

# --- 1. syntax: bash -n ---------------------------------------------------------
shell_files=()
for f in "$REPO/bashrc" "$REPO/recreate-environment.sh" "$REPO/after-install.sh" \
         "$REPO/install_optdeps.sh" "$REPO"/scripts/* "$REPO"/sway/*.sh \
         "$REPO"/waybar/scripts/*.sh "$REPO"/hypr/scripts/*.sh; do
  [ -f "$f" ] && shell_files+=("$f")
done
for f in "${shell_files[@]}"; do
  rel="${f#"$REPO"/}"
  if out="$(bash -n "$f" 2>&1)"; then report PASS "bash -n $rel"; else report FAIL "bash -n $rel" "$out"; fi
done

# --- 2. shellcheck ------------------------------------------------------------------
if have shellcheck; then
  for f in "${shell_files[@]}"; do
    rel="${f#"$REPO"/}"
    if out="$(shellcheck -s bash -S error -f gcc "$f" 2>&1)"; then
      nw="$(shellcheck -s bash -S warning -f gcc "$f" 2>/dev/null | grep -c ': warning:' || true)"
      if [ "$nw" -gt 0 ]; then
        report WARN "shellcheck $rel (0 errors, $nw warnings)" \
          "$(shellcheck -s bash -S warning -f gcc "$f" 2>/dev/null | sed "s#^$REPO/##" | head -5)"
      else
        report PASS "shellcheck $rel"
      fi
    else
      report FAIL "shellcheck $rel (errors)" "$(printf '%s\n' "$out" | sed "s#^$REPO/##")"
    fi
  done
else
  report SKIP "shellcheck (not installed)"
fi

# --- 3. shell startup ------------------------------------------------------------------
for mode in "-ic" "-lic"; do
  in_pty "$WORK/o" "$WORK/e" bash "$mode" exit || true
  if [ ! -s "$WORK/e" ]; then
    report PASS "bash $mode exit: stderr empty"
  else
    report FAIL "bash $mode exit: stderr not empty" "$(cat "$WORK/e")"
  fi
done

# --- 4. prompt rendering ----------------------------------------------------------------
# strip \001/\002 (readline markers) and ANSI colors from an expanded PS1
clean_ps1() { tr -d '\001\002' < "$1" | sed 's/\x1b\[[0-9;]*m//g'; }
render_ps1() {  # render_ps1 DIR PRE-CMD -> $WORK/ps1
  in_pty "$WORK/ps1" "$WORK/ps1err" bash -ic "cd $(printf '%q' "$1") && $2; __prompt; printf '%s' \"\${PS1@P}\"" || true
}
if grep -q '__prompt' "$HOME/.bashrc" 2>/dev/null; then
  gitdir="$WORK/repo"
  git init -q -b testenv-branch "$gitdir" 2>/dev/null || { mkdir -p "$gitdir"; git -C "$gitdir" init -q; git -C "$gitdir" checkout -q -b testenv-branch; }
  render_ps1 "$gitdir" true
  ps1="$(clean_ps1 "$WORK/ps1")"
  if printf '%s' "$ps1" | grep -q 'testenv-branch'; then
    report PASS "prompt in git repo shows branch" "$(printf '%s' "$ps1" | cat -v)"
  else
    report FAIL "prompt in git repo shows branch" "PS1 rendered as: $(printf '%s' "$ps1" | cat -v)" "$(cat "$WORK/ps1err")"
  fi

  if [ -d "$REPO/.git" ]; then
    br="$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    render_ps1 "$REPO" true
    ps1="$(clean_ps1 "$WORK/ps1")"
    if [ -n "$br" ] && printf '%s' "$ps1" | grep -qF "($br"; then
      report PASS "prompt in synced repo shows branch '$br'" "$(printf '%s' "$ps1" | cat -v)"
    else
      report FAIL "prompt in synced repo shows branch '$br'" "PS1 rendered as: $(printf '%s' "$ps1" | cat -v)"
    fi
  fi

  plain="$WORK/plain dir"; mkdir -p "$plain"
  render_ps1 "$plain" true
  ps1="$(clean_ps1 "$WORK/ps1")"
  if printf '%s' "$ps1" | grep -qF "plain dir" && ! printf '%s' "$ps1" | grep -q '('; then
    report PASS "prompt outside repo: path shown, no branch" "$(printf '%s' "$ps1" | cat -v)"
  else
    report FAIL "prompt outside repo: path shown, no branch" "PS1 rendered as: $(printf '%s' "$ps1" | cat -v)"
  fi

  render_ps1 "$plain" "(exit 3)"
  ps1="$(clean_ps1 "$WORK/ps1")"
  if printf '%s' "$ps1" | grep -qF '✗3'; then
    report PASS "prompt shows failing exit code" "$(printf '%s' "$ps1" | cat -v)"
  else
    report WARN "prompt shows failing exit code" "PS1 rendered as: $(printf '%s' "$ps1" | cat -v)"
  fi
else
  report SKIP "prompt rendering (~/.bashrc has no __prompt)"
fi

# --- 5. symlinks created by recreate-environment.sh ------------------------------------
missing=() wrong=()
for d in "$REPO"/*/; do
  name="$(basename "$d")"
  case "$name" in guides|dconf) continue ;; esac
  t="$CFG/$name"
  if [ ! -L "$t" ]; then missing+=("$name")
  elif [ "$(readlink -f "$t")" != "$(readlink -f "$d")" ]; then wrong+=("$name -> $(readlink "$t")"); fi
done
for pair in ".bashrc:bashrc" ".config/mimeapps.list:mimeapps.list" ".config/user-dirs.locale:user-dirs.locale" \
            ".config/arch-hero-wallpaper-free.png:arch-hero-wallpaper-free.png"; do
  t="$HOME/${pair%%:*}" s="$REPO/${pair#*:}"
  if [ ! -L "$t" ]; then missing+=("${pair%%:*}")
  elif [ "$(readlink -f "$t")" != "$(readlink -f "$s")" ]; then wrong+=("${pair%%:*}"); fi
done
if [ ${#missing[@]} -eq 0 ] && [ ${#wrong[@]} -eq 0 ]; then
  report PASS "dotfile symlinks ($(find "$CFG" -maxdepth 1 -type l | wc -l) links in ~/.config + ~/.bashrc)"
else
  report FAIL "dotfile symlinks" "missing: ${missing[*]:-none}" "wrong target: ${wrong[*]:-none}"
fi
if [ -d "$REPO/dconf" ]; then
  [ -f "$CFG/dconf/user" ] && report PASS "dconf/user restored (copied)" || report FAIL "dconf/user restored (copied)"
else
  report SKIP "dconf/user restore (dconf/ excluded from sync)"
fi
odd=()
for n in docs testenv guides opencode dconf Bitwarden Signal mozilla gh github-copilot; do [ -L "$CFG/$n" ] && odd+=("$n"); done
[ ${#odd[@]} -eq 0 ] || report FAIL "repo meta / sensitive dirs symlinked into ~/.config: ${odd[*]}"

# --- 6. compositor configs ---------------------------------------------------------------
for wm in sway scroll; do
  conf="$CFG/$wm/config"
  if ! have "$wm"; then report SKIP "$wm -C ($wm not installed)"; continue; fi
  [ -f "$conf" ] || { report FAIL "$wm -C (no $conf)"; continue; }
  # headless backend: over ssh there is no seat, and -C still creates a backend
  if out="$(WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman timeout 30 "$wm" -C -c "$conf" 2>&1)"; then
    report PASS "$wm -C -c ~/.config/$wm/config" "$(printf '%s\n' "$out" | grep -iE 'error|warn' | grep -v drmGetDevices2 || true)"
  else
    report FAIL "$wm -C -c ~/.config/$wm/config" "$out"
  fi
done
if have Hyprland || have hyprland; then
  hl="$(command -v Hyprland || command -v hyprland)"
  if "$hl" --help 2>&1 | grep -q -- '--verify-config'; then
    out="$(XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" timeout 30 "$hl" --verify-config -c "$CFG/hypr/hyprland.conf" 2>&1)" && rc=0 || rc=$?
    if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -qiE 'config error|error in'; then
      report PASS "Hyprland --verify-config"
    else
      report FAIL "Hyprland --verify-config (rc=$rc, $("$hl" --version 2>/dev/null | head -1 | cut -d' ' -f1-2))" \
        "$(printf '%s\n' "$out" | sed 's/\x1b\[[0-9;]*m//g' | sed -n '/Config parsing result/,$p' | head -15)"
    fi
  else
    report SKIP "Hyprland --verify-config (unsupported by this Hyprland)"
  fi
else
  report SKIP "Hyprland --verify-config (hyprland not installed)"
fi

# --- 7. waybar JSONC -------------------------------------------------------------------
if have python3; then
  cat > "$WORK/jsonc.py" <<'PY'
import json, re, sys
def strip(src):
    out, i, n, in_str = [], 0, len(src), False
    while i < n:
        c = src[i]
        if in_str:
            out.append(c)
            if c == '\\' and i + 1 < n: out.append(src[i+1]); i += 2; continue
            if c == '"': in_str = False
            i += 1
        elif c == '"': in_str = True; out.append(c); i += 1
        elif src.startswith('//', i):
            j = src.find('\n', i); i = n if j < 0 else j
        elif src.startswith('/*', i):
            j = src.find('*/', i + 2); i = n if j < 0 else j + 2
        else: out.append(c); i += 1
    return re.sub(r',(\s*[}\]])', r'\1', ''.join(out))
rc = 0
for p in sys.argv[1:]:
    try:
        json.loads(strip(open(p, encoding='utf-8').read())); print("ok   " + p)
    except Exception as e:
        print("bad  %s: %s" % (p, e)); rc = 1
sys.exit(rc)
PY
  wb=()
  for f in "$CFG"/waybar/config "$CFG"/waybar/config.jsonc "$CFG"/waybar/Modules* \
           "$CFG"/waybar/UserModules "$CFG"/waybar/configs/*; do
    [ -f "$f" ] && wb+=("$f")
  done
  for f in "${wb[@]}"; do
    rel="${f#"$CFG"/}"
    if out="$(python3 "$WORK/jsonc.py" "$f" 2>&1)"; then report PASS "JSONC $rel"
    else report FAIL "JSONC $rel" "$(printf '%s' "$out" | sed 's/^bad  [^:]*: //')"; fi
  done
else
  report SKIP "waybar JSONC (no python3)"
fi

# --- 8. tmux ---------------------------------------------------------------------------
if have tmux && [ -f "$CFG/tmux/tmux.conf" ]; then
  out="$(tmux -L testenv-check -f /dev/null new-session -d \; source-file "$CFG/tmux/tmux.conf" 2>&1; tmux -L testenv-check kill-server 2>/dev/null)" || true
  if [ -z "$out" ]; then report PASS "tmux source-file ~/.config/tmux/tmux.conf"
  else report FAIL "tmux source-file ~/.config/tmux/tmux.conf" "$out"; fi
else
  report SKIP "tmux config (tmux or config missing)"
fi

# --- 9. clipboard: headless sway + cliphist watcher from the config ---------------------
clip_test() {
  local miss=()
  for t in sway wl-copy wl-paste cliphist; do have "$t" || miss+=("$t"); done
  [ ${#miss[@]} -eq 0 ] || { report SKIP "cliphist via headless sway (missing: ${miss[*]})"; return; }
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  [ -d "$XDG_RUNTIME_DIR" ] || { report SKIP "cliphist via headless sway (no XDG_RUNTIME_DIR)"; return; }
  WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
    sway -c "$CFG/sway/config" >"$WORK/sway.log" 2>&1 &
  local spid=$! ipc="" i
  for i in $(seq 1 80); do   # up to 20 s
    ipc="$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*."$spid".sock 2>/dev/null | head -1 || true)"
    [ -n "$ipc" ] && break
    kill -0 "$spid" 2>/dev/null || break
    sleep 0.25
  done
  if [ -z "$ipc" ]; then
    report FAIL "headless sway starts with ~/.config/sway/config" "$(tail -15 "$WORK/sway.log")"
    kill "$spid" 2>/dev/null; return
  fi
  # the watcher must be a process started by the config; take WAYLAND_DISPLAY from its env
  local wpid=""
  for i in $(seq 1 40); do
    wpid="$(pgrep -u "$USER" -f 'wl-paste --type text --watch cliphist store' | head -1 || true)"
    [ -n "$wpid" ] && break
    sleep 0.25
  done
  local sock=""
  [ -n "$wpid" ] && sock="$(tr '\0' '\n' < "/proc/$wpid/environ" 2>/dev/null | sed -n 's/^WAYLAND_DISPLAY=//p')"
  [ -n "$sock" ] || sock="$(ls -t "$XDG_RUNTIME_DIR" | grep -m1 '^wayland-[0-9]*$' || true)"
  report PASS "headless sway starts with ~/.config/sway/config (WAYLAND_DISPLAY=$sock)"
  export WAYLAND_DISPLAY="$sock" SWAYSOCK="$ipc"
  if [ -n "$wpid" ]; then
    report PASS "sway config started 'wl-paste --type text --watch cliphist store'"
  else
    report FAIL "sway config started 'wl-paste --type text --watch cliphist store'" "starting it manually for the next check"
    wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
    sleep 0.5
  fi
  local token="testenv-clip-$$-$RANDOM"
  printf '%s' "$token" | wl-copy
  local found=0
  for i in $(seq 1 20); do
    cliphist list 2>/dev/null | grep -qF "$token" && { found=1; break; }
    sleep 0.25
  done
  if [ "$found" -eq 1 ]; then
    report PASS "wl-copy -> cliphist list shows the copied text"
  else
    report FAIL "wl-copy -> cliphist list shows the copied text" "cliphist list: $(cliphist list 2>&1 | head -3)"
  fi
  if [ -x "$CFG/sway/clipboard.sh" ] || [ -f "$CFG/sway/clipboard.sh" ]; then
    : # interactive picker (fuzzel/rofi) cannot be driven headlessly; syntax is covered above
  fi
  swaymsg exit >/dev/null 2>&1 || kill "$spid" 2>/dev/null
  pkill -u "$USER" -f 'wl-paste --type (text|image) --watch cliphist store' 2>/dev/null || true
  wait "$spid" 2>/dev/null || true
  unset WAYLAND_DISPLAY
}
if [ "$GUI_TESTS" -eq 1 ]; then clip_test; else report SKIP "cliphist via headless sway (--no-gui-tests)"; fi

# --- 10. bluetooth.sh toggle ---------------------------------------------------------------
bt="$CFG/waybar/scripts/bluetooth.sh"
if [ -f "$bt" ]; then
  if have bluetoothctl; then
    systemctl is-active -q bluetooth 2>/dev/null || sudo -n systemctl start bluetooth 2>/dev/null || true
    out="$(timeout 15 bash "$bt" toggle 2>&1)" && rc=0 || rc=$?
    if printf '%s' "$out" | grep -qi 'syntax error'; then
      report FAIL "bluetooth.sh toggle (syntax error)" "$out"
    else
      st=PASS; [ "$rc" -eq 0 ] || st=WARN
      report "$st" "bluetooth.sh toggle runs (rc=$rc; bluetoothd $(systemctl is-active bluetooth 2>/dev/null))" \
        "$(printf '%s' "$out" | head -5)"
    fi
  else
    report SKIP "bluetooth.sh toggle (bluez-utils not installed)"
  fi
else
  report SKIP "bluetooth.sh toggle (no $bt)"
fi

echo
echo "### summary: $NPASS pass, $NFAIL fail, $NWARN warn, $NSKIP skip"
[ "$NFAIL" -eq 0 ]
