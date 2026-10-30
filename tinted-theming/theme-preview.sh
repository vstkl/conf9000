#!/usr/bin/env bash
# Preview helper for the `theme` picker (scripts/paint.sh).
#
#   theme-preview.sh show NAME   palette swatches + code sample (fzf --preview)
#   theme-preview.sh term NAME   recolor the terminal running the picker (live preview);
#                                `theme` restores the current scheme if you cancel
#
# NAME as listed by `theme`: ayu-dark (base16) or base24-dracula.
set -euo pipefail

data="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
name=${2:-}
case "$name" in
base24-*) sys=base24 slug=${name#base24-} ;;
base16-*) sys=base16 slug=${name#base16-} ;;
*) sys=base16 slug=$name ;;
esac

case "${1:-}" in
term)
	# tinted-shell's per-scheme script sets the 16 colors + fg/bg/cursor via escape codes on $TTY
	f="$data/repos/shell/scripts/$sys-$slug.sh"
	[ -r "$f" ] && TTY=/dev/tty bash "$f" >/dev/null 2>&1
	;;
show)
	yaml="$data/scheme-repos/schemes/$sys/$slug.yaml"
	[ -r "$yaml" ] || { echo "no scheme file for $name"; exit 0; }
	field() { sed -n -E "s/^$1: *\"?([^\"]*)\"?.*/\1/p" "$yaml" | head -1; }
	hex() { sed -n -E "s/^ *$1: *\"?#?([0-9a-fA-F]{6}).*/\1/p" "$yaml" | head -1; }
	declare -A c
	for b in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do c[$b]=$(hex "base$b"); done
	fg() { printf '\e[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
	bg() { printf '\e[48;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
	r=$'\e[0m'

	printf '%s%s %s %s\n' "$(bg "${c[00]}")" "$(fg "${c[05]}")" "$(field name)" "$r"
	printf '%s · %s\n\n' "$sys" "$(field variant)"
	# swatches: background shades, then accents
	for row in "00 01 02 03 04 05 06 07" "08 09 0A 0B 0C 0D 0E 0F"; do
		for b in $row; do printf '%s      %s' "$(bg "${c[$b]}")" "$r"; done
		printf '\n'
		for b in $row; do printf ' %-5s' "$b"; done
		printf '\n'
	done
	# code sample on the scheme's own background
	B=$(bg "${c[00]}") T=$(fg "${c[05]}") C=$(fg "${c[03]}") K=$(fg "${c[0E]}")
	F=$(fg "${c[0D]}") S=$(fg "${c[0B]}") N=$(fg "${c[09]}") E=$(fg "${c[08]}") Y=$(fg "${c[0A]}")
	printf '\n'
	printf '%s %s# theme preview%s                          %s\n' "$B" "$C" "$T" "$r"
	printf '%s %slocal%s %sname%s=%s"%s"%s                     %s\n' "$B" "$K" "$T" "$T" "$T" "$S" "$slug" "$T" "$r"
	printf '%s %sfunction%s %sgreet%s() {                     %s\n' "$B" "$K" "$T" "$F" "$T" "$r"
	printf '%s   %sif%s [ %s$#%s -gt %s0%s ]; %sthen%s               %s\n' "$B" "$K" "$T" "$Y" "$T" "$N" "$T" "$K" "$T" "$r"
	# shellcheck disable=SC2016 # literal $1 in the sample
	printf '%s     %secho%s %s"hello $1"%s                  %s\n' "$B" "$F" "$T" "$S" "$T" "$r"
	printf '%s   %selse%s %sreturn%s %s1%s  %s# error%s            %s\n' "$B" "$K" "$T" "$K" "$T" "$E" "$T" "$C" "$T" "$r"
	printf '%s   %sfi%s                                   %s\n' "$B" "$K" "$T" "$r"
	printf '%s }                                      %s\n' "$B" "$r"
	;;
*)
	sed -n '2,8p' "$0" >&2
	exit 1
	;;
esac
