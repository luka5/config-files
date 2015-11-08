# vim:ft=zsh ts=2 sw=2 sts=2

CURRENT_BG='NONE'
PRIMARY_FG=black

# Characters
SEGMENT_SEPARATOR="\ue0b0"
RSEGMENT_SEPARATOR="\ue0b2"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"
CLOCK="\u25f7"

prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

rprompt_segment() {
  local fg bg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG == 'NONE' ]]; then
    print -n "%{%F{$1}%}$RSEGMENT_SEPARATOR%{$fg$bg%}"
  elif [[ $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$RSEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG='NONE'
}


prompt_context() {
  local shell_level current_time
  if [[ $SHLVL > 1 ]]; then shell_level=" +$(($SHLVL-1))"; fi
  current_time=$(date '+%H:%M')
  prompt_segment cyan $PRIMARY_FG " ${CLOCK}${current_time}${shell_level} "
}

rprompt_user() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    rprompt_segment $PRIMARY_FG default " %(!.%{%F{yellow}%}.)$user@%m "
  fi
}

prompt_git() {
  local color ref ahead behind

  ref="${vcs_info_msg_0_}"
  color=green
  if [[ -n "$ref" ]]; then
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi

    ahead=$(git rev-list @{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git rev-list HEAD..@{upstream} 2>/dev/null | wc -l | tr -d ' ')
    if [[ $behind > 0 ]] && [[ $ahead > 0 ]]; then
      color=red
      ref+=" ➚$ahead ➘$behind"
    elif [[ $behind > 0 ]]; then
      ref+=" ➘$behind"
      color=yellow
    elif [[ $ahead > 0 ]]; then
      ref+=" ➚$ahead"
      color=green
    else
      color=green
    fi

    prompt_segment $color $PRIMARY_FG
    print -Pn " $ref "
  fi
}

function +git-untracked() {
  if git status --porcelain | fgrep '??' &> /dev/null ; then
    hook_com[unstaged]+=" $LIGHTNING"
  fi
}

prompt_dir() {
  prompt_segment blue $PRIMARY_FG " $(pwd) "
}

prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default " $symbols "
}

rprompt_stats() {
  local memfree memtotal load
  memfree=$( bc -l <<< "scale=1;`sed -n "s/MemFree:[\t ]\+\([0-9]\+\) kB/\1/p" /proc/meminfo`/1024/1024" )
  memtotal=$( bc -l <<< "scale=1;`sed -n "s/MemTotal:[\t ]\+\([0-9]\+\) kB/\1/Ip" /proc/meminfo`/1024/1024" )
  load=$(cat /proc/loadavg)
  rprompt_segment black white " $memfree/${memtotal}GB | $load "
}

build_prompt() {
  RETVAL=$?
  CURRENT_BG='NONE'
  prompt_status
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
  echo
  prompt_segment black white " >>= "
  prompt_end
}

build_rprompt() {
  #rprompt_user
  rprompt_stats
}

prompt_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}$(build_prompt) '
  RPROMPT='%{%f%b%k%}$(build_rprompt)'
}

prompt_setup() {
  setopt prompt_subst

  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:git*' stagedstr '✚'
  zstyle ':vcs_info:git*' unstagedstr '●'
  zstyle ':vcs_info:git*' formats '%b %c%u'
  zstyle ':vcs_info:git*' actionformats '%b %c%u (%a)'

  zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
}

prompt_setup "$@"
