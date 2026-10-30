# esp-ctx.sh – switch between ESP-IDF versions installed in /opt/esp (btrfs subvolumes)
#
# Sourced by ~/.bashrc (every file in ~/.config/scripts is), so this file only defines
# functions. Usage (in any shell):
#
#   esp                      activate the version pinned in ./.esp-idf-version (searched upward),
#                            else your default
#   esp use <tag>            activate a version in this shell, e.g. `esp use v6.1`
#   esp off                  deactivate (strip IDF from PATH, unset IDF_*)
#   esp ls                   list installed versions (* = active, d = your default)
#   esp default <tag>        set your default version
#   esp install <tag> [tgt]  install a version as a new subvolume (CoW snapshot of the nearest
#                            installed version when possible) + its tools for targets
#                            (default: esp32h2; "all" for every chip)
#   esp snap <tag> [name]    read-only btrfs snapshot of a version (before updating/patching)
#   esp rollback <tag> <snapshot>   replace a version with a snapshot
#   esp rm <tag>             delete a version (needs sudo unless user_subvol_rm_allowed)
#   esp pin [tag]            write ./.esp-idf-version for the current project
#   esp setup                one-time root setup of /opt/esp and the "esp" group (asks for sudo)
#
# Layout:
#   /opt/esp/idf/<tag>       one btrfs subvolume per ESP-IDF version (git checkout)
#   /opt/esp/tools           shared IDF_TOOLS_PATH (toolchains, python venvs per IDF version)
#   /opt/esp/.snapshots      read-only snapshots <tag>@<date>[-name]

