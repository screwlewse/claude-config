# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
VCS_INFO_formats () {
	setopt localoptions noksharrays NO_shwordsplit
	local msg tmp
	local -i i
	local -A hook_com
	hook_com=(action "$1" action_orig "$1" branch "$2" branch_orig "$2" base "$3" base_orig "$3" staged "$4" staged_orig "$4" unstaged "$5" unstaged_orig "$5" revision "$6" revision_orig "$6" misc "$7" misc_orig "$7" vcs "${vcs}" vcs_orig "${vcs}") 
	hook_com[base-name]="${${hook_com[base]}:t}" 
	hook_com[base-name_orig]="${hook_com[base-name]}" 
	hook_com[subdir]="$(VCS_INFO_reposub ${hook_com[base]})" 
	hook_com[subdir_orig]="${hook_com[subdir]}" 
	: vcs_info-patch-9b9840f2-91e5-4471-af84-9e9a0dc68c1b
	for tmp in base base-name branch misc revision subdir
	do
		hook_com[$tmp]="${hook_com[$tmp]//\%/%%}" 
	done
	VCS_INFO_hook 'post-backend'
	if [[ -n ${hook_com[action]} ]]
	then
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" actionformats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b|%a]%u%c-' 
	else
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" formats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b]%u%c-' 
	fi
	if [[ -n ${hook_com[staged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" stagedstr tmp
		[[ -z ${tmp} ]] && hook_com[staged]='S'  || hook_com[staged]=${tmp} 
	fi
	if [[ -n ${hook_com[unstaged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" unstagedstr tmp
		[[ -z ${tmp} ]] && hook_com[unstaged]='U'  || hook_com[unstaged]=${tmp} 
	fi
	if [[ ${quiltmode} != 'standalone' ]] && VCS_INFO_hook "pre-addon-quilt"
	then
		local REPLY
		VCS_INFO_quilt addon
		hook_com[quilt]="${REPLY}" 
		unset REPLY
	elif [[ ${quiltmode} == 'standalone' ]]
	then
		hook_com[quilt]=${hook_com[misc]} 
	fi
	(( ${#msgs} > maxexports )) && msgs[$(( maxexports + 1 )),-1]=() 
	for i in {1..${#msgs}}
	do
		if VCS_INFO_hook "set-message" $(( $i - 1 )) "${msgs[$i]}"
		then
			zformat -f msg ${msgs[$i]} a:${hook_com[action]} b:${hook_com[branch]} c:${hook_com[staged]} i:${hook_com[revision]} m:${hook_com[misc]} r:${hook_com[base-name]} s:${hook_com[vcs]} u:${hook_com[unstaged]} Q:${hook_com[quilt]} R:${hook_com[base]} S:${hook_com[subdir]}
			msgs[$i]=${msg} 
		else
			msgs[$i]=${hook_com[message]} 
		fi
	done
	hook_com=() 
	backend_misc=() 
	return 0
}
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
alias_value () {
	(( $+aliases[$1] )) && echo $aliases[$1]
}
async () {
	async_init
}
async_flush_jobs () {
	setopt localoptions noshwordsplit
	local worker=$1 
	shift
	zpty -t $worker &> /dev/null || return 1
	async_job $worker "_killjobs"
	local junk
	if zpty -r -t $worker junk '*'
	then
		(( ASYNC_DEBUG )) && print -n "async_flush_jobs $worker: ${(V)junk}"
		while zpty -r -t $worker junk '*'
		do
			(( ASYNC_DEBUG )) && print -n "${(V)junk}"
		done
		(( ASYNC_DEBUG )) && print
	fi
	typeset -gA ASYNC_PROCESS_BUFFER
	unset "ASYNC_PROCESS_BUFFER[$worker]"
}
async_init () {
	(( ASYNC_INIT_DONE )) && return
	typeset -g ASYNC_INIT_DONE=1 
	zmodload zsh/zpty
	zmodload zsh/datetime
	autoload -Uz is-at-least
	typeset -g ASYNC_ZPTY_RETURNS_FD=0 
	[[ -o interactive ]] && [[ -o zle ]] && {
		typeset -h REPLY
		zpty _async_test :
		(( REPLY )) && ASYNC_ZPTY_RETURNS_FD=1 
		zpty -d _async_test
	}
}
async_job () {
	setopt localoptions noshwordsplit noksharrays noposixidentifiers noposixstrings
	local worker=$1 
	shift
	local -a cmd
	cmd=("$@") 
	if (( $#cmd > 1 ))
	then
		cmd=(${(q)cmd}) 
	fi
	_async_send_job $0 $worker "$cmd"
}
async_process_results () {
	setopt localoptions unset noshwordsplit noksharrays noposixidentifiers noposixstrings
	local worker=$1 
	local callback=$2 
	local caller=$3 
	local -a items
	local null=$'\0' data 
	integer -l len pos num_processed has_next
	typeset -gA ASYNC_PROCESS_BUFFER
	while zpty -r -t $worker data 2> /dev/null
	do
		ASYNC_PROCESS_BUFFER[$worker]+=$data 
		len=${#ASYNC_PROCESS_BUFFER[$worker]} 
		pos=${ASYNC_PROCESS_BUFFER[$worker][(i)$null]} 
		if (( ! len )) || (( pos > len ))
		then
			continue
		fi
		while (( pos <= len ))
		do
			items=("${(@Q)${(z)ASYNC_PROCESS_BUFFER[$worker][1,$pos-1]}}") 
			ASYNC_PROCESS_BUFFER[$worker]=${ASYNC_PROCESS_BUFFER[$worker][$pos+1,$len]} 
			len=${#ASYNC_PROCESS_BUFFER[$worker]} 
			if (( len > 1 ))
			then
				pos=${ASYNC_PROCESS_BUFFER[$worker][(i)$null]} 
			fi
			has_next=$(( len != 0 )) 
			if (( $#items == 5 ))
			then
				items+=($has_next) 
				$callback "${(@)items}"
				(( num_processed++ ))
			elif [[ -z $items ]]
			then
				
			else
				$callback "[async]" 1 "" 0 "$0:$LINENO: error: bad format, got ${#items} items (${(q)items})" $has_next
			fi
		done
	done
	(( num_processed )) && return 0
	[[ $caller = trap || $caller = watcher ]] && return 0
	return 1
}
async_register_callback () {
	setopt localoptions noshwordsplit nolocaltraps
	typeset -gA ASYNC_PTYS ASYNC_CALLBACKS
	local worker=$1 
	shift
	ASYNC_CALLBACKS[$worker]="$*" 
	if [[ ! -o interactive ]] || [[ ! -o zle ]]
	then
		trap '_async_notify_trap' WINCH
	elif [[ -o interactive ]] && [[ -o zle ]]
	then
		local fd w
		for fd w in ${(@kv)ASYNC_PTYS}
		do
			if [[ $w == $worker ]]
			then
				zle -F $fd _async_zle_watcher
				break
			fi
		done
	fi
}
async_start_worker () {
	setopt localoptions noshwordsplit noclobber
	local worker=$1 
	shift
	local -a args
	args=("$@") 
	zpty -t $worker &> /dev/null && return
	typeset -gA ASYNC_PTYS
	typeset -h REPLY
	typeset has_xtrace=0 
	if [[ -o interactive ]] && [[ -o zle ]]
	then
		args+=(-z) 
		if (( ! ASYNC_ZPTY_RETURNS_FD ))
		then
			integer -l zptyfd
			exec {zptyfd}>&1
			exec {zptyfd}>&-
		fi
	fi
	integer errfd=-1 
	if is-at-least 5.0.8
	then
		exec {errfd}>&2
	fi
	[[ -o xtrace ]] && {
		has_xtrace=1 
		unsetopt xtrace
	}
	if (( errfd != -1 ))
	then
		zpty -b $worker _async_worker -p $$ $args 2>&$errfd
	else
		zpty -b $worker _async_worker -p $$ $args
	fi
	local ret=$? 
	(( has_xtrace )) && setopt xtrace
	(( errfd != -1 )) && exec {errfd}>&-
	if (( ret ))
	then
		async_stop_worker $worker
		return 1
	fi
	if ! is-at-least 5.0.8
	then
		sleep 0.001
	fi
	if [[ -o interactive ]] && [[ -o zle ]]
	then
		if (( ! ASYNC_ZPTY_RETURNS_FD ))
		then
			REPLY=$zptyfd 
		fi
		ASYNC_PTYS[$REPLY]=$worker 
	fi
}
async_stop_worker () {
	setopt localoptions noshwordsplit
	local ret=0 worker k v 
	for worker in $@
	do
		for k v in ${(@kv)ASYNC_PTYS}
		do
			if [[ $v == $worker ]]
			then
				zle -F $k
				unset "ASYNC_PTYS[$k]"
			fi
		done
		async_unregister_callback $worker
		zpty -d $worker 2> /dev/null || ret=$? 
		typeset -gA ASYNC_PROCESS_BUFFER
		unset "ASYNC_PROCESS_BUFFER[$worker]"
	done
	return $ret
}
async_unregister_callback () {
	typeset -gA ASYNC_CALLBACKS
	unset "ASYNC_CALLBACKS[$1]"
}
async_worker_eval () {
	setopt localoptions noshwordsplit noksharrays noposixidentifiers noposixstrings
	local worker=$1 
	shift
	local -a cmd
	cmd=("$@") 
	if (( $#cmd > 1 ))
	then
		cmd=(${(q)cmd}) 
	fi
	_async_send_job $0 $worker "_async_eval $cmd"
}
azure_prompt_info () {
	return 1
}
bashcompinit () {
	# undefined
	builtin autoload -XUz
}
bracketed-paste-magic () {
	# undefined
	builtin autoload -XUz
}
bzr_prompt_info () {
	local bzr_branch
	bzr_branch=$(bzr nick 2>/dev/null)  || return
	if [[ -n "$bzr_branch" ]]
	then
		local bzr_dirty="" 
		if [[ -n $(bzr status 2>/dev/null) ]]
		then
			bzr_dirty=" %{$fg[red]%}*%{$reset_color%}" 
		fi
		printf "%s%s%s%s" "$ZSH_THEME_SCM_PROMPT_PREFIX" "bzr::${bzr_branch##*:}" "$bzr_dirty" "$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}
chruby_prompt_info () {
	return 1
}
clipcopy () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
clippaste () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
colors () {
	emulate -L zsh
	typeset -Ag color colour
	color=(00 none 01 bold 02 faint 22 normal 03 italic 23 no-italic 04 underline 24 no-underline 05 blink 25 no-blink 07 reverse 27 no-reverse 08 conceal 28 no-conceal 30 black 40 bg-black 31 red 41 bg-red 32 green 42 bg-green 33 yellow 43 bg-yellow 34 blue 44 bg-blue 35 magenta 45 bg-magenta 36 cyan 46 bg-cyan 37 white 47 bg-white 39 default 49 bg-default) 
	local k
	for k in ${(k)color}
	do
		color[${color[$k]}]=$k 
	done
	for k in ${color[(I)3?]}
	do
		color[fg-${color[$k]}]=$k 
	done
	for k in grey gray
	do
		color[$k]=${color[black]} 
		color[fg-$k]=${color[$k]} 
		color[bg-$k]=${color[bg-black]} 
	done
	colour=(${(kv)color}) 
	local lc=$'\e[' rc=m 
	typeset -Hg reset_color bold_color
	reset_color="$lc${color[none]}$rc" 
	bold_color="$lc${color[bold]}$rc" 
	typeset -AHg fg fg_bold fg_no_bold
	for k in ${(k)color[(I)fg-*]}
	do
		fg[${k#fg-}]="$lc${color[$k]}$rc" 
		fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc" 
		fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
	typeset -AHg bg bg_bold bg_no_bold
	for k in ${(k)color[(I)bg-*]}
	do
		bg[${k#bg-}]="$lc${color[$k]}$rc" 
		bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc" 
		bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
}
compaudit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compdef () {
	local opt autol type func delete eval new i ret=0 cmd svc 
	local -a match mbegin mend
	emulate -L zsh
	setopt extendedglob
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	while getopts "anpPkKde" opt
	do
		case "$opt" in
			(a) autol=yes  ;;
			(n) new=yes  ;;
			([pPkK]) if [[ -n "$type" ]]
				then
					print -u2 "$0: type already set to $type"
					return 1
				fi
				if [[ "$opt" = p ]]
				then
					type=pattern 
				elif [[ "$opt" = P ]]
				then
					type=postpattern 
				elif [[ "$opt" = K ]]
				then
					type=widgetkey 
				else
					type=key 
				fi ;;
			(d) delete=yes  ;;
			(e) eval=yes  ;;
		esac
	done
	shift OPTIND-1
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	if [[ -z "$delete" ]]
	then
		if [[ -z "$eval" ]] && [[ "$1" = *\=* ]]
		then
			while (( $# ))
			do
				if [[ "$1" = *\=* ]]
				then
					cmd="${1%%\=*}" 
					svc="${1#*\=}" 
					func="$_comps[${_services[(r)$svc]:-$svc}]" 
					[[ -n ${_services[$svc]} ]] && svc=${_services[$svc]} 
					[[ -z "$func" ]] && func="${${_patcomps[(K)$svc][1]}:-${_postpatcomps[(K)$svc][1]}}" 
					if [[ -n "$func" ]]
					then
						_comps[$cmd]="$func" 
						_services[$cmd]="$svc" 
					else
						print -u2 "$0: unknown command or service: $svc"
						ret=1 
					fi
				else
					print -u2 "$0: invalid argument: $1"
					ret=1 
				fi
				shift
			done
			return ret
		fi
		func="$1" 
		[[ -n "$autol" ]] && autoload -rUz "$func"
		shift
		case "$type" in
			(widgetkey) while [[ -n $1 ]]
				do
					if [[ $# -lt 3 ]]
					then
						print -u2 "$0: compdef -K requires <widget> <comp-widget> <key>"
						return 1
					fi
					[[ $1 = _* ]] || 1="_$1" 
					[[ $2 = .* ]] || 2=".$2" 
					[[ $2 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$1" "$2" "$func"
					if [[ -n $new ]]
					then
						bindkey "$3" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] && bindkey "$3" "$1"
					else
						bindkey "$3" "$1"
					fi
					shift 3
				done ;;
			(key) if [[ $# -lt 2 ]]
				then
					print -u2 "$0: missing keys"
					return 1
				fi
				if [[ $1 = .* ]]
				then
					[[ $1 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" "$1" "$func"
				else
					[[ $1 = menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" ".$1" "$func"
				fi
				shift
				for i
				do
					if [[ -n $new ]]
					then
						bindkey "$i" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] || continue
					fi
					bindkey "$i" "$func"
				done ;;
			(*) while (( $# ))
				do
					if [[ "$1" = -N ]]
					then
						type=normal 
					elif [[ "$1" = -p ]]
					then
						type=pattern 
					elif [[ "$1" = -P ]]
					then
						type=postpattern 
					else
						case "$type" in
							(pattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_patcomps[$match[1]]="=$match[2]=$func" 
								else
									_patcomps[$1]="$func" 
								fi ;;
							(postpattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_postpatcomps[$match[1]]="=$match[2]=$func" 
								else
									_postpatcomps[$1]="$func" 
								fi ;;
							(*) if [[ "$1" = *\=* ]]
								then
									cmd="${1%%\=*}" 
									svc=yes 
								else
									cmd="$1" 
									svc= 
								fi
								if [[ -z "$new" || -z "${_comps[$1]}" ]]
								then
									_comps[$cmd]="$func" 
									[[ -n "$svc" ]] && _services[$cmd]="${1#*\=}" 
								fi ;;
						esac
					fi
					shift
				done ;;
		esac
	else
		case "$type" in
			(pattern) unset "_patcomps[$^@]" ;;
			(postpattern) unset "_postpatcomps[$^@]" ;;
			(key) print -u2 "$0: cannot restore key bindings"
				return 1 ;;
			(*) unset "_comps[$^@]" ;;
		esac
	fi
}
compdump () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compgen () {
	local opts prefix suffix job OPTARG OPTIND ret=1 
	local -a name res results jids
	local -A shortopts
	emulate -L sh
	setopt kshglob noshglob braceexpand nokshautoload
	shortopts=(a alias b builtin c command d directory e export f file g group j job k keyword u user v variable) 
	while getopts "o:A:G:C:F:P:S:W:X:abcdefgjkuv" name
	do
		case $name in
			([abcdefgjkuv]) OPTARG="${shortopts[$name]}"  ;&
			(A) case $OPTARG in
					(alias) results+=("${(k)aliases[@]}")  ;;
					(arrayvar) results+=("${(k@)parameters[(R)array*]}")  ;;
					(binding) results+=("${(k)widgets[@]}")  ;;
					(builtin) results+=("${(k)builtins[@]}" "${(k)dis_builtins[@]}")  ;;
					(command) results+=("${(k)commands[@]}" "${(k)aliases[@]}" "${(k)builtins[@]}" "${(k)functions[@]}" "${(k)reswords[@]}")  ;;
					(directory) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N-/)) 
						setopt nobareglobqual ;;
					(disabled) results+=("${(k)dis_builtins[@]}")  ;;
					(enabled) results+=("${(k)builtins[@]}")  ;;
					(export) results+=("${(k)parameters[(R)*export*]}")  ;;
					(file) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N)) 
						setopt nobareglobqual ;;
					(function) results+=("${(k)functions[@]}")  ;;
					(group) emulate zsh
						_groups -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(hostname) emulate zsh
						_hosts -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(job) results+=("${savejobtexts[@]%% *}")  ;;
					(keyword) results+=("${(k)reswords[@]}")  ;;
					(running) jids=("${(@k)savejobstates[(R)running*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(stopped) jids=("${(@k)savejobstates[(R)suspended*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(setopt | shopt) results+=("${(k)options[@]}")  ;;
					(signal) results+=("SIG${^signals[@]}")  ;;
					(user) results+=("${(k)userdirs[@]}")  ;;
					(variable) results+=("${(k)parameters[@]}")  ;;
					(helptopic)  ;;
				esac ;;
			(F) COMPREPLY=() 
				local -a args
				args=("${words[0]}" "${@[-1]}" "${words[CURRENT-2]}") 
				() {
					typeset -h words
					$OPTARG "${args[@]}"
				}
				results+=("${COMPREPLY[@]}")  ;;
			(G) setopt nullglob
				results+=(${~OPTARG}) 
				unsetopt nullglob ;;
			(W) results+=(${(Q)~=OPTARG})  ;;
			(C) results+=($(eval $OPTARG))  ;;
			(P) prefix="$OPTARG"  ;;
			(S) suffix="$OPTARG"  ;;
			(X) if [[ ${OPTARG[0]} = '!' ]]
				then
					results=("${(M)results[@]:#${OPTARG#?}}") 
				else
					results=("${results[@]:#$OPTARG}") 
				fi ;;
		esac
	done
	print -l -r -- "$prefix${^results[@]}$suffix"
}
compinit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compinstall () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
complete () {
	emulate -L zsh
	local args void cmd print remove
	args=("$@") 
	zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
	if [[ -n $print ]]
	then
		printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
	elif [[ -n $remove ]]
	then
		for cmd
		do
			unset "_comps[$cmd]"
		done
	else
		compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
	fi
}
conda_prompt_info () {
	return 1
}
current_branch () {
	git_current_branch
}
d () {
	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -n 10
	fi
}
default () {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
delkh () {
	if [ $# -eq 0 ]
	then
		echo "Usage: delkh <hostname or IP>"
		echo "Example: delkh github.com"
		echo "Example: delkh 192.168.1.100"
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
detect-clipboard () {
	emulate -L zsh
	if [[ "${OSTYPE}" == darwin* ]] && (( ${+commands[pbcopy]} )) && (( ${+commands[pbpaste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | pbcopy
		}
		clippaste () {
			pbpaste
		}
	elif [[ "${OSTYPE}" == (cygwin|msys)* ]]
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" > /dev/clipboard
		}
		clippaste () {
			cat /dev/clipboard
		}
	elif (( $+commands[clip.exe] )) && (( $+commands[powershell.exe] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | clip.exe
		}
		clippaste () {
			powershell.exe -noprofile -command Get-Clipboard
		}
	elif [ -n "${WAYLAND_DISPLAY:-}" ] && (( ${+commands[wl-copy]} )) && (( ${+commands[wl-paste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | wl-copy &> /dev/null &|
		}
		clippaste () {
			wl-paste --no-newline
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xsel]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xsel --clipboard --input
		}
		clippaste () {
			xsel --clipboard --output
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xclip]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xclip -selection clipboard -in &> /dev/null &|
		}
		clippaste () {
			xclip -out -selection clipboard
		}
	elif (( ${+commands[lemonade]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | lemonade copy
		}
		clippaste () {
			lemonade paste
		}
	elif (( ${+commands[doitclient]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | doitclient wclip
		}
		clippaste () {
			doitclient wclip -r
		}
	elif (( ${+commands[win32yank]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | win32yank -i
		}
		clippaste () {
			win32yank -o
		}
	elif [[ $OSTYPE == linux-android* ]] && (( $+commands[termux-clipboard-set] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | termux-clipboard-set
		}
		clippaste () {
			termux-clipboard-get
		}
	elif [ -n "${TMUX:-}" ] && (( ${+commands[tmux]} ))
	then
		clipcopy () {
			tmux load-buffer "${1:--}"
		}
		clippaste () {
			tmux save-buffer -
		}
	else
		_retry_clipboard_detection_or_fail () {
			local clipcmd="${1}" 
			shift
			if detect-clipboard
			then
				"${clipcmd}" "$@"
			else
				print "${clipcmd}: Platform $OSTYPE not supported or xclip/xsel not installed" >&2
				return 1
			fi
		}
		clipcopy () {
			_retry_clipboard_detection_or_fail clipcopy "$@"
		}
		clippaste () {
			_retry_clipboard_detection_or_fail clippaste "$@"
		}
		return 1
	fi
}
diff () {
	command diff --color "$@"
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
down-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
edit-command-line () {
	# undefined
	builtin autoload -XU
}
env_default () {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}
gbda () {
	git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2> /dev/null
}
gbds () {
	local default_branch=$(git_main_branch) 
	(( ! $? )) || default_branch=$(git_develop_branch) 
	git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch
	do
		local merge_base=$(git merge-base $default_branch $branch) 
		if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]
		then
			git branch -D $branch
		fi
	done
}
gccd () {
	setopt localoptions extendedglob
	local repo="${${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}" 
	command git clone --recurse-submodules "$@" || return
	[[ -d "$_" ]] && cd "$_" || cd "${${repo:t}%.git/#}"
}
gdnolock () {
	git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
gdv () {
	git diff -w "$@" | view -
}
getent () {
	if [[ $1 = hosts ]]
	then
		sed 's/#.*//' /etc/$1 | grep -w $2
	elif [[ $2 = <-> ]]
	then
		grep ":$2:[^:]*$" /etc/$1
	else
		grep "^$2:" /etc/$1
	fi
}
ggf () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force origin "${b:=$1}"
}
ggfl () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force-with-lease origin "${b:=$1}"
}
ggl () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git pull origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git pull origin "${b:=$1}"
	fi
}
ggp () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git push origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git push origin "${b:=$1}"
	fi
}
ggpnp () {
	if [[ "$#" == 0 ]]
	then
		ggl && ggp
	else
		ggl "${*}" && ggp "${*}"
	fi
}
ggu () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git pull --rebase origin "${b:=$1}"
}
git_commits_ahead () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count @{upstream}..HEAD 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$commits$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
		fi
	fi
}
git_commits_behind () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count HEAD..@{upstream} 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX$commits$ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX"
		fi
	fi
}
git_current_branch () {
	local ref
	ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]]
	then
		[[ $ret == 128 ]] && return
		ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo ${ref#refs/heads/}
}
git_current_user_email () {
	__git_prompt_git config user.email 2> /dev/null
}
git_current_user_name () {
	__git_prompt_git config user.name 2> /dev/null
}
git_develop_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local branch
	for branch in dev devel develop development
	do
		if command git show-ref -q --verify refs/heads/$branch
		then
			echo $branch
			return 0
		fi
	done
	echo develop
	return 1
}
git_main_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local ref
	for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}
	do
		if command git show-ref -q --verify $ref
		then
			echo ${ref:t}
			return 0
		fi
	done
	echo master
	return 1
}
git_previous_branch () {
	local ref
	ref=$(__git_prompt_git rev-parse --quiet --symbolic-full-name @{-1} 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]] || [[ -z $ref ]]
	then
		return
	fi
	echo ${ref#refs/heads/}
}
git_prompt_ahead () {
	if [[ -n "$(__git_prompt_git rev-list origin/$(git_current_branch)..HEAD 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
	fi
}
git_prompt_behind () {
	if [[ -n "$(__git_prompt_git rev-list HEAD..origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_BEHIND"
	fi
}
git_prompt_info () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}"
	fi
}
git_prompt_long_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_remote () {
	if [[ -n "$(__git_prompt_git show-ref origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS"
	else
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_MISSING"
	fi
}
git_prompt_short_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_status () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}"
	fi
}
git_remote_status () {
	local remote ahead behind git_remote_status git_remote_status_detailed
	remote=${$(__git_prompt_git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/} 
	if [[ -n ${remote} ]]
	then
		ahead=$(__git_prompt_git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l) 
		behind=$(__git_prompt_git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l) 
		if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}" 
		elif [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		fi
		if [[ -n $ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_PREFIX${remote:gs/%/%%}$git_remote_status_detailed$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_SUFFIX" 
		fi
		echo $git_remote_status
	fi
}
git_repo_name () {
	local repo_path
	if repo_path="$(__git_prompt_git rev-parse --show-toplevel 2>/dev/null)"  && [[ -n "$repo_path" ]]
	then
		echo ${repo_path:t}
	fi
}
grename () {
	if [[ -z "$1" || -z "$2" ]]
	then
		echo "Usage: $0 old_branch new_branch"
		return 1
	fi
	git branch -m "$1" "$2"
	if git push origin :"$1"
	then
		git push --set-upstream origin "$2"
	fi
}
gunwipall () {
	local _commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format=format:%H) 
	if [[ "$_commit" != "$(git rev-parse HEAD)" ]]
	then
		git reset $_commit || return 1
	fi
}
handle_completion_insecurities () {
	local -aU insecure_dirs
	insecure_dirs=(${(f@):-"$(compaudit 2>/dev/null)"}) 
	[[ -z "${insecure_dirs}" ]] && return
	print "[oh-my-zsh] Insecure completion-dependent directories detected:"
	ls -ld "${(@)insecure_dirs}"
	cat <<EOD

[oh-my-zsh] For safety, we will not load completions from these directories until
[oh-my-zsh] you fix their permissions and ownership and restart zsh.
[oh-my-zsh] See the above list for directories with group or other writability.

[oh-my-zsh] To fix your permissions you can do so by disabling
[oh-my-zsh] the write permission of "group" and "others" and making sure that the
[oh-my-zsh] owner of these directories is either root or your current user.
[oh-my-zsh] The following command may help:
[oh-my-zsh]     compaudit | xargs chmod g-w,o-w

[oh-my-zsh] If the above didn't help or you want to skip the verification of
[oh-my-zsh] insecure directories you can set the variable ZSH_DISABLE_COMPFIX to
[oh-my-zsh] "true" before oh-my-zsh is sourced in your zshrc file.

EOD
}
hg_prompt_info () {
	return 1
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
is_plugin () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/plugins/$name/$name.plugin.zsh || builtin test -f $base_dir/plugins/$name/_$name
}
is_theme () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/$name.zsh-theme
}
jenv_prompt_info () {
	return 1
}
mkcd () {
	mkdir -p $@ && cd ${@:$#}
}
nvm_prompt_info () {
	which nvm &> /dev/null || return
	local nvm_prompt=${$(nvm current)#v} 
	echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt:gs/%/%%}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
}
omz () {
	setopt localoptions noksharrays
	[[ $# -gt 0 ]] || {
		_omz::help
		return 1
	}
	local command="$1" 
	shift
	(( ${+functions[_omz::$command]} )) || {
		_omz::help
		return 1
	}
	_omz::$command "$@"
}
omz_diagnostic_dump () {
	emulate -L zsh
	builtin echo "Generating diagnostic dump; please be patient..."
	local thisfcn=omz_diagnostic_dump 
	local -A opts
	local opt_verbose opt_noverbose opt_outfile
	local timestamp=$(date +%Y%m%d-%H%M%S) 
	local outfile=omz_diagdump_$timestamp.txt 
	builtin zparseopts -A opts -D -- "v+=opt_verbose" "V+=opt_noverbose"
	local verbose n_verbose=${#opt_verbose} n_noverbose=${#opt_noverbose} 
	(( verbose = 1 + n_verbose - n_noverbose ))
	if [[ ${#*} > 0 ]]
	then
		opt_outfile=$1 
	fi
	if [[ ${#*} > 1 ]]
	then
		builtin echo "$thisfcn: error: too many arguments" >&2
		return 1
	fi
	if [[ -n "$opt_outfile" ]]
	then
		outfile="$opt_outfile" 
	fi
	_omz_diag_dump_one_big_text &> "$outfile"
	if [[ $? != 0 ]]
	then
		builtin echo "$thisfcn: error while creating diagnostic dump; see $outfile for details"
	fi
	builtin echo
	builtin echo Diagnostic dump file created at: "$outfile"
	builtin echo
	builtin echo To share this with OMZ developers, post it as a gist on GitHub
	builtin echo at "https://gist.github.com" and share the link to the gist.
	builtin echo
	builtin echo "WARNING: This dump file contains all your zsh and omz configuration files,"
	builtin echo "so don't share it publicly if there's sensitive information in them."
	builtin echo
}
omz_history () {
	local clear list stamp REPLY
	zparseopts -E -D c=clear l=list f=stamp E=stamp i=stamp t:=stamp
	if [[ -n "$clear" ]]
	then
		print -nu2 "This action will irreversibly delete your command history. Are you sure? [y/N] "
		builtin read -E
		[[ "$REPLY" = [yY] ]] || return 0
		print -nu2 >| "$HISTFILE"
		fc -p "$HISTFILE"
		print -u2 History file deleted.
	elif [[ $# -eq 0 ]]
	then
		builtin fc "${stamp[@]}" -l 1
	else
		builtin fc "${stamp[@]}" -l "$@"
	fi
}
omz_termsupport_cwd () {
	setopt localoptions unset
	local URL_HOST URL_PATH
	URL_HOST="$(omz_urlencode -P $HOST)"  || return 1
	URL_PATH="$(omz_urlencode -P $PWD)"  || return 1
	[[ -z "$KONSOLE_PROFILE_NAME" && -z "$KONSOLE_DBUS_SESSION" ]] || URL_HOST="" 
	printf "\e]7;file://%s%s\e\\" "${URL_HOST}" "${URL_PATH}"
}
omz_termsupport_precmd () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return 0
	title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}
omz_termsupport_preexec () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return 0
	emulate -L zsh
	setopt extended_glob
	local -a cmdargs
	cmdargs=("${(z)2}") 
	if [[ "${cmdargs[1]}" = fg ]]
	then
		local job_id jobspec="${cmdargs[2]#%}" 
		case "$jobspec" in
			(<->) job_id=${jobspec}  ;;
			("" | % | +) job_id=${(k)jobstates[(r)*:+:*]}  ;;
			(-) job_id=${(k)jobstates[(r)*:-:*]}  ;;
			([?]*) job_id=${(k)jobtexts[(r)*${(Q)jobspec}*]}  ;;
			(*) job_id=${(k)jobtexts[(r)${(Q)jobspec}*]}  ;;
		esac
		if [[ -n "${jobtexts[$job_id]}" ]]
		then
			1="${jobtexts[$job_id]}" 
			2="${jobtexts[$job_id]}" 
		fi
	fi
	local CMD="${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}" 
	local LINE="${2:gs/%/%%}" 
	title "$CMD" "%100>...>${LINE}%<<"
}
omz_urldecode () {
	emulate -L zsh
	local encoded_url=$1 
	local caller_encoding=$langinfo[CODESET] 
	local LC_ALL=C 
	export LC_ALL
	local tmp=${encoded_url:gs/+/ /} 
	tmp=${tmp:gs/\\/\\\\/} 
	tmp=${tmp:gs/%/\\x/} 
	local decoded="$(printf -- "$tmp")" 
	local -a safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]
	then
		decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from UTF-8 to $caller_encoding" >&2
			return 1
		fi
	fi
	echo -E "$decoded"
}
omz_urlencode () {
	emulate -L zsh
	setopt norematchpcre
	local -a opts
	zparseopts -D -E -a opts r m P
	local in_str="$@" 
	local url_str="" 
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]
	then
		spaces_as_plus=1 
	fi
	local str="$in_str" 
	local encoding=$langinfo[CODESET] 
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$encoding]} ]]
	then
		str=$(echo -E "$str" | iconv -f $encoding -t UTF-8) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from $encoding to UTF-8" >&2
			return 1
		fi
	fi
	local i byte ord LC_ALL=C 
	export LC_ALL
	local reserved=';/?:@&=+$,' 
	local mark='_.!~*''()-' 
	local dont_escape="[A-Za-z0-9" 
	if [[ -z $opts[(r)-r] ]]
	then
		dont_escape+=$reserved 
	fi
	if [[ -z $opts[(r)-m] ]]
	then
		dont_escape+=$mark 
	fi
	dont_escape+="]" 
	local url_str="" 
	for ((i = 1; i <= ${#str}; ++i )) do
		byte="$str[i]" 
		if [[ "$byte" =~ "$dont_escape" ]]
		then
			url_str+="$byte" 
		else
			if [[ "$byte" == " " && -n $spaces_as_plus ]]
			then
				url_str+="+" 
			elif [[ "$PREFIX" = *com.termux* ]]
			then
				url_str+="$byte" 
			else
				ord=$(( [##16] #byte )) 
				url_str+="%$ord" 
			fi
		fi
	done
	echo -E "$url_str"
}
open_command () {
	local open_cmd
	case "$OSTYPE" in
		(darwin*) open_cmd='open'  ;;
		(cygwin*) open_cmd='cygstart'  ;;
		(linux*) [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open'  || {
				open_cmd='cmd.exe /c start ""' 
				[[ -e "$1" ]] && {
					1="$(wslpath -w "${1:a}")"  || return 1
				}
				[[ "$1" = (http|https)://* ]] && {
					1="$(echo "$1" | sed -E 's/([&|()<>^])/^\1/g')"  || return 1
				}
			} ;;
		(msys*) open_cmd='start ""'  ;;
		(*) echo "Platform $OSTYPE not supported"
			return 1 ;;
	esac
	if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]
	then
		"$BROWSER" "$@"
		return
	fi
	${=open_cmd} "$@" &> /dev/null
}
parse_git_dirty () {
	local STATUS
	local -a FLAGS
	FLAGS=('--porcelain') 
	if [[ "$(__git_prompt_git config --get oh-my-zsh.hide-dirty)" != "1" ]]
	then
		if [[ "${DISABLE_UNTRACKED_FILES_DIRTY:-}" == "true" ]]
		then
			FLAGS+='--untracked-files=no' 
		fi
		case "${GIT_STATUS_IGNORE_SUBMODULES:-}" in
			(git)  ;;
			(*) FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"  ;;
		esac
		STATUS=$(__git_prompt_git status ${FLAGS} 2> /dev/null | tail -n 1) 
	fi
	if [[ -n $STATUS ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
	else
		echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
	fi
}
prompt_spaceship_chpwd () {
	spaceship::worker::eval builtin cd -q $PWD
	spaceship_exec_time_start
}
prompt_spaceship_precmd () {
	RETVAL=$? 
	RETVALS=("$pipestatus[@]") 
	spaceship_exec_time_stop
	spaceship::worker::init
	spaceship::core::start
	spaceship::populate
}
prompt_spaceship_preexec () {
	spaceship::worker::flush
	spaceship_exec_time_start
}
prompt_spaceship_setup () {
	autoload -Uz vcs_info
	autoload -Uz add-zsh-hook
	autoload -Uz add-zsh-hook
	autoload -Uz is-at-least
	if ! is-at-least 5.2
	then
		print -P "%Bspaceship-prompt%b requires at least %Bzsh v5.2%b (you have %Bv$ZSH_VERSION%b)."
		print -P "Please upgrade your zsh installation."
	fi
	prompt_opts=(cr percent sp subst) 
	setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"
	zmodload zsh/datetime
	zmodload zsh/mathfunc
	add-zsh-hook preexec prompt_spaceship_preexec
	add-zsh-hook precmd prompt_spaceship_precmd
	add-zsh-hook chpwd prompt_spaceship_chpwd
	VIRTUAL_ENV_DISABLE_PROMPT=true 
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:git*' formats '%b'
	spaceship::core::load_sections
}
pyenv_prompt_info () {
	return 1
}
rbenv_prompt_info () {
	return 1
}
regexp-replace () {
	argv=("$1" "$2" "$3") 
	4=0 
	[[ -o re_match_pcre ]] && 4=1 
	emulate -L zsh
	local MATCH MBEGIN MEND
	local -a match mbegin mend
	if (( $4 ))
	then
		zmodload zsh/pcre || return 2
		pcre_compile -- "$2" && pcre_study || return 2
		4=0 6= 
		local ZPCRE_OP
		while pcre_match -b -n $4 -- "${(P)1}"
		do
			5=${(e)3} 
			argv+=(${(s: :)ZPCRE_OP} "$5") 
			4=$((argv[-2] + (argv[-3] == argv[-2]))) 
		done
		(($# > 6)) || return
		set +o multibyte
		5= 6=1 
		for 2 3 4 in "$@[7,-1]"
		do
			5+=${(P)1[$6,$2]}$4 
			6=$(($3 + 1)) 
		done
		5+=${(P)1[$6,-1]} 
	else
		4=${(P)1} 
		while [[ -n $4 ]]
		do
			if [[ $4 =~ $2 ]]
			then
				5+=${4[1,MBEGIN-1]}${(e)3} 
				if ((MEND < MBEGIN))
				then
					((MEND++))
					5+=${4[1]} 
				fi
				4=${4[MEND+1,-1]} 
				6=1 
			else
				break
			fi
		done
		[[ -n $6 ]] || return
		5+=$4 
	fi
	eval $1=\$5
}
ruby_prompt_info () {
	echo "$(rvm_prompt_info || rbenv_prompt_info || chruby_prompt_info)"
}
rvm_prompt_info () {
	[ -f $HOME/.rvm/bin/rvm-prompt ] || return 1
	local rvm_prompt
	rvm_prompt=$($HOME/.rvm/bin/rvm-prompt ${=ZSH_THEME_RVM_PROMPT_OPTIONS} 2>/dev/null) 
	[[ -z "${rvm_prompt}" ]] && return 1
	echo "${ZSH_THEME_RUBY_PROMPT_PREFIX}${rvm_prompt:gs/%/%%}${ZSH_THEME_RUBY_PROMPT_SUFFIX}"
}
spaceship () {
	zparseopts -E -D h=help -help=help v=version -version=version
	local cmd="$1" 
	if [[ -n $help ]]
	then
		_spaceship::cli::help "${(@)@:2}"
		return 0
	fi
	if [[ -n "$version" ]]
	then
		_spaceship::cli::version "${(@)@:2}"
		return 0
	fi
	(( $+functions[_spaceship::cli::$cmd] )) || {
		_spaceship::cli::help
		return 1
	}
	shift
	_spaceship::cli::$cmd "$@"
}
spaceship::cache::clear () {
	SPACESHIP_CACHE=() 
}
spaceship::cache::get () {
	local key="$1" 
	echo -n "${SPACESHIP_CACHE[$key]}"
}
spaceship::cache::set () {
	local key="$1" value="$2" 
	SPACESHIP_CACHE[$key]="$value" 
}
spaceship::core::async_callback () {
	local job="$1" code="$2" output="$3" exec_time="$4" err="$5" has_next="$6" 
	local section="${job#"spaceship_"}" 
	spaceship::worker::callback "$@"
	case $job in
		("[async]") if (( code == 2 )) || (( code == 3 )) || (( code == 130 ))
			then
				spaceship::worker::init
				spaceship::core::start
				return
			fi ;;
		("[async/eval]") if (( code ))
			then
				spaceship::core::start
				return
			fi ;;
		(";") return ;;
		(*) if [[ "${#SPACESHIP_JOBS}" -eq 0 ]]
			then
				if spaceship::includes SPACESHIP_PROMPT_ORDER "async" || spaceship::includes SPACESHIP_RPROMPT_ORDER "async"
				then
					spaceship::core::refresh_section "async"
				fi
				spaceship::core::render
			fi
			if [[ "$(spaceship::cache::get $section)" == "$output" ]]
			then
				return
			fi
			spaceship::cache::set "$section" "$output" ;;
	esac
	if [[ "$has_next" == 0 ]]
	then
		spaceship::core::render
	fi
}
spaceship::core::compose_order () {
	for section in $@
	do
		spaceship::section::render "$(spaceship::cache::get $section)"
	done
}
spaceship::core::load_sections () {
	local load_async=false 
	for section in $(spaceship::union $SPACESHIP_PROMPT_ORDER $SPACESHIP_RPROMPT_ORDER)
	do
		if spaceship::defined "spaceship_$section"
		then
			continue
		elif [[ -f "$SPACESHIP_ROOT/sections/$section.zsh" ]]
		then
			builtin source "$SPACESHIP_ROOT/sections/$section.zsh"
			spaceship::precompile "$SPACESHIP_ROOT/sections/$section.zsh"
		else
			spaceship::core::skip_section "$section"
			continue
		fi
		if spaceship::is_section_async "$section"
		then
			load_async=true 
		fi
	done
	if $load_async
	then
		spaceship::worker::load
	fi
}
spaceship::core::refresh_section () {
	zparseopts -E -D -sync=sync
	local section="$1" 
	[[ -z $section ]] && return 1
	setopt EXTENDED_GLOB LOCAL_OPTIONS
	if ! spaceship::defined "spaceship_$section"
	then
		spaceship::core::skip_section "$section"
		return 1
	fi
	if spaceship::is_section_async "$section" && [[ -z $sync ]]
	then
		spaceship::worker::run "spaceship_$section"
	else
		spaceship::cache::set "$section" "$(spaceship_$section)"
	fi
}
spaceship::core::render () {
	spaceship::populate
	zle && zle .reset-prompt && zle -R
}
spaceship::core::skip_section () {
	local section="$1" 
	print -P "%F{yellow}Warning!%f The '%F{cyan}${section}%f' section was not found. Removing it from the prompt."
	SPACESHIP_PROMPT_ORDER=("${(@)SPACESHIP_PROMPT_ORDER:#${section}}") 
	SPACESHIP_RPROMPT_ORDER=("${(@)SPACESHIP_RPROMPT_ORDER:#${section}}") 
}
spaceship::core::start () {
	spaceship::cache::clear
	for section in $(spaceship::union $SPACESHIP_PROMPT_ORDER $SPACESHIP_RPROMPT_ORDER)
	do
		spaceship::core::refresh_section "$section"
	done
}
spaceship::datafile () {
	spaceship::extract "$@"
}
spaceship::defined () {
	typeset -f + "$1" &> /dev/null
}
spaceship::deprecated () {
	[[ -n $1 ]] || return
	local deprecated=$1 message=$2 
	local deprecated_value=${(P)deprecated} 
	[[ -n $deprecated_value ]] || return
	print -P "%B$deprecated%b is deprecated. $message"
}
spaceship::displaytime () {
	local duration="$1" precision="$2" 
	[[ -z "$precision" ]] && precision=1 
	integer D=$((duration/60/60/24)) 
	integer H=$((duration/60/60%24)) 
	integer M=$((duration/60%60)) 
	local S=$((duration%60)) 
	[[ $D > 0 ]] && printf '%dd ' $D
	[[ $H > 0 ]] && printf '%dh ' $H
	[[ $M > 0 ]] && printf '%dm ' $M
	printf %.${precision}f%s $S s
}
spaceship::exists () {
	command -v $1 > /dev/null 2>&1
}
spaceship::extract () {
	zparseopts -E -D -json=json -yaml=yaml -toml=toml -xml=xml
	local file="$1" 
	shift
	if [[ -n "$yaml" ]]
	then
		if spaceship::exists yq
		then
			spaceship::extract::jq yq "$file" "$@"
		elif spaceship::exists ruby
		then
			spaceship::extract::ruby::yaml "$file" "$@"
		elif spaceship::exists python3
		then
			spaceship::extract::python::yaml "$file" "$@"
		else
			return 1
		fi
	fi
	if [[ -n "$json" ]]
	then
		if spaceship::exists jq
		then
			spaceship::extract::jq jq "$file" "$@"
		elif spaceship::exists yq
		then
			spaceship::extract::jq yq "$file" "$@"
		elif spaceship::exists ruby
		then
			spaceship::extract::ruby::json "$file" "$@"
		elif spaceship::exists python3
		then
			spaceship::extract::python::json "$file" "$@"
		elif spaceship::exists node
		then
			spaceship::extract::node::json "$file" "$@"
		else
			return 1
		fi
	fi
	if [[ -n "$toml" ]]
	then
		if spaceship::exists tomlq
		then
			spaceship::extract::jq tomlq "$file" "$@"
		elif spaceship::exists python3
		then
			spaceship::extract::python::toml "$file" "$@"
		else
			return 1
		fi
	fi
	if [[ -n "$xml" ]]
	then
		if spaceship::exists xq
		then
			spaceship::extract::jq xq "$file" "$@"
		else
			return 1
		fi
	fi
	return 1
}
spaceship::extract::jq () {
	local exe=$1 file=$2 
	shift 2
	local keys=("$@") 
	"$exe" -r ".${(j| // .|)keys}" "$file" 2> /dev/null
}
spaceship::extract::node::json () {
	local file=$1 
	shift
	local keys=("$@") 
	node -p "['${(j|','|)keys}'].map(s => s.split('.').reduce((obj, key) => obj[key], require('./$file'))).find(Boolean)" 2> /dev/null
}
spaceship::extract::python () {
	local imports=$1 load=$2 
	shift 2
	local keys=("$@") 
	python -c "import $imports, functools; data=$load; print(next(filter(None, map(lambda key: functools.reduce(lambda obj, key: obj[key] if key in obj else {}, key.split('.'), data), ['${(j|','|)keys}'])), None))" 2> /dev/null
}
spaceship::extract::python::json () {
	local file=$1 
	shift
	spaceship::extract::python json "json.load(open('$file'))" "$@"
}
spaceship::extract::python::toml () {
	local file=$1 
	shift
	local import py_version="${(@)$(python3 -V 2>&1)[2]}" 
	autoload is-at-least
	if is-at-least 3.11 "$py_version" ]]
	then
		import=tomllib 
	else
		import=tomli 
	fi
	spaceship::extract::python "$import" "$import.load(open('$file', 'rb'))" "$@"
}
spaceship::extract::python::yaml () {
	local file=$1 
	shift
	spaceship::extract::python yaml "yaml.safe_load(open('$file'))" "$@"
}
spaceship::extract::ruby () {
	local import=$1 load=$2 
	shift 2
	local keys=("$@") 
	ruby -r "$import" -e "puts ['${(j|','|)keys}'].map { |key| key.split('.').reduce($load) { |obj, key| obj[key] } }.find(&:itself)" 2> /dev/null
}
spaceship::extract::ruby::json () {
	local file=$1 
	shift
	spaceship::extract::ruby 'json' "JSON::load(File.read('$file'))" "$@"
}
spaceship::extract::ruby::yaml () {
	local file=$1 
	shift
	spaceship::extract::ruby 'yaml' "YAML::load_file('$file')" "$@"
}
spaceship::grep () {
	local GREP_OPTIONS="" 
	if command grep --color=never "" &> /dev/null <<< ""
	then
		GREP_OPTIONS="--color=never" 
	fi
	command grep $GREP_OPTIONS "$@"
}
spaceship::includes () {
	local array_name="$1" item="$2" 
	local array=("${(@P)array_name}") 
	(( $array[(Ie)$item] ))
}
spaceship::is_git () {
	[[ $(command git rev-parse --is-inside-work-tree 2>/dev/null) == true ]]
}
spaceship::is_hg () {
	local hg_root="$(spaceship::upsearch .hg)" 
	[[ -n "$hg_root" ]] &> /dev/null
}
spaceship::is_prompt_async () {
	[[ "$SPACESHIP_PROMPT_ASYNC" == true ]] && (( ASYNC_INIT_DONE ))
}
spaceship::is_section_async () {
	local section="$1" 
	local sync_sections=(user dir host exec_time async line_sep jobs exit_code char) 
	if spaceship::includes sync_sections "$section"
	then
		return 1
	fi
	if [[ "$SPACESHIP_PROMPT_ASYNC" != true ]]
	then
		return 1
	fi
	local async_option="SPACESHIP_${(U)section}_ASYNC" 
	[[ "${(P)async_option}" == true ]]
}
spaceship::populate () {
	PROMPT='$(spaceship::prompt)' 
	RPROMPT='$(spaceship::rprompt)' 
	PS2='$(spaceship::ps2)' 
}
spaceship::precompile () {
	spaceship::exists zcompile || return 1
	local file="$1" 
	if [[ ! $file.zwc -nt $file && -w "$(dirname $1)" ]]
	then
		zcompile -R -- $file.zwc $file
	fi
}
spaceship::prompt () {
	_spaceship_prompt_opened="$SPACESHIP_PROMPT_FIRST_PREFIX_SHOW" 
	local prompt="$(spaceship::core::compose_order $SPACESHIP_PROMPT_ORDER)" 
	if [[ "${ITERM_SHELL_INTEGRATION_INSTALLED:-}" == "Yes" ]]
	then
		prompt="%{$(iterm2_prompt_mark)%}${prompt}%{$(iterm2_prompt_end)%}" 
	fi
	if [[ $SPACESHIP_PROMPT_ADD_NEWLINE == true ]]
	then
		prompt="\n${prompt}" 
	fi
	echo -n "$prompt"
}
spaceship::ps2 () {
	local char="${SPACESHIP_CHAR_SYMBOL_SECONDARY="$SPACESHIP_CHAR_SYMBOL"}" 
	local ps2="$(spaceship::section --color "$SPACESHIP_CHAR_COLOR_SECONDARY" "$char")" 
	spaceship::section::render "$ps2"
}
spaceship::rprompt () {
	_spaceship_rprompt_opened="$SPACESHIP_RPROMPT_FIRST_PREFIX_SHOW" 
	local rprompt="$(spaceship::core::compose_order $SPACESHIP_RPROMPT_ORDER)" 
	if [[ "$SPACESHIP_RPROMPT_ADD_NEWLINE" != true ]]
	then
		local rprompt_prefix='%{'$'\e[1A''%}' 
		local rprompt_suffix='%{'$'\e[1B''%}' 
		rprompt="$rprompt_prefix$rprompt$rprompt_suffix" 
	fi
	echo -n "$rprompt"
}
spaceship::section () {
	zparseopts -E -D -color:=color_ -prefix:=prefix_ -suffix:=suffix_ -symbol:=symbol_
	local color="${color_[2]}" prefix="${prefix_[2]}" suffix="${suffix_[2]}" symbol="${symbol_[2]}" 
	local content="$@" 
	local tuple=() 
	tuple+=("(") 
	tuple+=("$color") 
	tuple+=("$prefix") 
	tuple+=("$suffix") 
	tuple+=("$symbol") 
	tuple+=("$content") 
	tuple+=(")") 
	echo -n "${(j:·|·:)tuple}"
}
spaceship::section::render () {
	local tuple="$1" section_data=() result="" 
	section_data=("${(@s:·|·:)tuple}") 
	local opener="" color="" prefix="" content="" suffix="" closer="" 
	opener="${section_data[1]}" 
	color="${section_data[2]}" 
	color="%F{$color}" 
	prefix="${section_data[3]}" 
	suffix="${section_data[4]}" 
	symbol="${section_data[5]}" 
	content="${section_data[6]}" 
	closer="${section_data[7]}" 
	if [[ -z "$content" && -z "$symbol" ]]
	then
		return
	fi
	if [[ "$_spaceship_prompt_opened" == true || "$_spaceship_rprompt_opened" == true ]] && [[ "$SPACESHIP_PROMPT_PREFIXES_SHOW" == true ]] && [[ -n "$prefix" ]]
	then
		result+="%{%B%}" 
		result+="$prefix" 
		result+="%{%b%}" 
	fi
	_spaceship_prompt_opened=true 
	_spaceship_rprompt_opened=true 
	result+="%{%B$color%}" 
	result+="$symbol$content" 
	result+="%{%b%f%}" 
	if [[ "$SPACESHIP_PROMPT_SUFFIXES_SHOW" == true ]] && [[ -n "$suffix" ]]
	then
		result+="%{%B%}" 
		result+="$suffix" 
		result+="%{%b%}" 
	fi
	echo -n "$result"
}
spaceship::section::v3 () {
	local color prefix content suffix
	[[ -n "$1" ]] && color="$1"  || color="" 
	[[ -n "$2" ]] && prefix="$2"  || prefix="" 
	[[ -n "$3" ]] && content="$3"  || content="" 
	[[ -n "$4" ]] && suffix="$4"  || suffix="" 
	[[ -z $3 && -z $4 ]] && content="$2" prefix='' 
	spaceship::section::v4 --color "$color" --prefix "$prefix" --suffix "$suffix" "$content"
}
spaceship::section::v4 () {
	spaceship::section "$@"
}
spaceship::testkit::render_prompt () {
	prompt_spaceship_precmd
	spaceship::prompt "$*"
}
spaceship::testkit::render_ps2 () {
	prompt_spaceship_precmd
	spaceship::ps2 "$*"
}
spaceship::testkit::render_rprompt () {
	prompt_spaceship_precmd
	spaceship::rprompt "$*"
}
spaceship::union () {
	typeset -U sections=("$@") 
	echo $sections
}
spaceship::upsearch () {
	zparseopts -E -D s=silent -silent=silent
	local files=("$@") 
	local root="$(pwd -P)" 
	while [ "$root" ]
	do
		for file in "${files[@]}"
		do
			local find_match="$(find $root -maxdepth 1 -name $file -print -quit 2>/dev/null)" 
			local filename="$root/$file" 
			if [[ -n "$find_match" ]]
			then
				[[ -z "$silent" ]] && echo "$find_match"
				return 0
			elif [[ -e "$filename" ]]
			then
				[[ -z "$silent" ]] && echo "$filename"
				return 0
			fi
		done
		if [[ -d "$root/.git" || -d "$root/.hg" ]]
		then
			return 1
		fi
		root="${root%/*}" 
	done
	return 1
}
spaceship::worker::callback () {
	SPACESHIP_JOBS=("${(@)SPACESHIP_JOBS:#${1}}") 
}
spaceship::worker::eval () {
	if spaceship::is_prompt_async
	then
		async_worker_eval "spaceship" "$@"
	fi
}
spaceship::worker::flush () {
	if spaceship::is_prompt_async
	then
		async_flush_jobs "spaceship"
	fi
}
spaceship::worker::init () {
	if spaceship::is_prompt_async
	then
		SPACESHIP_JOBS=() 
		async_stop_worker "spaceship"
		async_start_worker "spaceship" -n -u
		async_worker_eval "spaceship" setopt extendedglob
		async_worker_eval "spaceship" spaceship::worker::renice
		async_register_callback "spaceship" spaceship::core::async_callback
	fi
}
spaceship::worker::load () {
	if ! (( ASYNC_INIT_DONE ))
	then
		builtin source "$SPACESHIP_ROOT/async.zsh"
		spaceship::precompile "$SPACESHIP_ROOT/async.zsh"
	fi
}
spaceship::worker::renice () {
	if command -v renice > /dev/null
	then
		command renice +15 -p $$
	fi
	if command -v ionice > /dev/null
	then
		command ionice -c 3 -p $$
	fi
}
spaceship::worker::run () {
	if spaceship::is_prompt_async
	then
		SPACESHIP_JOBS+=("$1") 
		async_job "spaceship" "$@"
	fi
}
spaceship_ansible () {
	[[ $SPACESHIP_ANSIBLE_SHOW == false ]] && return
	spaceship::exists ansible || return
	local ansible_configs="$(spaceship::upsearch ansible.cfg .ansible.cfg)" 
	local yaml_files="$(echo ?(*.yml|*.yaml)([1]N^/))" 
	local detected_playbooks
	if [[ -n "$yaml_files" ]]
	then
		detected_playbooks="$(spaceship::grep -oE "tasks|hosts|roles" $yaml_files)" 
	fi
	[[ -n "$ansible_configs" || -n "$detected_playbooks" ]] || return
	local ansible_version=$(ansible --version | head -1 | spaceship::grep -oE '([0-9]+\.)([0-9]+\.)?([0-9]+)') 
	spaceship::section --color "$SPACESHIP_ANSIBLE_COLOR" --prefix "$SPACESHIP_ANSIBLE_PREFIX" --suffix "$SPACESHIP_ANSIBLE_SUFFIX" --symbol "$SPACESHIP_ANSIBLE_SYMBOL" "v$ansible_version"
}
spaceship_async () {
	spaceship::is_prompt_async || return
	[[ "$SPACESHIP_ASYNC_SHOW" == false ]] && return
	local jobs_count=${#SPACESHIP_JOBS} 
	local content
	(( $jobs_count == 0 )) && return
	if [[ "$SPACESHIP_ASYNC_SHOW_COUNT" == true ]]
	then
		content="$jobs_count" 
	fi
	spaceship::section --color "$SPACESHIP_ASYNC_COLOR" --prefix "$SPACESHIP_ASYNC_PREFIX" --suffix "$SPACESHIP_ASYNC_SUFFIX" --symbol "$SPACESHIP_ASYNC_SYMBOL" "$content"
}
spaceship_aws () {
	[[ $SPACESHIP_AWS_SHOW == false ]] && return
	local profile=${AWS_VAULT:-$AWS_PROFILE} 
	[[ -z $profile ]] || [[ "$profile" == "default" ]] && return
	spaceship::section --color "$SPACESHIP_AWS_COLOR" --prefix "$SPACESHIP_AWS_PREFIX" --suffix "$SPACESHIP_AWS_SUFFIX" --symbol "$SPACESHIP_AWS_SYMBOL" "$profile"
}
spaceship_azure () {
	[[ $SPACESHIP_AZURE_SHOW == false ]] && return
	spaceship::exists az || return
	AZ_ACCOUNT=$(az account show --query name --output tsv 2>/dev/null) 
	[[ -z "$AZ_ACCOUNT" ]] && return
	spaceship::section --color "$SPACESHIP_AZURE_COLOR" --prefix "$SPACESHIP_AZURE_PREFIX" --suffix "$SPACESHIP_AZURE_SUFFIX" --symbol "$SPACESHIP_AZURE_SYMBOL" "$AZ_ACCOUNT"
}
spaceship_battery () {
	[[ $SPACESHIP_BATTERY_SHOW == false ]] && return
	local battery_data battery_percent battery_status battery_color
	if spaceship::exists pmset
	then
		battery_data=$(pmset -g batt | grep "InternalBattery") 
		[[ -z "$battery_data" ]] && return
		battery_percent="$( echo $battery_data | \grep -oE '[0-9]{1,3}%' )" 
		battery_status="$( echo $battery_data | awk -F '; *' '{ print $2 }' )" 
	elif spaceship::exists acpi
	then
		battery_data=$(acpi -b 2>/dev/null | head -1) 
		[[ -z $battery_data ]] && return
		battery_status_and_percent="$(echo $battery_data |  sed 's/Battery [0-9]*: \(.*\), \([0-9]*\)%.*/\1:\2/')" 
		battery_status_and_percent_array=("${(@s/:/)battery_status_and_percent}") 
		battery_status=$battery_status_and_percent_array[1]:l 
		battery_percent=$battery_status_and_percent_array[2] 
		[[ $battery_percent == "0" ]] && return
	elif spaceship::exists upower
	then
		local battery=$(command upower -e | grep battery | head -1) 
		[[ -z $battery ]] && return
		battery_data=$(upower -i $battery) 
		battery_percent="$( echo "$battery_data" | grep percentage | awk '{print $2}' )" 
		battery_status="$( echo "$battery_data" | grep state | awk '{print $2}' )" 
	else
		return
	fi
	battery_percent="$(echo $battery_percent | tr -d '%[,;]')" 
	if [[ $battery_percent == 100 || $battery_status =~ "(charged|full)" ]]
	then
		battery_color="green" 
	elif [[ $battery_percent -lt $SPACESHIP_BATTERY_THRESHOLD ]]
	then
		battery_color="red" 
	else
		battery_color="yellow" 
	fi
	if [[ $battery_status == "charging" ]]
	then
		battery_symbol="${SPACESHIP_BATTERY_SYMBOL_CHARGING}" 
	elif [[ $battery_status =~ "^[dD]ischarg.*" ]]
	then
		battery_symbol="${SPACESHIP_BATTERY_SYMBOL_DISCHARGING}" 
	else
		battery_symbol="${SPACESHIP_BATTERY_SYMBOL_FULL}" 
	fi
	if [[ $SPACESHIP_BATTERY_SHOW == 'always' || $battery_percent -lt $SPACESHIP_BATTERY_THRESHOLD || ( $SPACESHIP_BATTERY_SHOW == 'charged' && $battery_status =~ "(charged|full)" ) ]]
	then
		spaceship::section --color "$battery_color" --prefix "$SPACESHIP_BATTERY_PREFIX" --suffix "$SPACESHIP_BATTERY_SUFFIX" --symbol "$battery_symbol" "$battery_percent%%"
	fi
}
spaceship_bun () {
	[[ $SPACESHIP_BUN_SHOW == false ]] && return
	spaceship::upsearch -s bun.lockb bunfig.toml || return
	spaceship::exists bun || return
	local bun_version=$(bun --version) 
	spaceship::section --color "$SPACESHIP_BUN_COLOR" --prefix "$SPACESHIP_BUN_PREFIX" --suffix "$SPACESHIP_BUN_SUFFIX" --symbol "$SPACESHIP_BUN_SYMBOL" "v$bun_version"
}
spaceship_char () {
	local color char
	if [[ $RETVAL -eq 0 ]]
	then
		color="$SPACESHIP_CHAR_COLOR_SUCCESS" 
		char="$SPACESHIP_CHAR_SYMBOL_SUCCESS" 
	else
		color="$SPACESHIP_CHAR_COLOR_FAILURE" 
		char="$SPACESHIP_CHAR_SYMBOL_FAILURE" 
	fi
	if [[ $UID -eq 0 ]]
	then
		char="$SPACESHIP_CHAR_SYMBOL_ROOT" 
	fi
	spaceship::section --color "$color" --prefix "$SPACESHIP_CHAR_PREFIX" --suffix "$SPACESHIP_CHAR_SUFFIX" --symbol "$char"
}
spaceship_conda () {
	[[ $SPACESHIP_CONDA_SHOW == false ]] && return
	spaceship::exists conda && [ -n "$CONDA_DEFAULT_ENV" ] || return
	local conda_env=${CONDA_DEFAULT_ENV} 
	if [[ $SPACESHIP_CONDA_VERBOSE == false ]]
	then
		conda_env=${CONDA_DEFAULT_ENV:t} 
	fi
	spaceship::section --color "$SPACESHIP_CONDA_COLOR" --prefix "$SPACESHIP_CONDA_PREFIX" --suffix "$SPACESHIP_CONDA_SUFFIX" --symbol "$SPACESHIP_CONDA_SYMBOL" "$conda_env"
}
spaceship_crystal () {
	[[ $SPACESHIP_CRYSTAL_SHOW == false ]] && return
	spaceship::exists crystal || return
	local is_crystal_project="$(spaceship::upsearch shard.yml)" 
	[[ -n "$is_crystal_project" || -n *.cr(#qN^/) ]] || return
	local crystal_version=$(crystal --version | awk '/Crystal*/ {print $2}') 
	spaceship::section --color "$SPACESHIP_CRYSTAL_COLOR" --prefix "$SPACESHIP_CRYSTAL_PREFIX" --suffix "$SPACESHIP_CRYSTAL_SUFFIX" --symbol "$SPACESHIP_CRYSTAL_SYMBOL" "v$crystal_version"
}
spaceship_dart () {
	[[ $SPACESHIP_DART_SHOW == false ]] && return
	spaceship::exists dart || return
	local is_dart_project="$(spaceship::upsearch pubspec.yaml pubspec.yml pubspec.lock dart_tool)" 
	[[ -n "$is_dart_project" || -n *.dart(#qN^/) ]] || return
	local dart_version=$(dart --version | awk '{sub(/-.*/, "", $4); print $4}') 
	spaceship::section --color "$SPACESHIP_DART_COLOR" --prefix "$SPACESHIP_DART_PREFIX" --suffix "$SPACESHIP_DART_SUFFIX" --symbol "${SPACESHIP_DART_SYMBOL}" "v${dart_version}"
}
spaceship_deno () {
	[[ $SPACESHIP_DENO_SHOW == false ]] && return
	spaceship::exists deno || return
	local is_deno_project="$(spaceship::upsearch deno.json deno.jsonc)" 
	[[ -n "$is_deno_project" || -n {mod,dep,main,cli}.ts(#qN^/) ]] || return
	local deno_version=$(deno --version 2>/dev/null | head -1 | cut -d' ' -f2) 
	[[ "$deno_version" == "$SPACESHIP_DENO_DEFAULT_VERSION" ]] && return
	spaceship::section --color "$SPACESHIP_DENO_COLOR" --prefix "$SPACESHIP_DENO_PREFIX" --suffix "$SPACESHIP_DENO_SUFFIX" --symbol "$SPACESHIP_DENO_SYMBOL" "v$deno_version"
}
spaceship_dir () {
	[[ $SPACESHIP_DIR_SHOW == false ]] && return
	local dir trunc_prefix
	if [[ $SPACESHIP_DIR_TRUNC_REPO == true ]] && spaceship::is_git
	then
		local git_root=$(git rev-parse --show-toplevel) 
		if (
				cygpath --version
			) > /dev/null 2> /dev/null
		then
			git_root=$(cygpath -u $git_root) 
		fi
		if [[ $git_root:h == / ]]
		then
			trunc_prefix=/ 
		else
			trunc_prefix=$SPACESHIP_DIR_TRUNC_PREFIX 
		fi
		dir="$trunc_prefix$git_root:t${${PWD:A}#$~~git_root}" 
	else
		if [[ SPACESHIP_DIR_TRUNC -gt 0 ]]
		then
			trunc_prefix="%($((SPACESHIP_DIR_TRUNC + 1))~|$SPACESHIP_DIR_TRUNC_PREFIX|)" 
		fi
		dir="$trunc_prefix%${SPACESHIP_DIR_TRUNC}~" 
	fi
	local suffix="$SPACESHIP_DIR_SUFFIX" 
	if [[ ! -w . ]]
	then
		suffix="%F{$SPACESHIP_DIR_LOCK_COLOR}${SPACESHIP_DIR_LOCK_SYMBOL}%f${SPACESHIP_DIR_SUFFIX}" 
	fi
	spaceship::section --color "$SPACESHIP_DIR_COLOR" --prefix "$SPACESHIP_DIR_PREFIX" --suffix "$suffix" "$dir"
}
spaceship_docker () {
	[[ $SPACESHIP_DOCKER_SHOW == false ]] && return
	spaceship::exists docker || return
	if [[ -n "$COMPOSE_FILE" ]]
	then
		local compose_path
		local separator=${COMPOSE_PATH_SEPARATOR:-":"} 
		local filenames=("${(@ps/$separator/)COMPOSE_FILE}") 
		local compose_path="$(spaceship::upsearch -s $filenames)" 
		[[ -n "$compose_path" ]] || return
	fi
	local docker_context="$(spaceship_docker_context)" 
	local docker_context_section="$(spaceship::section::render $docker_context)" 
	local docker_project_globs=('Dockerfile' '.devcontainer/Dockerfile' 'docker-compose.y*ml') 
	local is_docker_project="$(spaceship::upsearch Dockerfile $docker_project_globs)" 
	[[ -n "$is_docker_project" || -f /.dockerenv || -n "$docker_context" ]] || return
	local docker_version=$(docker version -f "{{.Server.Version}}" 2>/dev/null) 
	[[ $? -ne 0 || -z $docker_version ]] && return
	[[ $SPACESHIP_DOCKER_VERBOSE == false ]] && docker_version=${docker_version%-*} 
	spaceship::section --color "$SPACESHIP_DOCKER_COLOR" --prefix "$SPACESHIP_DOCKER_PREFIX" --suffix "$SPACESHIP_DOCKER_SUFFIX" --symbol "$SPACESHIP_DOCKER_SYMBOL" "v${docker_version}${docker_context_section}"
}
spaceship_docker_compose () {
	[[ $SPACESHIP_DOCKER_COMPOSE_SHOW == false ]] && return
	spaceship::exists docker-compose || return
	local docker_compose_globs=('docker-compose.y*ml' 'compose.y*ml') 
	spaceship::upsearch -s $docker_compose_globs || return
	local containers="$(docker-compose ps -a 2>/dev/null | tail -n+2)" 
	[[ -n "$containers" ]] || return
	local statuses="" 
	while IFS= read -r line
	do
		local letter_position=$(echo $line | awk 'match($0,"_"){print RSTART}') 
		local letter=$(echo ${line:$letter:1} | tr '[:lower:]' '[:upper:]') 
		local color="" 
		[[ -z "$letter" ]] && continue
		if [[ "$line" == *"Up"* ]] || [[ "$line" == *"running"* ]]
		then
			color="$SPACESHIP_DOCKER_COMPOSE_COLOR_UP" 
		elif [[ "$line" == *"Paused"* ]] || [[ "$line" == *"paused"* ]]
		then
			color="$SPACESHIP_DOCKER_COMPOSE_COLOR_PAUSED" 
		else
			color="$SPACESHIP_DOCKER_COMPOSE_COLOR_DOWN" 
		fi
		statuses+="$(spaceship_docker_compose::paint $color $letter)" 
	done <<< "$containers"
	spaceship::section --color "$SPACESHIP_DOCKER_COMPOSE_COLOR" --prefix "$SPACESHIP_DOCKER_COMPOSE_PREFIX" --suffix "$SPACESHIP_DOCKER_COMPOSE_SUFFIX" --symbol "$SPACESHIP_DOCKER_COMPOSE_SYMBOL" "$statuses"
}
spaceship_docker_compose::paint () {
	local color="$1" text="$2" 
	echo -n "%{%F{$color}%}$text%{%f%}"
}
spaceship_docker_context () {
	[[ $SPACESHIP_DOCKER_CONTEXT_SHOW == false ]] && return
	local docker_remote_context
	if [[ -n $DOCKER_MACHINE_NAME ]]
	then
		docker_remote_context="$DOCKER_MACHINE_NAME" 
	elif [[ -n $DOCKER_HOST ]]
	then
		docker_remote_context="$(basename $DOCKER_HOST | cut -d':' -f1)" 
	else
		docker_remote_context=$(docker context ls --format '{{if .Current}}{{if and (ne .Name "default") (ne .Name "desktop-linux") (ne .Name "colima")}}{{.Name}}{{end}}{{end}}' 2>/dev/null) 
		[[ $? -ne 0 ]] && return
		docker_remote_context=$(echo $docker_remote_context | tr -d '\n') 
	fi
	[[ -z $docker_remote_context ]] && return
	spaceship::section --color "$SPACESHIP_DOCKER_COLOR" "$SPACESHIP_DOCKER_CONTEXT_PREFIX${docker_remote_context}$SPACESHIP_DOCKER_CONTEXT_SUFFIX"
}
spaceship_dotnet () {
	[[ $SPACESHIP_DOTNET_SHOW == false ]] && return
	local is_dotnet_project="$(spaceship::upsearch project.json global.json paket.dependencies)" 
	[[ -n "$is_dotnet_project" || -n *.(cs|fs|x)proj(#qN^/) || -n *.sln(#qN^/) ]] || return
	spaceship::exists dotnet || return
	local dotnet_version
	dotnet_version=$(dotnet --version 2>/dev/null) 
	[[ $? -eq 0 ]] || return
	spaceship::section --color "$SPACESHIP_DOTNET_COLOR" --prefix "$SPACESHIP_DOTNET_PREFIX" --suffix "$SPACESHIP_DOTNET_SUFFIX" --symbol "$SPACESHIP_DOTNET_SYMBOL" "$dotnet_version"
}
spaceship_elixir () {
	[[ $SPACESHIP_ELIXIR_SHOW == false ]] && return
	[[ -f mix.exs || -n *.ex(#qN^/) || -n *.exs(#qN^/) ]] || return
	local elixir_version
	if spaceship::exists kiex
	then
		elixir_version="${ELIXIR_VERSION}" 
	elif spaceship::exists exenv
	then
		elixir_version=$(exenv version-name) 
	elif spaceship::exists asdf
	then
		elixir_version=${$(asdf current elixir)[2]} 
	fi
	if [[ $elixir_version == "" ]]
	then
		spaceship::exists elixir || return
		elixir_version=$(elixir -v 2>/dev/null | spaceship::grep "Elixir" | cut -d ' ' -f 2) 
	fi
	[[ $elixir_version == "system" ]] && return
	[[ $elixir_version == $SPACESHIP_ELIXIR_DEFAULT_VERSION ]] && return
	[[ "${elixir_version}" =~ ^[0-9].+$ ]] && elixir_version="v${elixir_version}" 
	spaceship::section --color "$SPACESHIP_ELIXIR_COLOR" --prefix "$SPACESHIP_ELIXIR_PREFIX" --suffix "$SPACESHIP_ELIXIR_SUFFIX" --symbol "$SPACESHIP_ELIXIR_SYMBOL" "$elixir_version"
}
spaceship_elm () {
	[[ $SPACESHIP_ELM_SHOW == false ]] && return
	local is_elm_project="$(spaceship::upsearch elm.json elm-package.json elm-stuff)" 
	[[ -n "$is_elm_project" || -n *.elm(#qN^/) ]] || return
	spaceship::exists elm || return
	local elm_version=$(elm --version 2> /dev/null) 
	spaceship::section --color "$SPACESHIP_ELM_COLOR" --prefix "$SPACESHIP_ELM_PREFIX" --suffix "$SPACESHIP_ELM_SUFFIX" --symbol "$SPACESHIP_ELM_SYMBOL" "v$elm_version"
}
spaceship_erlang () {
	[[ $SPACESHIP_ERLANG_SHOW == false ]] && return
	spaceship::exists erl || return
	spaceship::upsearch -s rebar.config erlang.mk || return
	local erl_version="$(erl -noshell -eval 'io:fwrite("~s\n", [erlang:system_info(otp_release)]).' -s erlang halt)" 
	spaceship::section --color "$SPACESHIP_ERLANG_COLOR" --prefix "$SPACESHIP_ERLANG_PREFIX" --suffix "$SPACESHIP_ERLANG_SUFFIX" --symbol "$SPACESHIP_ERLANG_SYMBOL" "v$erl_version"
}
spaceship_exec_time () {
	[[ $SPACESHIP_EXEC_TIME_SHOW == false ]] && return
	if (( SPACESHIP_EXEC_TIME_duration >= SPACESHIP_EXEC_TIME_ELAPSED ))
	then
		spaceship::section --color "$SPACESHIP_EXEC_TIME_COLOR" --prefix "$SPACESHIP_EXEC_TIME_PREFIX" --suffix "$SPACESHIP_EXEC_TIME_SUFFIX" "$(spaceship::displaytime $SPACESHIP_EXEC_TIME_duration $SPACESHIP_EXEC_TIME_PRECISION)"
	fi
}
spaceship_exec_time_start () {
	[[ $SPACESHIP_EXEC_TIME_SHOW == false ]] && return
	SPACESHIP_EXEC_TIME_start=$EPOCHREALTIME 
}
spaceship_exec_time_stop () {
	[[ $SPACESHIP_EXEC_TIME_SHOW == false ]] && return
	[[ -n $SPACESHIP_EXEC_TIME_duration ]] && unset SPACESHIP_EXEC_TIME_duration
	[[ -z $SPACESHIP_EXEC_TIME_start ]] && return
	SPACESHIP_EXEC_TIME_duration=$((EPOCHREALTIME - SPACESHIP_EXEC_TIME_start)) 
	unset SPACESHIP_EXEC_TIME_start
}
spaceship_exit_code () {
	[[ $SPACESHIP_EXIT_CODE_SHOW == false || $RETVAL == 0 ]] && return
	spaceship::section --color "$SPACESHIP_EXIT_CODE_COLOR" --prefix "$SPACESHIP_EXIT_CODE_PREFIX" --suffix "$SPACESHIP_EXIT_CODE_SUFFIX" --symbol "$SPACESHIP_EXIT_CODE_SYMBOL" "$RETVAL"
}
spaceship_gcloud () {
	[[ $SPACESHIP_GCLOUD_SHOW == false ]] && return
	spaceship::exists gcloud || return
	local gcloud_dir=${CLOUDSDK_CONFIG:-"${HOME}/.config/gcloud"} 
	[[ -f $gcloud_dir/active_config ]] || return
	if (( ${+CLOUDSDK_ACTIVE_CONFIG_NAME} ))
	then
		local gcloud_active_config=${CLOUDSDK_ACTIVE_CONFIG_NAME} 
	else
		local gcloud_active_config=$(head -n1 $gcloud_dir/active_config) 
	fi
	local gcloud_active_config_file=$gcloud_dir/configurations/config_$gcloud_active_config 
	[[ -f $gcloud_active_config_file ]] || return
	local gcloud_active_project=$(sed -n 's/project = \(.*\)/\1/p' $gcloud_active_config_file) 
	local gcloud_status="$gcloud_active_config/$gcloud_active_project" 
	spaceship::section --color "$SPACESHIP_GCLOUD_COLOR" --prefix "$SPACESHIP_GCLOUD_PREFIX" --suffix "$SPACESHIP_GCLOUD_SUFFIX" --symbol "$SPACESHIP_GCLOUD_SYMBOL" "$gcloud_status"
}
spaceship_git () {
	[[ $SPACESHIP_GIT_SHOW == false ]] && return
	for subsection in "${SPACESHIP_GIT_ORDER[@]}"
	do
		spaceship::core::refresh_section --sync "$subsection"
	done
	local git_branch="$(spaceship::cache::get git_branch)" 
	[[ -z $git_branch ]] && return
	local git_data="$(spaceship::core::compose_order $SPACESHIP_GIT_ORDER)" 
	spaceship::section --color 'white' --prefix "$SPACESHIP_GIT_PREFIX" --suffix "$SPACESHIP_GIT_SUFFIX" "$git_data"
}
spaceship_git_branch () {
	[[ $SPACESHIP_GIT_BRANCH_SHOW == false ]] && return
	vcs_info
	local git_current_branch="$vcs_info_msg_0_" 
	[[ -z "$git_current_branch" ]] && return
	git_current_branch="${git_current_branch#heads/}" 
	git_current_branch="${git_current_branch/.../}" 
	spaceship::section --color "$SPACESHIP_GIT_BRANCH_COLOR" "$SPACESHIP_GIT_BRANCH_PREFIX$git_current_branch$SPACESHIP_GIT_BRANCH_SUFFIX"
}
spaceship_git_commit () {
	[[ $SPACESHIP_GIT_COMMIT_SHOW == false ]] && return
	spaceship::is_git || return
	commit_hash=$(command git rev-parse --short HEAD 2>/dev/null) 
	if [[ -n $commit_hash ]]
	then
		spaceship::section --color "$SPACESHIP_GIT_COMMIT_COLOR" --prefix "$SPACESHIP_GIT_COMMIT_PREFIX" --suffix "$SPACESHIP_GIT_COMMIT_SUFFIX" --symbol "$SPACESHIP_GIT_COMMIT_SYMBOL" "$commit_hash"
	fi
}
spaceship_git_status () {
	[[ $SPACESHIP_GIT_STATUS_SHOW == false ]] && return
	spaceship::is_git || return
	local INDEX git_branch="$vcs_info_msg_0_" git_status="" 
	INDEX=$(command git status --porcelain -b 2> /dev/null) 
	if $(echo "$INDEX" | command grep -E '^\?\? ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_UNTRACKED$git_status" 
	fi
	if $(echo "$INDEX" | command grep '^A[ MDAU] ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_ADDED$git_status" 
	elif $(echo "$INDEX" | command grep '^M[ MD] ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_ADDED$git_status" 
	elif $(echo "$INDEX" | command grep '^UA' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_ADDED$git_status" 
	fi
	if $(echo "$INDEX" | command grep '^[ MARC]M ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_MODIFIED$git_status" 
	fi
	if $(echo "$INDEX" | command grep '^R[ MD] ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_RENAMED$git_status" 
	fi
	if $(echo "$INDEX" | command grep '^[MARCDU ]D ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_DELETED$git_status" 
	elif $(echo "$INDEX" | command grep '^D[ UM] ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_DELETED$git_status" 
	fi
	if $(command git rev-parse --verify refs/stash >/dev/null 2>&1)
	then
		git_status="$SPACESHIP_GIT_STATUS_STASHED$git_status" 
	fi
	if $(echo "$INDEX" | command grep '^U[UDA] ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_UNMERGED$git_status" 
	elif $(echo "$INDEX" | command grep '^AA ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_UNMERGED$git_status" 
	elif $(echo "$INDEX" | command grep '^DD ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_UNMERGED$git_status" 
	elif $(echo "$INDEX" | command grep '^[DA]U ' &> /dev/null)
	then
		git_status="$SPACESHIP_GIT_STATUS_UNMERGED$git_status" 
	fi
	local ahead=$(command git rev-list --count ${git_branch}@{upstream}..HEAD 2>/dev/null) 
	local behind=$(command git rev-list --count HEAD..${git_branch}@{upstream} 2>/dev/null) 
	if (( $ahead )) && (( $behind ))
	then
		git_status="$SPACESHIP_GIT_STATUS_DIVERGED$git_status" 
	elif (( $ahead ))
	then
		git_status="$SPACESHIP_GIT_STATUS_AHEAD$git_status" 
	elif (( $behind ))
	then
		git_status="$SPACESHIP_GIT_STATUS_BEHIND$git_status" 
	fi
	if [[ -n $git_status ]]
	then
		spaceship::section --color "$SPACESHIP_GIT_STATUS_COLOR" "$SPACESHIP_GIT_STATUS_PREFIX$git_status$SPACESHIP_GIT_STATUS_SUFFIX"
	fi
}
spaceship_gnu_screen () {
	[[ $SPACESHIP_GNU_SCREEN_SHOW == false ]] && return
	spaceship::exists screen || return
	[[ "$STY" =~ ^"[0-9]+\." ]] || return
	local screen_session="$STY" 
	spaceship::section --color "$SPACESHIP_GNU_SCREEN_COLOR" --prefix "$SPACESHIP_GNU_SCREEN_PREFIX" --suffix "$SPACESHIP_GNU_SCREEN_SUFFIX" --symbol "$SPACESHIP_GNU_SCREEN_SYMBOL" "$screen_session"
}
spaceship_golang () {
	[[ $SPACESHIP_GOLANG_SHOW == false ]] && return
	local is_go_project="$(spaceship::upsearch go.mod Godeps glide.yaml Gopkg.toml Gopkg.lock)" 
	[[ -n "$is_go_project" || ( -n $GOPATH && "$PWD/" =~ "$GOPATH/" ) || -n *.go(#qN^/) ]] || return
	spaceship::exists go || return
	local go_version=$(go version | awk '{ if ($3 ~ /^devel/) {print $3 ":" substr($4, 2)} else {print "v" substr($3, 3)} }') 
	spaceship::section --color "$SPACESHIP_GOLANG_COLOR" --prefix "$SPACESHIP_GOLANG_PREFIX" --suffix "$SPACESHIP_GOLANG_SUFFIX" --symbol "$SPACESHIP_GOLANG_SYMBOL" "$go_version"
}
spaceship_haskell () {
	[[ $SPACESHIP_HASKELL_SHOW == false ]] && return
	local is_haskell_project=$(spaceship::upsearch stack.yaml) 
	[[ -n "$is_haskell_project" || -n *.hs(#qN^/) || -n *.cabal(#qN) ]] || return
	local haskell_version
	if spaceship::exists cabal
	then
		haskell_version=$(ghc -- --numeric-version --no-install-ghc) 
	elif spaceship::exists stack
	then
		haskell_version=$(stack ghc -- --numeric-version --no-install-ghc) 
	else
		return
	fi
	spaceship::section --color "$SPACESHIP_HASKELL_COLOR" --prefix "$SPACESHIP_HASKELL_PREFIX" --suffix "$SPACESHIP_HASKELL_SUFFIX" --symbol "$SPACESHIP_HASKELL_SYMBOL" "v$haskell_version"
}
spaceship_hg () {
	[[ $SPACESHIP_HG_SHOW == false ]] && return
	for subsection in "${SPACESHIP_HG_ORDER[@]}"
	do
		spaceship::core::refresh_section --sync "$subsection"
	done
	local hg_branch="$(spaceship::cache::get hg_branch)" 
	[[ -z $hg_branch ]] && return
	local hg_data="$(spaceship::core::compose_order $SPACESHIP_HG_ORDER)" 
	spaceship::section --color 'white' --prefix "$SPACESHIP_HG_PREFIX" --suffix "$SPACESHIP_HG_SUFFIX" "$hg_data"
}
spaceship_hg_branch () {
	[[ $SPACESHIP_HG_BRANCH_SHOW == false ]] && return
	spaceship::is_hg || return
	local hg_info=$(hg log -r . --template '{activebookmark}') 
	if [[ -z $hg_info ]]
	then
		hg_info=$(hg branch) 
	fi
	spaceship::section --color "$SPACESHIP_HG_BRANCH_COLOR" "$SPACESHIP_HG_BRANCH_PREFIX$hg_info$SPACESHIP_HG_BRANCH_SUFFIX"
}
spaceship_hg_status () {
	[[ $SPACESHIP_HG_STATUS_SHOW == false ]] && return
	spaceship::is_hg || return
	local INDEX=$(hg status 2>/dev/null) hg_status="" 
	if $(echo "$INDEX" | grep -E '^\? ' &> /dev/null)
	then
		hg_status="$SPACESHIP_HG_STATUS_UNTRACKED$hg_status" 
	fi
	if $(echo "$INDEX" | grep -E '^A ' &> /dev/null)
	then
		hg_status="$SPACESHIP_HG_STATUS_ADDED$hg_status" 
	fi
	if $(echo "$INDEX" | grep -E '^M ' &> /dev/null)
	then
		hg_status="$SPACESHIP_HG_STATUS_MODIFIED$hg_status" 
	fi
	if $(echo "$INDEX" | grep -E '^(R|!)' &> /dev/null)
	then
		hg_status="$SPACESHIP_HG_STATUS_DELETED$hg_status" 
	fi
	if [[ -n $hg_status ]]
	then
		spaceship::section --color "$SPACESHIP_HG_STATUS_COLOR" "$SPACESHIP_HG_STATUS_PREFIX$hg_status$SPACESHIP_HG_STATUS_SUFFIX"
	fi
}
spaceship_host () {
	[[ $SPACESHIP_HOST_SHOW == false ]] && return
	if [[ $SPACESHIP_HOST_SHOW == 'always' ]] || [[ -n $SSH_CONNECTION ]]
	then
		local host_color host
		if [[ -n $SSH_CONNECTION ]]
		then
			host_color=$SPACESHIP_HOST_COLOR_SSH 
		else
			host_color=$SPACESHIP_HOST_COLOR 
		fi
		if [[ $SPACESHIP_HOST_SHOW_FULL == true ]]
		then
			host="%M" 
		else
			host="%m" 
		fi
		spaceship::section --color "$host_color" --prefix "$SPACESHIP_HOST_PREFIX" --suffix "$SPACESHIP_HOST_SUFFIX" "$host"
	fi
}
spaceship_ibmcloud () {
	[[ $SPACESHIP_IBMCLOUD_SHOW == false ]] && return
	spaceship::exists ibmcloud || return
	local ibmcloud_account=$(ibmcloud target | grep Account | awk '{print $2}') 
	[[ -z $ibmcloud_account ]] && return
	[[ "No" == $ibmcloud_account ]] && ibmcloud_account="No account targeted" 
	spaceship::section --color "$SPACESHIP_IBMCLOUD_COLOR" --prefix "$SPACESHIP_IBMCLOUD_PREFIX" --suffix "$SPACESHIP_IBMCLOUD_SUFFIX" --symbol "$SPACESHIP_IBMCLOUD_SYMBOL" "$ibmcloud_account"
}
spaceship_java () {
	[[ $SPACESHIP_JAVA_SHOW == false ]] && return
	spaceship::exists java || return
	local java_project_globs=('pom.xml' 'build.gradle*' 'settings.gradle*' 'build.xml') 
	local is_java_project="$(spaceship::upsearch $java_project_globs)" 
	[[ -n "$is_java_project" || -n *.(java|class|jar|war)(#qN^/) ]] || return
	local java_version=$(java -version 2>&1 | spaceship::grep version | awk -F '"' '{print $2}') 
	[[ -z "$java_version" ]] && return
	spaceship::section --color "$SPACESHIP_JAVA_COLOR" --prefix "$SPACESHIP_JAVA_PREFIX" --suffix "$SPACESHIP_JAVA_SUFFIX" --symbol "$SPACESHIP_JAVA_SYMBOL" "v${java_version}"
}
spaceship_jobs () {
	[[ $SPACESHIP_JOBS_SHOW == false ]] && return
	local jobs_amount=${#jobstates} 
	[[ $jobs_amount -gt 0 ]] || return
	if [[ $jobs_amount -le $SPACESHIP_JOBS_AMOUNT_THRESHOLD ]]
	then
		jobs_amount='' 
		SPACESHIP_JOBS_AMOUNT_PREFIX='' 
		SPACESHIP_JOBS_AMOUNT_SUFFIX='' 
	fi
	spaceship::section --color "$SPACESHIP_JOBS_COLOR" --prefix "$SPACESHIP_JOBS_PREFIX" --suffix "$SPACESHIP_JOBS_SUFFIX" --symbol "$SPACESHIP_JOBS_SYMBOL" "$SPACESHIP_JOBS_AMOUNT_PREFIX$jobs_amount$SPACESHIP_JOBS_AMOUNT_SUFFIX"
}
spaceship_julia () {
	[[ $SPACESHIP_JULIA_SHOW == false ]] && return
	local is_julia_project="$(spaceship::upsearch Project.toml JuliaProject.toml Manifest.toml)" 
	[[ -n "$is_julia_project" || -n *.jl(#qN^/) ]] || return
	spaceship::exists julia || return
	local julia_version=$(julia --version | spaceship::grep -oE '([0-9]+\.)([0-9]+\.)?([0-9]+)') 
	spaceship::section --color "$SPACESHIP_JULIA_COLOR" --prefix "$SPACESHIP_JULIA_PREFIX" --suffix "$SPACESHIP_JULIA_SUFFIX" --symbol "$SPACESHIP_JULIA_SYMBOL" "$julia_version"
}
spaceship_kotlin () {
	[[ $SPACESHIP_KOTLIN_SHOW == false ]] && return
	spaceship::exists kotlinc || return
	[[ -n *.kt(#qN^/) || -n *.kts(#qN^/) ]] || return
	local kotlin_version=$(kotlinc -version 2>&1 | spaceship::grep -oE '([0-9]+\.)([0-9]+\.)?([0-9]+)' | head -n 1) 
	[[ -z "$kotlin_version" ]] && return
	spaceship::section --color "$SPACESHIP_KOTLIN_COLOR" --prefix "$SPACESHIP_KOTLIN_PREFIX" --suffix "$SPACESHIP_KOTLIN_SUFFIX" --symbol "$SPACESHIP_KOTLIN_SYMBOL" "v$kotlin_version"
}
spaceship_kubectl () {
	[[ $SPACESHIP_KUBECTL_SHOW == false ]] && return
	local kubectl_version="$(spaceship_kubectl_version)" 
	local kubectl_context="$(spaceship_kubectl_context)" 
	[[ -z $kubectl_version && -z $kubectl_context ]] && return
	local kubectl_version_section="$(spaceship::section::render $kubectl_version)" 
	local kubectl_context_section="$(spaceship::section::render $kubectl_context)" 
	spaceship::section --color "$SPACESHIP_KUBECTL_COLOR" --prefix "$SPACESHIP_KUBECTL_PREFIX" --suffix "$SPACESHIP_KUBECTL_SUFFIX" --symbol "$SPACESHIP_KUBECTL_SYMBOL" "${kubectl_version_section}${kubectl_context_section}"
}
spaceship_kubectl_context () {
	[[ $SPACESHIP_KUBECTL_CONTEXT_SHOW == false ]] && return
	spaceship::exists kubectl || return
	local kube_context=$(kubectl config current-context 2>/dev/null) 
	[[ -z $kube_context ]] && return
	if [[ $SPACESHIP_KUBECTL_CONTEXT_SHOW_NAMESPACE == true ]]
	then
		local kube_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null) 
		[[ -n $kube_namespace && "$kube_namespace" != "default" ]] && kube_context="$kube_context ($kube_namespace)" 
	fi
	local len=${#SPACESHIP_KUBECTL_CONTEXT_COLOR_GROUPS[@]} 
	local it_to=$((len / 2)) 
	local section_color 'i'
	for ((i = 1; i <= $it_to; i++)) do
		local idx=$(((i - 1) * 2)) 
		local color="${SPACESHIP_KUBECTL_CONTEXT_COLOR_GROUPS[$idx + 1]}" 
		local pattern="${SPACESHIP_KUBECTL_CONTEXT_COLOR_GROUPS[$idx + 2]}" 
		if [[ "$kube_context" =~ "$pattern" ]]
		then
			section_color=$color 
			break
		fi
	done
	[[ -z "$section_color" ]] && section_color=$SPACESHIP_KUBECTL_CONTEXT_COLOR 
	spaceship::section --color "$section_color" --prefix "$SPACESHIP_KUBECTL_CONTEXT_PREFIX" --suffix "$SPACESHIP_KUBECTL_CONTEXT_SUFFIX" "$kube_context"
}
spaceship_kubectl_version () {
	[[ $SPACESHIP_KUBECTL_VERSION_SHOW == false ]] && return
	spaceship::exists kubectl || return
	local kube_context=$(kubectl config current-context 2>/dev/null) 
	[[ -z $kube_context ]] && return
	local kubectl_version=$(kubectl version 2>/dev/null | grep "Server Version" | sed 's/Server Version: \(.*\)/\1/') 
	[[ -z $kubectl_version ]] && return
	spaceship::section --color "$SPACESHIP_KUBECTL_VERSION_COLOR" --prefix "$SPACESHIP_KUBECTL_VERSION_PREFIX" --suffix "$SPACESHIP_KUBECTL_VERSION_SUFFIX" "$kubectl_version"
}
spaceship_line_sep () {
	[[ $SPACESHIP_PROMPT_SEPARATE_LINE != true ]] && return
	spaceship::section --color 'white' "\n"
}
spaceship_lua () {
	[[ $SPACESHIP_LUA_SHOW == false ]] && return
	spaceship::exists lua || return
	local is_lua_project="$(spaceship::upsearch .lua-version lua)" 
	[[ -n "$is_lua_project" || -n *.lua(#qN^/) ]] || return
	local lua_version=$(lua -v | awk '{print $2}') 
	spaceship::section --color "$SPACESHIP_LUA_COLOR" --prefix "$SPACESHIP_LUA_PREFIX" --suffix "$SPACESHIP_LUA_SUFFIX" --symbol "${SPACESHIP_LUA_SYMBOL}" "v${lua_version}"
}
spaceship_nix_shell () {
	[[ $SPACESHIP_NIX_SHELL_SHOW == false ]] && return
	[[ -z "$IN_NIX_SHELL" ]] && return
	if [[ -z "$name" || "$name" == "" ]]
	then
		display_text="$IN_NIX_SHELL" 
	else
		display_text="$IN_NIX_SHELL ($name)" 
	fi
	spaceship::section --color "$SPACESHIP_NIX_SHELL_COLOR" --prefix "$SPACESHIP_NIX_SHELL_PREFIX" --suffix "$SPACESHIP_NIX_SHELL_SUFFIX" --symbol "$SPACESHIP_NIX_SHELL_SYMBOL" "$display_text"
}
spaceship_node () {
	[[ $SPACESHIP_NODE_SHOW == false ]] && return
	local is_node_project="$(spaceship::upsearch package.json .nvmrc .node-version node_modules)" 
	[[ -n "$is_node_project" || -n *.js(#qN^/) || -n *.cjs(#qN^/) || -n *.mjs(#qN^/) ]] || return
	local node_version
	if spaceship::exists fnm
	then
		node_version=$(fnm current 2>/dev/null) 
	elif spaceship::exists nvm
	then
		node_version=$(nvm current 2>/dev/null) 
	elif spaceship::exists nodenv
	then
		node_version=$(nodenv version-name) 
	elif spaceship::exists node
	then
		node_version=$(node -v 2>/dev/null) 
	else
		return
	fi
	[[ $node_version == "system" || $node_version == "node" ]] && return
	[[ $node_version == $SPACESHIP_NODE_DEFAULT_VERSION ]] && return
	spaceship::section --color "$SPACESHIP_NODE_COLOR" --prefix "$SPACESHIP_NODE_PREFIX" --suffix "$SPACESHIP_NODE_SUFFIX" --symbol "$SPACESHIP_NODE_SYMBOL" "$node_version"
}
spaceship_ocaml () {
	[[ $SPACESHIP_OCAML_SHOW == false ]] && return
	local is_ocaml_project="$(spaceship::upsearch esy.lock _opam dune dune-project jbuild jbuild-ignore .merlin)" 
	[[ -n "$is_ocaml_project" || -n *.opam(#qN^/) || -n *.{ml,mli,re,rei}(#qN^/) ]] || return
	local ocaml_version
	if spaceship::exists esy && $(esy true 2>/dev/null)
	then
		ocaml_version=$(esy ocaml -vnum 2>/dev/null) 
	elif spaceship::exists opam
	then
		ocaml_version=$(opam switch show 2>/dev/null) 
	elif spaceship::exists ocaml
	then
		ocaml_version=$(ocaml -vnum) 
	else
		return
	fi
	[[ -z "$ocaml_version" || "$ocaml_version" == "system" ]] && return
	[[ "$ocaml_version" =~ ^[0-9].+$ ]] && ocaml_version="v$ocaml_version" 
	spaceship::section --color "$SPACESHIP_OCAML_COLOR" --prefix "$SPACESHIP_OCAML_PREFIX" --suffix "$SPACESHIP_OCAML_SUFFIX" --symbol "$SPACESHIP_OCAML_SYMBOL" "$ocaml_version"
}
spaceship_package () {
	[[ $SPACESHIP_PACKAGE_SHOW == false ]] && return
	local package_version
	for manager in "${SPACESHIP_PACKAGE_ORDER[@]}"
	do
		package_version="$(spaceship_package::$manager)" 
		if [[ -z $package_version || "$package_version" == "null" || "$package_version" == "undefined" ]]
		then
			continue
		fi
		spaceship::section --color "$SPACESHIP_PACKAGE_COLOR" --prefix "$SPACESHIP_PACKAGE_PREFIX" --suffix "$SPACESHIP_PACKAGE_SUFFIX" --symbol "$SPACESHIP_PACKAGE_SYMBOL" "$package_version"
		return
	done
}
spaceship_package::cargo () {
	spaceship::exists cargo || return
	spaceship::upsearch -s Cargo.toml || return
	local pkgid=$(cargo pkgid 2>&1) 
	echo "$pkgid" | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox} -q "error:" && return
	echo "${pkgid##*\#}"
}
spaceship_package::composer () {
	spaceship::exists composer || return
	local composer_json=$(spaceship::upsearch composer.json)  || return
	spaceship::extract --json $composer_json "version"
}
spaceship_package::dart () {
	spaceship::exists dart || return
	local pubspec_file=$(spaceship::upsearch pubspec.yaml pubspec.yml)  || return
	spaceship::extract --yaml $pubspec_file "version"
}
spaceship_package::gradle () {
	spaceship::upsearch -s settings.gradle settings.gradle.kts || return
	local gradle_exe=$(spaceship::upsearch gradlew)  || (
		spaceship::exists gradle && gradle_exe="gradle" 
	) || return
	$gradle_exe properties --no-daemon --console=plain -q 2> /dev/null | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox} "^version:" | awk '{printf $2}'
}
spaceship_package::julia () {
	spaceship::exists julia || return
	local project_toml=$(spaceship::upsearch Project.toml)  || return
	spaceship::extract --toml $project_toml "version"
}
spaceship_package::lerna () {
	spaceship::exists npm || return
	local lerna_json=$(spaceship::upsearch lerna.json)  || return
	local package_version="$(spaceship::extract --json $lerna_json version)" 
	if [[ "$package_version" == "independent" ]]
	then
		package_version="($package_version)" 
	fi
	echo "$package_version"
}
spaceship_package::maven () {
	spaceship::upsearch -s pom.xml || return
	local maven_exe=$(spaceship::upsearch mvnw) 
	if [[ -z $maven_exe ]] && spaceship::exists mvn
	then
		maven_exe="mvn" 
	fi
	[[ -z $maven_exe ]] && return
	local version
	version=$($maven_exe help:evaluate -q -DforceStdout -Dexpression=project.version 2>/dev/null) 
	[[ $? != 0 ]] && return
	echo "${version}"
}
spaceship_package::npm () {
	spaceship::exists npm || return
	local package_json=$(spaceship::upsearch package.json)  || return
	local package_version="$(spaceship::extract --json $package_json version)" 
	local is_private_package="$(spaceship::extract --json $package_json private)" 
	if [[ "$SPACESHIP_PACKAGE_SHOW_PRIVATE" == false && "$is_private_package" == true ]]
	then
		return 0
	fi
	if [[ "$package_version" == '0.0.0-development' || $package_version == '0.0.0-semantic'* ]]
	then
		package_version="(semantic)" 
	fi
	echo "$package_version"
}
spaceship_package::python () {
	local pyproject_toml=$(spaceship::upsearch pyproject.toml)  || return
	spaceship::extract --toml "$pyproject_toml" "project.version" "tool.poetry.version"
}
spaceship_perl () {
	[[ $SPACESHIP_PERL_SHOW == false ]] && return
	spaceship::exists perl || return
	local is_perl_project="$(spaceship::upsearch META.{json,yml,yaml} .perl-version cpanfile)" 
	[[ -n "$is_perl_project" || -n *.pl(#qN^/) || -n *.pm(#qN^/) ]] || return
	local perl_version=$(perl -v 2>&1 | awk '/This/ {print $9}' | sed -r 's/[(v]+//g;s/[)]//g') 
	spaceship::section --color "$SPACESHIP_PERL_COLOR" --prefix "$SPACESHIP_PERL_PREFIX" --suffix "$SPACESHIP_PERL_SUFFIX" --symbol "$SPACESHIP_PERL_SYMBOL" "v$perl_version"
}
spaceship_php () {
	[[ $SPACESHIP_PHP_SHOW == false ]] && return
	local is_php_project="$(spaceship::upsearch composer.json)" 
	[[ -n "$is_php_project" || -n *.php(#qN^/) ]] || return
	spaceship::exists php || return
	local php_version=$(php -v 2>&1 | spaceship::grep -oe "^PHP\s*[0-9.]\+" | awk '{print $2}') 
	spaceship::section --color "$SPACESHIP_PHP_COLOR" --prefix "$SPACESHIP_PHP_PREFIX" --suffix "${SPACESHIP_PHP_SUFFIX}" --symbol "${SPACESHIP_PHP_SYMBOL}" "v${php_version}"
}
spaceship_pulumi () {
	[[ $SPACESHIP_PULUMI_SHOW == false ]] && return
	spaceship::exists pulumi || return
	local pulumi_project="$(spaceship::upsearch Pulumi.yml Pulumi.yaml)" 
	[[ -n "$pulumi_project" || -d .pulumi/stacks ]] || return
	local pulumi_stack=$(pulumi stack ls 2>/dev/null | sed -n -e '/\x2A/p' | cut -f1 -d" " | sed s/\*//) 
	[[ -z $pulumi_stack ]] && return
	spaceship::section --color "$SPACESHIP_PULUMI_COLOR" --prefix "$SPACESHIP_PULUMI_PREFIX" --suffix "$SPACESHIP_PULUMI_SUFFIX" --symbol "$SPACESHIP_PULUMI_SYMBOL" "$pulumi_stack"
}
spaceship_purescript () {
	[[ $SPACESHIP_PURESCRIPR_SHOW == false ]] && return
	spaceship::exists purescript || return
	local is_purescript_context="$(spaceship::upsearch spago.dhall)" 
	[[ -n "$is_purescript_context" || -n *.purs(#qN^/) ]] || return
	local purescript_version="$(purescript --version)" 
	spaceship::section --color "$SPACESHIP_PURESCRIPT_COLOR" --prefix "$SPACESHIP_PURESCRIPT_PREFIX" --suffix "$SPACESHIP_PURESCRIPT_SUFFIX" --symbol "$SPACESHIP_PURESCRIPT_SYMBOL" "v$purescript_version"
}
spaceship_python () {
	[[ $SPACESHIP_PYTHON_SHOW == false ]] && return
	local is_python_project="$(spaceship::upsearch requirements.txt Pipfile pyproject.toml)" 
	[[ -n "$is_python_project" || -n *.py(#qN^/) ]] || return
	local py_version
	if [[ -n "$VIRTUAL_ENV" ]] || [[ $SPACESHIP_PYTHON_SHOW == always ]]
	then
		py_version=${(@)$(python -V 2>&1)[2]} 
	fi
	[[ -z $py_version ]] && return
	spaceship::section --color "$SPACESHIP_PYTHON_COLOR" --prefix "$SPACESHIP_PYTHON_PREFIX" --suffix "$SPACESHIP_PYTHON_SUFFIX" --symbol "$SPACESHIP_PYTHON_SYMBOL" "$py_version"
}
spaceship_red () {
	[[ $SPACESHIP_RED_SHOW == false ]] && return
	local is_red_project="$(spaceship::upsearch red.rc redbol)" 
	[[ -n "$is_red_project" || -n *.red(#qN^/) || -n *.reds(#qN^/) ]] || return
	local red_version
	if [[ -n "$VIRTUAL_ENV" ]] || [[ $SPACESHIP_RED_SHOW == always ]]
	then
		red_version=${(@)$(red --version 2>&1)[2]} 
	fi
	[[ -z $red_version ]] && return
	spaceship::section --color "$SPACESHIP_RED_COLOR" --prefix "$SPACESHIP_RED_PREFIX" --suffix "$SPACESHIP_RED_SUFFIX" --symbol "$SPACESHIP_RED_SYMBOL" "$red_version"
}
spaceship_ruby () {
	[[ $SPACESHIP_RUBY_SHOW == false ]] && return
	local is_ruby_project="$(spaceship::upsearch Gemfile Rakefile)" 
	[[ -n "$is_ruby_project" || -n *.rb(#qN^/) ]] || return
	local ruby_version
	if spaceship::exists rvm-prompt
	then
		ruby_version=$(rvm-prompt i v g) 
	elif spaceship::exists chruby
	then
		ruby_version=$(chruby | sed -n -e 's/ \* //p') 
	elif spaceship::exists rbenv
	then
		ruby_version=$(rbenv version-name) 
	elif spaceship::exists asdf
	then
		ruby_version=${$(asdf current ruby)[2]} 
	else
		return
	fi
	[[ -z $ruby_version || "${ruby_version}" == "system" ]] && return
	[[ "${ruby_version}" =~ ^[0-9].+$ ]] && ruby_version="v${ruby_version}" 
	spaceship::section --color "$SPACESHIP_RUBY_COLOR" --prefix "$SPACESHIP_RUBY_PREFIX" --suffix "$SPACESHIP_RUBY_SUFFIX" --symbol "$SPACESHIP_RUBY_SYMBOL" "$ruby_version"
}
spaceship_rust () {
	[[ $SPACESHIP_RUST_SHOW == false ]] && return
	local is_rust_project="$(spaceship::upsearch Cargo.toml)" 
	[[ -n "$is_rust_project" || -n *.rs(#qN^/) ]] || return
	spaceship::exists rustc || return
	local rust_version=$(rustc --version | cut -d' ' -f2) 
	if [[ $SPACESHIP_RUST_VERBOSE_VERSION == false ]]
	then
		local rust_version=$(echo $rust_version | cut -d'-' -f1) 
	fi
	spaceship::section --color "$SPACESHIP_RUST_COLOR" --prefix "$SPACESHIP_RUST_PREFIX" --suffix "$SPACESHIP_RUST_SUFFIX" --symbol "$SPACESHIP_RUST_SYMBOL" "$rust_version"
}
spaceship_scala () {
	[[ $SPACESHIP_SCALA_SHOW == false ]] && return
	spaceship::exists scalac || return
	local is_scala_context="$(spaceship::upsearch .scalaenv .sbtenv .metals)" 
	[[ -n "$is_scala_context" || -n *.scala(#qN^/) || -n *.sbt(#qN^/) ]] || return
	local scala_version=$(scalac -version 2>&1 | spaceship::grep -Eo "[0-9]+\.[0-9]+\.[0-9]+") 
	[[ -z "$scala_version" || "${scala_version}" == "system" ]] && return
	spaceship::section::v4 --color "$SPACESHIP_SCALA_COLOR" --prefix "$SPACESHIP_SCALA_PREFIX" --suffix "$SPACESHIP_SCALA_SUFFIX" --symbol "$SPACESHIP_SCALA_SYMBOL" "v$scala_version"
}
spaceship_sudo () {
	[[ $SPACESHIP_SUDO_SHOW == false ]] && return
	spaceship::exists sudo || return
	if ! sudo -n true > /dev/null 2>&1
	then
		return
	fi
	spaceship::section --color "$SPACESHIP_SUDO_COLOR" --prefix "$SPACESHIP_SUDO_PREFIX" --suffix "$SPACESHIP_SUDO_SUFFIX" --symbol "$SPACESHIP_SUDO_SYMBOL"
}
spaceship_swift () {
	spaceship::exists swiftenv || return
	local swift_version
	if [[ $SPACESHIP_SWIFT_SHOW_GLOBAL == true ]]
	then
		swift_version=$(swiftenv version | sed 's/ .*//') 
	elif [[ $SPACESHIP_SWIFT_SHOW_LOCAL == true ]]
	then
		if swiftenv version | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox} ".swift-version" > /dev/null
		then
			swift_version=$(swiftenv version | sed 's/ .*//') 
		fi
	fi
	[ -n "${swift_version}" ] || return
	spaceship::section --color "$SPACESHIP_SWIFT_COLOR" --prefix "$SPACESHIP_SWIFT_PREFIX" --suffix "$SPACESHIP_SWIFT_SUFFIX" --symbol "$SPACESHIP_SWIFT_SYMBOL" "$swift_version"
}
spaceship_terraform () {
	[[ $SPACESHIP_TERRAFORM_SHOW == false ]] && return
	spaceship::exists terraform || return
	spaceship::upsearch .terraform/environment || return
	local terraform_workspace=$(<.terraform/environment) 
	[[ -z $terraform_workspace ]] && return
	spaceship::section --color "$SPACESHIP_TERRAFORM_COLOR" --prefix "$SPACESHIP_TERRAFORM_PREFIX" --suffix "$SPACESHIP_TERRAFORM_SUFFIX" --symbol "$SPACESHIP_TERRAFORM_SYMBOL" "$terraform_workspace"
}
spaceship_time () {
	[[ $SPACESHIP_TIME_SHOW == false ]] && return
	local time_str
	if [[ -n $SPACESHIP_TIME_FORMAT ]]
	then
		time_str="${SPACESHIP_TIME_FORMAT}" 
	elif [[ $SPACESHIP_TIME_12HR == true ]]
	then
		time_str="%D{%r}" 
	else
		time_str="%D{%T}" 
	fi
	spaceship::section --color "$SPACESHIP_TIME_COLOR" --prefix "$SPACESHIP_TIME_PREFIX" --suffix "$SPACESHIP_TIME_SUFFIX" "$time_str"
}
spaceship_user () {
	[[ $SPACESHIP_USER_SHOW == false ]] && return
	if [[ $SPACESHIP_USER_SHOW == 'always' ]] || [[ $LOGNAME != $USER ]] || [[ $UID == 0 ]] || [[ $SPACESHIP_USER_SHOW == true && -n $SSH_CONNECTION ]]
	then
		local user_color
		if [[ $USER == 'root' ]]
		then
			user_color=$SPACESHIP_USER_COLOR_ROOT 
		else
			user_color="$SPACESHIP_USER_COLOR" 
		fi
		spaceship::section --color "$user_color" --prefix "$SPACESHIP_USER_PREFIX" --suffix "$SPACESHIP_USER_SUFFIX" '%n'
	fi
}
spaceship_venv () {
	[[ $SPACESHIP_VENV_SHOW == false ]] && return
	[ -n "$VIRTUAL_ENV" ] || return
	local venv
	if [[ "${SPACESHIP_VENV_GENERIC_NAMES[(i)$VIRTUAL_ENV:t]}" -le "${#SPACESHIP_VENV_GENERIC_NAMES}" ]]
	then
		venv="$VIRTUAL_ENV:h:t" 
	else
		venv="$VIRTUAL_ENV:t" 
	fi
	spaceship::section --color "$SPACESHIP_VENV_COLOR" --prefix "$SPACESHIP_VENV_PREFIX" --suffix "$SPACESHIP_VENV_SUFFIX" --symbol "$SPACESHIP_VENV_SYMBOL" "$venv"
}
spaceship_vlang () {
	[[ $SPACESHIP_VLANG_SHOW == false ]] && return
	local is_v_project=$(spaceship::upsearch v.mod vpkg.json .vpkg-lock.json) 
	[[ -n "$is_v_project" || -n *.v(#qN^/) ]] || return
	local v_version
	if spaceship::exists v
	then
		v_version=$(v version | cut -d' ' -f2) 
	fi
	[[ -z "$v_version" ]] && return
	spaceship::section --color "$SPACESHIP_VLANG_COLOR" --prefix "$SPACESHIP_VLANG_PREFIX" --suffix "$SPACESHIP_VLANG_SUFFIX" --symbol "$SPACESHIP_VLANG_SYMBOL" "v$v_version"
}
spaceship_xcode () {
	spaceship::exists xcenv || return
	local xcode_path
	if [[ $SPACESHIP_XCODE_SHOW_GLOBAL == true ]]
	then
		xcode_path=$(xcenv version | sed 's/ .*//') 
	elif [[ $SPACESHIP_XCODE_SHOW_LOCAL == true ]]
	then
		if xcenv version | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox} ".xcode-version" > /dev/null
		then
			xcode_path=$(xcenv version | sed 's/ .*//') 
		fi
	fi
	if [ -n "${xcode_path}" ]
	then
		local xcode_version_path=$xcode_path"/Contents/version.plist" 
		if [ -f ${xcode_version_path} ]
		then
			if spaceship::exists defaults
			then
				local xcode_version=$(defaults read ${xcode_version_path} CFBundleShortVersionString) 
				spaceship::section --color "$SPACESHIP_XCODE_COLOR" --prefix "$SPACESHIP_XCODE_PREFIX" --suffix "$SPACESHIP_XCODE_SUFFIX" --symbol "$SPACESHIP_XCODE_SYMBOL" "$xcode_version"
			fi
		fi
	fi
}
spaceship_zig () {
	[[ $SPACESHIP_ZIG_SHOW == false ]] && return
	spaceship::exists zig || return
	local is_zig_context="$(spaceship::upsearch build.zig)" 
	[[ -n "$is_zig_context" || -n *.zig(#qN^/) ]] || return
	local zig_version="$(zig version)" 
	spaceship::section --color "$SPACESHIP_ZIG_COLOR" --prefix "$SPACESHIP_ZIG_PREFIX" --suffix "$SPACESHIP_ZIG_SUFFIX" --symbol "$SPACESHIP_ZIG_SYMBOL" "v$zig_version"
}
spectrum_bls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${BG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
spectrum_ls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
svn_prompt_info () {
	return 1
}
take () {
	if [[ $1 =~ ^(https?|ftp).*\.(tar\.(gz|bz2|xz)|tgz)$ ]]
	then
		takeurl "$1"
	elif [[ $1 =~ ^(https?|ftp).*\.(zip)$ ]]
	then
		takezip "$1"
	elif [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]
	then
		takegit "$1"
	else
		takedir "$@"
	fi
}
takedir () {
	mkdir -p $@ && cd ${@:$#}
}
takegit () {
	git clone "$1"
	cd "$(basename ${1%%.git})"
}
takeurl () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	tar xf "$data"
	thedir="$(tar tf "$data" | head -n 1)" 
	rm "$data"
	cd "$thedir"
}
takezip () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	unzip "$data" -d "./"
	thedir="$(unzip -l "$data" | awk 'NR==4 {print $4}' | sed 's/\/.*//')" 
	rm "$data"
	cd "$thedir"
}
tf_prompt_info () {
	return 1
}
title () {
	setopt localoptions nopromptsubst
	[[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != vterm ]] && return
	: ${2=$1}
	case "$TERM" in
		(cygwin | xterm* | putty* | rxvt* | konsole* | ansi | mlterm* | alacritty* | st* | foot* | contour* | wezterm*) print -Pn "\e]2;${2:q}\a"
			print -Pn "\e]1;${1:q}\a" ;;
		(screen* | tmux*) print -Pn "\ek${1:q}\e\\" ;;
		(*) if [[ "$TERM_PROGRAM" == "iTerm.app" ]]
			then
				print -Pn "\e]2;${2:q}\a"
				print -Pn "\e]1;${1:q}\a"
			else
				if (( ${+terminfo[fsl]} && ${+terminfo[tsl]} ))
				then
					print -Pn "${terminfo[tsl]}$1${terminfo[fsl]}"
				fi
			fi ;;
	esac
}
try_alias_value () {
	alias_value "$1" || echo "$1"
}
uninstall_oh_my_zsh () {
	command env ZSH="$ZSH" sh "$ZSH/tools/uninstall.sh"
}
up-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
upgrade_oh_my_zsh () {
	echo "${fg[yellow]}Note: \`$0\` is deprecated. Use \`omz update\` instead.$reset_color" >&2
	omz update
}
url-quote-magic () {
	# undefined
	builtin autoload -XUz
}
vcs_info () {
	# undefined
	builtin autoload -XUz
}
vi_mode_prompt_info () {
	return 1
}
virtualenv_prompt_info () {
	return 1
}
work_in_progress () {
	command git -c log.showSignature=false log -n 1 2> /dev/null | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -q -- "--wip--" && echo "WIP!!"
}
zle-line-finish () {
	echoti rmkx
}
zle-line-init () {
	echoti smkx
}
zrecompile () {
	setopt localoptions extendedglob noshwordsplit noksharrays
	local opt check quiet zwc files re file pre ret map tmp mesg pats
	tmp=() 
	while getopts ":tqp" opt
	do
		case $opt in
			(t) check=yes  ;;
			(q) quiet=yes  ;;
			(p) pats=yes  ;;
			(*) if [[ -n $pats ]]
				then
					tmp=($tmp $OPTARG) 
				else
					print -u2 zrecompile: bad option: -$OPTARG
					return 1
				fi ;;
		esac
	done
	shift OPTIND-${#tmp}-1
	if [[ -n $check ]]
	then
		ret=1 
	else
		ret=0 
	fi
	if [[ -n $pats ]]
	then
		local end num
		while (( $# ))
		do
			end=$argv[(i)--] 
			if [[ end -le $# ]]
			then
				files=($argv[1,end-1]) 
				shift end
			else
				files=($argv) 
				argv=() 
			fi
			tmp=() 
			map=() 
			OPTIND=1 
			while getopts :MR opt $files
			do
				case $opt in
					([MR]) map=(-$opt)  ;;
					(*) tmp=($tmp $files[OPTIND])  ;;
				esac
			done
			shift OPTIND-1 files
			(( $#files )) || continue
			files=($files[1] ${files[2,-1]:#*(.zwc|~)}) 
			(( $#files )) || continue
			zwc=${files[1]%.zwc}.zwc 
			shift 1 files
			(( $#files )) || files=(${zwc%.zwc}) 
			if [[ -f $zwc ]]
			then
				num=$(zcompile -t $zwc | wc -l) 
				if [[ num-1 -ne $#files ]]
				then
					re=yes 
				else
					re= 
					for file in $files
					do
						if [[ $file -nt $zwc ]]
						then
							re=yes 
							break
						fi
					done
				fi
			else
				re=yes 
			fi
			if [[ -n $re ]]
			then
				if [[ -n $check ]]
				then
					[[ -z $quiet ]] && print $zwc needs re-compilation
					ret=0 
				else
					[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
					if [[ -z "$quiet" ]] && {
							[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
						} && zcompile $map $tmp $zwc $files
					then
						print succeeded
					elif ! {
							{
								[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
							} && zcompile $map $tmp $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		done
		return ret
	fi
	if (( $# ))
	then
		argv=(${^argv}/*.zwc(ND) ${^argv}.zwc(ND) ${(M)argv:#*.zwc}) 
	else
		argv=(${^fpath}/*.zwc(ND) ${^fpath}.zwc(ND) ${(M)fpath:#*.zwc}) 
	fi
	argv=(${^argv%.zwc}.zwc) 
	for zwc
	do
		files=(${(f)"$(zcompile -t $zwc)"}) 
		if [[ $files[1] = *\(mapped\)* ]]
		then
			map=-M 
			mesg='succeeded (old saved)' 
		else
			map=-R 
			mesg=succeeded 
		fi
		if [[ $zwc = */* ]]
		then
			pre=${zwc%/*}/ 
		else
			pre= 
		fi
		if [[ $files[1] != *$ZSH_VERSION ]]
		then
			re=yes 
		else
			re= 
		fi
		files=(${pre}${^files[2,-1]:#/*} ${(M)files[2,-1]:#/*}) 
		[[ -z $re ]] && for file in $files
		do
			if [[ $file -nt $zwc ]]
			then
				re=yes 
				break
			fi
		done
		if [[ -n $re ]]
		then
			if [[ -n $check ]]
			then
				[[ -z $quiet ]] && print $zwc needs re-compilation
				ret=0 
			else
				[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
				tmp=(${^files}(N)) 
				if [[ $#tmp -ne $#files ]]
				then
					[[ -z $quiet ]] && print 'failed (missing files)'
					ret=1 
				else
					if [[ -z "$quiet" ]] && mv -f $zwc ${zwc}.old && zcompile $map $zwc $files
					then
						print $mesg
					elif ! {
							mv -f $zwc ${zwc}.old && zcompile $map $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		fi
	done
	return ret
}
zsh_stats () {
	fc -l 1 | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' | grep -v "./" | sort -nr | head -n 20 | column -c3 -s " " -t | nl
}
# Shell Options
setopt alwaystoend
setopt autocd
setopt autopushd
setopt completeinword
setopt extendedhistory
setopt noflowcontrol
setopt nohashdirs
setopt histexpiredupsfirst
setopt histignoredups
setopt histignorespace
setopt histverify
setopt interactivecomments
setopt login
setopt longlistjobs
setopt promptsubst
setopt pushdignoredups
setopt pushdminus
setopt sharehistory
# Aliases
alias -- -='cd -'
alias -- ...=../..
alias -- ....=../../..
alias -- .....=../../../..
alias -- ......=../../../../..
alias -- 1='cd -1'
alias -- 2='cd -2'
alias -- 3='cd -3'
alias -- 4='cd -4'
alias -- 5='cd -5'
alias -- 6='cd -6'
alias -- 7='cd -7'
alias -- 8='cd -8'
alias -- 9='cd -9'
alias -- _='sudo '
alias -- egrep='grep -E'
alias -- fgrep='grep -F'
alias -- g=git
alias -- ga='git add'
alias -- gaa='git add --all'
alias -- gam='git am'
alias -- gama='git am --abort'
alias -- gamc='git am --continue'
alias -- gams='git am --skip'
alias -- gamscp='git am --show-current-patch'
alias -- gap='git apply'
alias -- gapa='git add --patch'
alias -- gapt='git apply --3way'
alias -- gau='git add --update'
alias -- gav='git add --verbose'
alias -- gb='git branch'
alias -- gbD='git branch --delete --force'
alias -- gba='git branch --all'
alias -- gbd='git branch --delete'
alias -- gbg='LANG=C git branch -vv | grep ": gone\]"'
alias -- gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -D'
alias -- gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -d'
alias -- gbl='git blame -w'
alias -- gbm='git branch --move'
alias -- gbnm='git branch --no-merged'
alias -- gbr='git branch --remote'
alias -- gbs='git bisect'
alias -- gbsb='git bisect bad'
alias -- gbsg='git bisect good'
alias -- gbsn='git bisect new'
alias -- gbso='git bisect old'
alias -- gbsr='git bisect reset'
alias -- gbss='git bisect start'
alias -- gc='git commit --verbose'
alias -- gc!='git commit --verbose --amend'
alias -- gcB='git checkout -B'
alias -- gca='git commit --verbose --all'
alias -- gca!='git commit --verbose --all --amend'
alias -- gcam='git commit --all --message'
alias -- gcan!='git commit --verbose --all --no-edit --amend'
alias -- gcann!='git commit --verbose --all --date=now --no-edit --amend'
alias -- gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias -- gcas='git commit --all --signoff'
alias -- gcasm='git commit --all --signoff --message'
alias -- gcb='git checkout -b'
alias -- gcd='git checkout $(git_develop_branch)'
alias -- gcf='git config --list'
alias -- gcfu='git commit --fixup'
alias -- gcl='git clone --recurse-submodules'
alias -- gclean='git clean --interactive -d'
alias -- gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'
alias -- gcm='git checkout $(git_main_branch)'
alias -- gcmsg='git commit --message'
alias -- gcn='git commit --verbose --no-edit'
alias -- gcn!='git commit --verbose --no-edit --amend'
alias -- gco='git checkout'
alias -- gcor='git checkout --recurse-submodules'
alias -- gcount='git shortlog --summary --numbered'
alias -- gcp='git cherry-pick'
alias -- gcpa='git cherry-pick --abort'
alias -- gcpc='git cherry-pick --continue'
alias -- gcs='git commit --gpg-sign'
alias -- gcsm='git commit --signoff --message'
alias -- gcss='git commit --gpg-sign --signoff'
alias -- gcssm='git commit --gpg-sign --signoff --message'
alias -- gd='git diff'
alias -- gdca='git diff --cached'
alias -- gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias -- gdcw='git diff --cached --word-diff'
alias -- gds='git diff --staged'
alias -- gdt='git diff-tree --no-commit-id --name-only -r'
alias -- gdup='git diff @{upstream}'
alias -- gdw='git diff --word-diff'
alias -- gf='git fetch'
alias -- gfa='git fetch --all --tags --prune --jobs=10'
alias -- gfg='git ls-files | grep'
alias -- gfo='git fetch origin'
alias -- gg='git gui citool'
alias -- gga='git gui citool --amend'
alias -- ggpull='git pull origin "$(git_current_branch)"'
alias -- ggpur=ggu
alias -- ggpush='git push origin "$(git_current_branch)"'
alias -- ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias -- ghh='git help'
alias -- gignore='git update-index --assume-unchanged'
alias -- gignored='git ls-files -v | grep "^[[:lower:]]"'
alias -- git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias -- gk='\gitk --all --branches &!'
alias -- gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
alias -- gl='git pull'
alias -- glg='git log --stat'
alias -- glgg='git log --graph'
alias -- glgga='git log --graph --decorate --all'
alias -- glgm='git log --graph --max-count=10'
alias -- glgp='git log --stat --patch'
alias -- glo='git log --oneline --decorate'
alias -- glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias -- glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias -- glog='git log --oneline --decorate --graph'
alias -- gloga='git log --oneline --decorate --graph --all'
alias -- glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias -- glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias -- glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias -- glp=_git_log_prettily
alias -- gluc='git pull upstream $(git_current_branch)'
alias -- glum='git pull upstream $(git_main_branch)'
alias -- gm='git merge'
alias -- gma='git merge --abort'
alias -- gmc='git merge --continue'
alias -- gmff='git merge --ff-only'
alias -- gmom='git merge origin/$(git_main_branch)'
alias -- gms='git merge --squash'
alias -- gmtl='git mergetool --no-prompt'
alias -- gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias -- gmum='git merge upstream/$(git_main_branch)'
alias -- gp='git push'
alias -- gpd='git push --dry-run'
alias -- gpf='git push --force-with-lease --force-if-includes'
alias -- gpf!='git push --force'
alias -- gpoat='git push origin --all && git push origin --tags'
alias -- gpod='git push origin --delete'
alias -- gpr='git pull --rebase'
alias -- gpra='git pull --rebase --autostash'
alias -- gprav='git pull --rebase --autostash -v'
alias -- gpristine='git reset --hard && git clean --force -dfx'
alias -- gprom='git pull --rebase origin $(git_main_branch)'
alias -- gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias -- gprum='git pull --rebase upstream $(git_main_branch)'
alias -- gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias -- gprv='git pull --rebase -v'
alias -- gpsup='git push --set-upstream origin $(git_current_branch)'
alias -- gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes'
alias -- gpu='git push upstream'
alias -- gpv='git push --verbose'
alias -- gr='git remote'
alias -- gra='git remote add'
alias -- grb='git rebase'
alias -- grba='git rebase --abort'
alias -- grbc='git rebase --continue'
alias -- grbd='git rebase $(git_develop_branch)'
alias -- grbi='git rebase --interactive'
alias -- grbm='git rebase $(git_main_branch)'
alias -- grbo='git rebase --onto'
alias -- grbom='git rebase origin/$(git_main_branch)'
alias -- grbs='git rebase --skip'
alias -- grbum='git rebase upstream/$(git_main_branch)'
alias -- grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias -- grev='git revert'
alias -- greva='git revert --abort'
alias -- grevc='git revert --continue'
alias -- grf='git reflog'
alias -- grh='git reset'
alias -- grhh='git reset --hard'
alias -- grhk='git reset --keep'
alias -- grhs='git reset --soft'
alias -- grm='git rm'
alias -- grmc='git rm --cached'
alias -- grmv='git remote rename'
alias -- groh='git reset origin/$(git_current_branch) --hard'
alias -- grrm='git remote remove'
alias -- grs='git restore'
alias -- grset='git remote set-url'
alias -- grss='git restore --source'
alias -- grst='git restore --staged'
alias -- grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias -- gru='git reset --'
alias -- grup='git remote update'
alias -- grv='git remote --verbose'
alias -- gs='git status'
alias -- gsb='git status --short --branch'
alias -- gsd='git svn dcommit'
alias -- gsh='git show'
alias -- gsi='git submodule init'
alias -- gsps='git show --pretty=short --show-signature'
alias -- gsr='git svn rebase'
alias -- gss='git status --short'
alias -- gst='git status'
alias -- gsta='git stash push'
alias -- gstaa='git stash apply'
alias -- gstall='git stash --all'
alias -- gstc='git stash clear'
alias -- gstd='git stash drop'
alias -- gstl='git stash list'
alias -- gstp='git stash pop'
alias -- gsts='git stash show --patch'
alias -- gstu='gsta --include-untracked'
alias -- gsu='git submodule update'
alias -- gsw='git switch'
alias -- gswc='git switch --create'
alias -- gswd='git switch $(git_develop_branch)'
alias -- gswm='git switch $(git_main_branch)'
alias -- gta='git tag --annotate'
alias -- gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'
alias -- gts='git tag --sign'
alias -- gtv='git tag | sort -V'
alias -- gunignore='git update-index --no-assume-unchanged'
alias -- gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias -- gup=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gup%F{yellow}\' is a deprecated alias, using \'%F{green}gpr%F{yellow}\' instead.%f"\n    gpr'
alias -- gupa=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupa%F{yellow}\' is a deprecated alias, using \'%F{green}gpra%F{yellow}\' instead.%f"\n    gpra'
alias -- gupav=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupav%F{yellow}\' is a deprecated alias, using \'%F{green}gprav%F{yellow}\' instead.%f"\n    gprav'
alias -- gupom=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupom%F{yellow}\' is a deprecated alias, using \'%F{green}gprom%F{yellow}\' instead.%f"\n    gprom'
alias -- gupomi=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupomi%F{yellow}\' is a deprecated alias, using \'%F{green}gpromi%F{yellow}\' instead.%f"\n    gpromi'
alias -- gupv=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupv%F{yellow}\' is a deprecated alias, using \'%F{green}gprv%F{yellow}\' instead.%f"\n    gprv'
alias -- gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias -- gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias -- gwipe='git reset --hard && git clean --force -df'
alias -- gwt='git worktree'
alias -- gwta='git worktree add'
alias -- gwtls='git worktree list'
alias -- gwtmv='git worktree move'
alias -- gwtrm='git worktree remove'
alias -- history=omz_history
alias -- l='ls -lah'
alias -- la='ls -lAh'
alias -- ll='ls -lh'
alias -- ls='ls -G'
alias -- lsa='ls -lah'
alias -- md='mkdir -p'
alias -- pip=pip3
alias -- python=python3
alias -- rd=rmdir
alias -- resource='source ~/.zshrc'
alias -- run-help=man
alias -- tf=terraform
alias -- vib='vim ~/.zshrc;resource'
alias -- which-command=whence
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/opt/homebrew/lib/node_modules/\@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin/rg'
fi
export PATH=/opt/homebrew/bin\:/opt/homebrew/sbin\:/usr/local/bin\:/System/Cryptexes/App/usr/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin\:/Applications/iTerm.app/Contents/Resources/utilities\:/Users/davidg/.local/bin\:/Users/davidg/.local/bin
