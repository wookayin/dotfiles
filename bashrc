# ~/.bashrc

umask 072

##########################
# 1. Basic Configuration #
##########################

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Platform detection
platform='linux'
if [[ `uname` == 'Darwin' ]]; then
  platform='mac'
fi

# history settings
shopt -s histappend		# append, no overwrite
HISTSIZE=10000
HISTFILESIZE=20000

##############
# 2. Aliases #
##############

# ls color and with classfication
if [[ $platform == 'mac' ]]; then
  alias ls='ls -F -G'
else
  alias ls='ls -F --color=auto'
fi
alias ll='ls -alF'

# grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# alert for rm, cp, mv
alias rm='rm -iv'
alias cp='cp -iv'
alias mv='mv -iv'

# screens
alias scr='screen -rD'


##################
# 3. Color & PS1 #
##################

COLOR_NONE="\e[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
GRAY="\033[0;37m"
BOLD_RED="\033[1;31m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_PURPLE="\033[1;35m"
BOLD_CYAN="\033[1;36m"
WHITE="\033[1;37m"

git_branch() {
	local git_branch=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'`
	local git_stat="`git status -unormal 2>&1`"

	local color_stat=''
	if [[ "$git_stat" =~ "nothing to commit" ]]; then
		color_stat="$GREEN"
	elif [[ "$git_stat" =~ "nothing added to commit but untracked files present" ]]; then
		color_stat="$LIGHT_GREEN"
	elif [[ "$git_stat" =~ "# Untracked files:" ]]; then
		color_stat="$YELLOW"
	else
		color_stat="$RED"
	fi

	echo -en "$color_stat$git_branch"
}

PS1="\[$BOLD_GREEN\][\[$BOLD_YELLOW\]\u\[$BOLD_GREEN\]@\[$BOLD_BLUE\]\h:\[$BOLD_RED\]"'`pwd`'"\[$BOLD_GREEN\]] "'`git_branch`'" \[$GRAY\]\t\n\[$BOLD_GREEN\]"'\$'"\[$COLOR_NONE\] "

# Terminal
# screen-256color if inside tmux, xterm-256color otherwise
if [[ -n "$TMUX" ]]; then
  export TERM="screen-256color"
else
  export TERM="xterm-256color"
fi

# Additional Completion
if [ -f /usr/local/etc/bash_completion ]; then source /usr/local/etc/bash_completion; fi
