#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

alias ll='ls -lhrsBA --classify=always --time=mtime --time-style="+%M" --sort=time'
alias llo='ls --color=auto -liarsht'
alias grep='grep --color=auto'

AIRGEDDON_WINDOWS_HANDLING=tmux
AIRGEDDON_SKIP_INTRO=true

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
# export IDF_TOOLS_PATH=/opt/esp/idf/v5.1/   # replaced by esp-ctx.sh (esp use <tag>)
#export IDF_PATH=/opt/esp/idf/v5.5


eval "$(fzf --bash)"
command -v tinty >/dev/null && eval "$(tinty generate-completion bash)"
export MANPAGER='nvim +Man!'
export SSH_AUTH_SOCK=$HOME/.bitwarden-ssh-agent.sock
source /usr/share/nvm/init-nvm.sh


export OPENSCADPATH=/usr/share/openscad/libraries


export GEM_HOME="$(gem env user_gemhome)"
export PATH="$PATH:$GEM_HOME/bin:/home/m/.cargo/bin:/home/m/.local/bin"

SCRIPTS_PATH=$HOME/.config/scripts
SCRIPTS=$(ls $SCRIPTS_PATH)

for SCRIPT in $SCRIPTS; do
	if [ ! -d $SCRIPTS_PATH/$SCRIPT ]; then

		# echo $script
		# cat $HOME/.config/scripts/$SCRIPT
		source $SCRIPTS_PATH/$SCRIPT
	fi
done

# Prompt: user@host path (git branch + state), red ✗<exit code> on failure, ❯ on its own line.
# git state markers: * unstaged, + staged, % untracked, $ stash, <>/=/ behind/ahead/in sync
if [[ -r /usr/share/git/completion/git-prompt.sh ]]; then
	source /usr/share/git/completion/git-prompt.sh
	GIT_PS1_SHOWDIRTYSTATE=1
	GIT_PS1_SHOWUNTRACKEDFILES=1
	GIT_PS1_SHOWSTASHSTATE=1
	GIT_PS1_SHOWUPSTREAM=auto
	GIT_PS1_SHOWCOLORHINTS=1
fi

__prompt() {
	local ec=$?
	local pre='\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\]'
	local post=''
	((ec)) && post=" \[\e[1;31m\]✗${ec}\[\e[0m\]"
	post+='\n\[\e[1;35m\]❯\[\e[0m\] '
	if declare -F __git_ps1 >/dev/null; then
		__git_ps1 "$pre" "$post" ' (%s)'
	else
		PS1="$pre$post"
	fi
}
PROMPT_COMMAND="__prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Tab completion for aliases: `gitlog <Tab>` completes like `git log --oneline --graph <Tab>`.
# bash doesn't apply a command's completion to its aliases; this expands the alias in the
# command line and hands it to bash-completion. Only simple aliases (no ; | & or cd ...).
_complete_alias() {
	local def=${BASH_ALIASES[$1]}
	local -a words
	read -ra words <<<"$def"
	COMP_WORDS=("${words[@]}" "${COMP_WORDS[@]:1}")
	((COMP_CWORD += ${#words[@]} - 1))
	COMP_LINE=$def${COMP_LINE#"$1"}
	((COMP_POINT += ${#def} - ${#1}))
	if declare -F _comp_command_offset >/dev/null; then
		_comp_command_offset 0
	elif declare -F _command_offset >/dev/null; then
		_command_offset 0
	fi
}
for _a in "${!BASH_ALIASES[@]}"; do
	case "${BASH_ALIASES[$_a]}" in *[\;\|\&\$\`]* | cd\ *) continue ;; esac
	[ "${BASH_ALIASES[$_a]%% *}" = "$_a" ] && continue # ls='ls --color' keeps ls's own completion
	complete -F _complete_alias "$_a"
done
unset _a
