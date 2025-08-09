# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
acp () {
	GREEN='\033[0;32m' 
	RED='\033[0;31m' 
	YELLOW='\033[1;33m' 
	NC='\033[0m' 
	if [ -z "$1" ]
	then
		echo -e "${RED}Error: No commit message provided.${NC}"
		read -p "Please enter a commit message: " commit_message
		if [ -z "$commit_message" ]
		then
			echo -e "${RED}Error: Still no commit message. Aborting.${NC}"
			return 1
		fi
	else
		commit_message=$1 
	fi
	echo -e "${YELLOW}Adding changes...${NC}"
	if ! git add .
	then
		echo -e "${RED}Failed to add changes. Aborting.${NC}"
		return 1
	fi
	echo -e "${YELLOW}Committing changes...${NC}"
	if ! git commit -m "$commit_message"
	then
		echo -e "${RED}Failed to commit changes. Aborting.${NC}"
		return 1
	fi
	echo -e "${YELLOW}Pushing changes...${NC}"
	if git push
	then
		echo -e "${GREEN}Changes pushed successfully!${NC}"
	else
		echo -e "${RED}Failed to push changes. Please check your connection or remote repository settings.${NC}"
		return 1
	fi
}
add-zle-hook-widget () {
	# undefined
	builtin autoload -XU
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
delkh () {
	if [ $# -eq 0 ]
	then
		echo "Usage: delkh <hostname or IP>"
		echo "Example: delkh github.com"
		return 1
	fi
	local HOST="$1" 
	local KNOWN_HOSTS="$HOME/.ssh/known_hosts" 
	if [ ! -f "$KNOWN_HOSTS" ]
	then
		echo "Error: $KNOWN_HOSTS file not found"
		return 1
	fi
	cp "$KNOWN_HOSTS" "$KNOWN_HOSTS.backup"
	local MATCHES=$(grep -c "$HOST" "$KNOWN_HOSTS" 2>/dev/null || echo "0") 
	if [ "$MATCHES" -eq 0 ]
	then
		echo "No entries found for: $HOST"
		return 0
	fi
	ssh-keygen -R "$HOST" 2> /dev/null
	if [ $? -eq 0 ]
	then
		echo "✅ Removed entry/entries for: $HOST"
		echo "📁 Backup saved to: $KNOWN_HOSTS.backup"
	else
		echo "❌ Failed to remove entries for: $HOST"
		cp "$KNOWN_HOSTS.backup" "$KNOWN_HOSTS"
		return 1
	fi
}
docker-kill-all () {
	echo "Killing all running containers..."
	docker kill $(docker ps -q) 2> /dev/null
	echo "All running containers killed!"
}
docker-reset () {
	echo "Stopping all containers..."
	docker stop $(docker ps -aq) 2> /dev/null
	echo "Removing all containers..."
	docker rm $(docker ps -aq) 2> /dev/null
	echo "Removing all images..."
	docker rmi $(docker images -q) 2> /dev/null
	echo "Pruning system (volumes, networks, build cache)..."
	docker system prune -af --volumes
	echo "Docker reset complete!"
}
is-at-least () {
	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done
}
prompt_starship_precmd () {
	STARSHIP_CMD_STATUS=$? STARSHIP_PIPE_STATUS=(${pipestatus[@]}) 
	if (( ${+STARSHIP_START_TIME} ))
	then
		__starship_get_time && (( STARSHIP_DURATION = STARSHIP_CAPTURED_TIME - STARSHIP_START_TIME ))
		unset STARSHIP_START_TIME
	else
		unset STARSHIP_DURATION STARSHIP_CMD_STATUS STARSHIP_PIPE_STATUS
	fi
	STARSHIP_JOBS_COUNT=${#jobstates} 
}
prompt_starship_preexec () {
	__starship_get_time && STARSHIP_START_TIME=$STARSHIP_CAPTURED_TIME 
}
starship_zle-keymap-select () {
	zle reset-prompt
}
# Shell Options
setopt nohashdirs
setopt login
setopt promptsubst
# Aliases
alias -- gs='git status'
alias -- la='ls -A'
alias -- ll='ls -la'
alias -- ls='ls -G'
alias -- pip=pip3
alias -- python=python3
alias -- resource='source ~/.zshrc'
alias -- rmf='rm -rf'
alias -- run-help=man
alias -- tf=terraform
alias -- vib='vim ~/.zshrc;resource'
alias -- which-command=whence
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/opt/homebrew/Cellar/ripgrep/14.1.1/bin/rg'
fi
export PATH=/opt/homebrew/bin\:/opt/homebrew/sbin\:/usr/local/bin\:/System/Cryptexes/App/usr/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin\:/Applications/iTerm.app/Contents/Resources/utilities\:/Users/davidg/.local/bin\:/Users/davidg/.local/bin\:/Users/davidg/.local/bin\:/Users/davidg/.local/bin\:/Users/davidg/.local/bin
