#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

alias ll='ls -lhrsBA --classify=always --time=mtime --time-style="+%M" --sort=time'
alias llo='ls --color=auto -liarsht'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

AIRGEDDON_WINDOWS_HANDLING=tmux
AIRGEDDON_SKIP_INTRO=true

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
export IDF_TOOLS_PATH=/opt/esp/idf/v5.1/
#export IDF_PATH=/opt/esp/idf/v5.5

#export BASE16_THEME='base16-atelier-dune'

eval "$(fzf --bash)"
# eval "$(tinty generate-completion bash)"
export MANPAGER='nvim +Man!'
source /usr/share/nvm/init-nvm.sh

# export BASE16_THEME='ayu-dark'
# export BASE16_THEME=$(cat $HOME/.config/color.scheme)

export OPENSCADPATH=/usr/share/openscad/libraries

# eval $(tinty apply "$BASE16_THEME")

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
