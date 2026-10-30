# shellcheck shell=bash
# Tab completion for tools that don't ship any (sourced by bashrc via ~/.config/scripts).

# --long options read from `<cmd> --help` by bash-completion (files still complete normally)
if declare -F _comp_complete_longopt >/dev/null; then
	complete -F _comp_complete_longopt nvim claude
fi

# bluetoothctl: commands, on/off, and known device addresses
_bluetoothctl_complete() {
	local cur=${COMP_WORDS[COMP_CWORD]} words=""
	if [ "$COMP_CWORD" -eq 1 ]; then
		words="power scan pair connect disconnect trust untrust remove block unblock info
			devices show list select agent default-agent discoverable pairable"
	elif [ "$COMP_CWORD" -eq 2 ]; then
		case ${COMP_WORDS[1]} in
		power | scan | discoverable | pairable | agent) words="on off" ;;
		connect | disconnect | pair | trust | untrust | remove | info | block | unblock)
			words=$(timeout 2 bluetoothctl devices 2>/dev/null | awk '$1 == "Device" {print $2}') ;;
		esac
	fi
	mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}
complete -F _bluetoothctl_complete bluetoothctl