ESP_ROOT=${ESP_ROOT:-/opt/esp}
ESP_REPO=${ESP_REPO:-https://github.com/espressif/esp-idf.git}
ESP_CFG=${XDG_CONFIG_HOME:-$HOME/.config}/esp-ctx

_esp_msg() { printf '\033[1;36mesp:\033[0m %s\n' "$*" >&2; }
_esp_err() { printf '\033[1;31mesp:\033[0m %s\n' "$*" >&2; return 1; }

_esp_versions() { [ -d "$ESP_ROOT/idf" ] && ls -1 "$ESP_ROOT/idf" 2>/dev/null | sort -V; }

_esp_default() { cat "$ESP_CFG/default" 2>/dev/null; }

_esp_pinned() {                         # nearest .esp-idf-version upward from $PWD
    local d=$PWD
    while [ "$d" != / ]; do
        [ -f "$d/.esp-idf-version" ] && { tr -d ' \n' < "$d/.esp-idf-version"; return; }
        d=$(dirname "$d")
    done
}

_esp_off() {
    local p
    p=$(printf '%s' "$PATH" | tr ':' '\n' | grep -v "^$ESP_ROOT/" | paste -sd:)
    export PATH=$p
    [ -n "$IDF_PYTHON_ENV_PATH" ] && type deactivate >/dev/null 2>&1 && deactivate 2>/dev/null
    unset IDF_PATH IDF_PYTHON_ENV_PATH IDF_TOOLS_EXPORT_CMD IDF_TOOLS_INSTALL_CMD \
          OPENOCD_SCRIPTS ESP_IDF_VERSION ESP_CTX IDF_DEACTIVATE_FILE_PATH ESP_ROM_ELF_DIR
}

_esp_use() {
    local tag=$1
    [ -n "$tag" ] || tag=$(_esp_pinned)
    [ -n "$tag" ] || tag=$(_esp_default)
    [ -n "$tag" ] || { _esp_err "no version given, no .esp-idf-version, no default (esp default <tag>)"; return 1; }
    [ -d "$ESP_ROOT/idf/$tag" ] || { _esp_err "$tag is not installed (esp ls / esp install $tag)"; return 1; }
    _esp_off
    export IDF_TOOLS_PATH=$ESP_ROOT/tools
    export IDF_PATH=$ESP_ROOT/idf/$tag
    # shellcheck disable=SC1091
    . "$IDF_PATH/export.sh" >/dev/null 2>&1 || { _esp_err "export.sh failed; run: esp install $tag"; return 1; }
    export ESP_CTX=$tag   # ESP_IDF_VERSION belongs to IDF (e.g. "6.1")
    _esp_msg "ESP-IDF $tag active ($(idf.py --version 2>/dev/null | head -1))"
}

_esp_ls() {
    local v cur def
    cur=$ESP_CTX; def=$(_esp_default)
    for v in $(_esp_versions); do
        printf '%s%s %s\n' "$([ "$v" = "$cur" ] && echo '*' || echo ' ')" \
                           "$([ "$v" = "$def" ] && echo 'd' || echo ' ')" "$v"
    done
    [ -d "$ESP_ROOT/.snapshots" ] && ls "$ESP_ROOT/.snapshots" 2>/dev/null | sed 's/^/    snapshot /'
}

_esp_nearest() {                        # installed version to snapshot from (highest <= tag, else highest)
    local want=$1 best="" v
    for v in $(_esp_versions); do
        [ "$(printf '%s\n%s\n' "$v" "$want" | sort -V | head -1)" = "$v" ] && best=$v
    done
    [ -n "$best" ] || best=$(_esp_versions | tail -1)
    echo "$best"
}

_esp_install() (                        # subshell: umask/cd/set -e don't leak into the shell
    set -e
    umask 002
    tag=$1; targets=${2:-esp32h2}
    [ -n "$tag" ] || { _esp_err "usage: esp install <tag> [targets]"; exit 1; }
    [ -w "$ESP_ROOT" ] || { _esp_err "$ESP_ROOT not writable - run 'esp setup' and log in again (group esp)"; exit 1; }
    mkdir -p "$ESP_ROOT/idf" "$ESP_ROOT/tools"
    dst=$ESP_ROOT/idf/$tag
    [ -e "$dst" ] && { _esp_err "$tag already installed"; exit 1; }
    src=$(_esp_nearest "$tag")
    if [ -n "$src" ]; then
        _esp_msg "snapshot $src -> $tag (copy-on-write), then switch the checkout"
        btrfs subvolume snapshot "$ESP_ROOT/idf/$src" "$dst" >/dev/null
        git -C "$dst" fetch --depth 1 origin tag "$tag"
        git -C "$dst" -c advice.detachedHead=false checkout -f "$tag"
        git -C "$dst" clean -ffdq
    else
        _esp_msg "fresh clone of $tag"
        btrfs subvolume create "$dst" >/dev/null
        git clone --depth 1 --branch "$tag" "$ESP_REPO" "$dst"
    fi
    git -C "$dst" submodule sync -q --recursive
    git -C "$dst" submodule update --init --recursive --depth 1 --jobs 8
    _esp_msg "installing tools for $targets into $ESP_ROOT/tools"
    IDF_TOOLS_PATH=$ESP_ROOT/tools "$dst/install.sh" "$targets"
    _esp_msg "done - activate with: esp use $tag"
)

_esp_snap() {
    local tag=$1 name=$2 dst
    [ -d "$ESP_ROOT/idf/$tag" ] || { _esp_err "$tag not installed"; return 1; }
    mkdir -p "$ESP_ROOT/.snapshots"
    dst=$ESP_ROOT/.snapshots/$tag@$(date +%Y%m%d-%H%M)${name:+-$name}
    btrfs subvolume snapshot -r "$ESP_ROOT/idf/$tag" "$dst" >/dev/null && _esp_msg "snapshot $dst"
}

_esp_subvol_rm() {
    btrfs subvolume delete "$1" >/dev/null 2>&1 || sudo btrfs subvolume delete "$1" >/dev/null
}

_esp_rollback() {
    local tag=$1 snap=$2
    [ -d "$ESP_ROOT/.snapshots/$snap" ] || { _esp_err "no snapshot $snap (esp ls)"; return 1; }
    [ "$ESP_CTX" = "$tag" ] && _esp_off
    _esp_subvol_rm "$ESP_ROOT/idf/$tag" || return 1
    btrfs subvolume snapshot "$ESP_ROOT/.snapshots/$snap" "$ESP_ROOT/idf/$tag" >/dev/null \
        && _esp_msg "$tag restored from $snap"
}

_esp_rm() {
    local tag=$1
    [ -d "$ESP_ROOT/idf/$tag" ] || { _esp_err "$tag not installed"; return 1; }
    [ "$ESP_CTX" = "$tag" ] && _esp_off
    _esp_subvol_rm "$ESP_ROOT/idf/$tag" && _esp_msg "removed $tag (shared tools stay in $ESP_ROOT/tools)"
}

_esp_setup() {                          # one-time, needs root
    local user=${SUDO_USER:-$USER}
    _esp_msg "creating group esp, adding $user, turning $ESP_ROOT into a btrfs subvolume"
    sudo bash -euc '
        root=$1; user=$2
        getent group esp >/dev/null || groupadd esp
        usermod -aG esp "$user"
        if [ -d "$root" ] && ! btrfs subvolume show "$root" >/dev/null 2>&1; then
            if [ -z "$(ls -A "$root")" ]; then rmdir "$root"; else
                echo "$root is not empty and not a subvolume - leaving it as a directory"; fi
        fi
        [ -e "$root" ] || btrfs subvolume create "$root" >/dev/null
        mkdir -p "$root/idf" "$root/tools" "$root/.snapshots"
        chown -R root:esp "$root"
        chmod 2775 "$root" "$root/idf" "$root/tools" "$root/.snapshots"
        setfacl -R -m g:esp:rwX "$root"
        setfacl -R -d -m g:esp:rwX -m d:m::rwX "$root"
    ' _ "$ESP_ROOT" "$user" || return 1
    _esp_msg "done. Log out and in again (or run: newgrp esp) so the group applies."
}

esp() {
    local cmd=${1:-use}; [ $# -gt 0 ] && shift
    case $cmd in
        use)      _esp_use "$@" ;;
        off)      _esp_off; _esp_msg "ESP-IDF deactivated" ;;
        ls|list)  _esp_ls ;;
        default)  [ -n "$1" ] || { _esp_default; return; }
                  mkdir -p "$ESP_CFG" && echo "$1" > "$ESP_CFG/default" && _esp_msg "default: $1" ;;
        install)  _esp_install "$@" ;;
        snap)     _esp_snap "$@" ;;
        rollback) _esp_rollback "$@" ;;
        rm)       _esp_rm "$@" ;;
        pin)      local t=${1:-$ESP_CTX}
                  [ -n "$t" ] || { _esp_err "usage: esp pin <tag>"; return 1; }
                  echo "$t" > .esp-idf-version && _esp_msg "pinned $t in $PWD/.esp-idf-version" ;;
        setup)    _esp_setup ;;
        v*)       _esp_use "$cmd" ;;             # shortcut: esp v6.1
        -h|help)  sed -n '3,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
        *)        _esp_err "unknown command $cmd (esp help)" ;;
    esac
}

_esp_complete() {
    local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "use off ls default install snap rollback rm pin setup help $(_esp_versions)" -- "$cur"))
    elif [[ $prev =~ ^(use|default|snap|rm|rollback|pin)$ ]]; then
        COMPREPLY=($(compgen -W "$(_esp_versions)" -- "$cur"))
    fi
}
complete -F _esp_complete esp 2>/dev/null
