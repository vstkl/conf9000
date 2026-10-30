# shellcheck shell=bash
# base16 theming via tinty (https://github.com/tinted-theming/tinty), sourced by bashrc.
# One scheme for the whole desktop: kitty, tmux, neovim, waybar, sway/scroll, swaync, fuzzel,
# rofi, yazi, bat, Claude Code, bash and fzf (see ~/.config/tinted-theming/tinty/config.toml).
#
#   theme                 pick a scheme with fzf
#   theme ayu-dark        apply base16-ayu-dark everywhere (Tab completes scheme names)
#   theme base24-dracula  base24 schemes need the prefix

_tinty_data="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"

# bat: "base16" theme uses the terminal palette, so it follows the scheme too
export BAT_THEME=base16

# this shell's terminal palette (works in tty and tmux too) and fzf colors
_tinty_source() {
	local f
	for f in "$_tinty_data"/artifacts/shell-scripts-file.sh "$_tinty_data"/artifacts/fzf-bash-file.config; do
		# shellcheck disable=SC1090
		[ -r "$f" ] && . "$f"
	done
}
_tinty_source

# scheme names: base16 ones without prefix (ayu-dark), base24 ones with it (base24-dracula)
_theme_names() {
	local f dir="$_tinty_data/scheme-repos/schemes"
	for f in "$dir"/base16/*.yaml; do [ -e "$f" ] && f=${f##*/} && echo "${f%.yaml}"; done
	for f in "$dir"/base24/*.yaml; do [ -e "$f" ] && f=${f##*/} && echo "base24-${f%.yaml}"; done
}

theme() {
	command -v tinty >/dev/null || { echo "theme: tinty is not installed" >&2; return 1; }
	local scheme=$1 current
	if [ -z "$scheme" ]; then
		command -v fzf >/dev/null || { _theme_names; return; }
		current=$(tinty current 2>/dev/null)
		scheme=$(_theme_names | fzf --prompt "theme> " --query "${current#base16-}") || return
	fi
	case "$scheme" in base16-* | base24-* | tinted8-*) ;; *) scheme="base16-$scheme" ;; esac
	tinty apply "$scheme" && _tinty_source
}

_theme_complete() {
	[ "$COMP_CWORD" -eq 1 ] || return 0
	mapfile -t COMPREPLY < <(compgen -W "$(_theme_names)" -- "${COMP_WORDS[1]}")
}
complete -F _theme_complete theme
