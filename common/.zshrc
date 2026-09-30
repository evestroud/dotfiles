# History. Without HISTFILE set, zsh keeps history in memory only and it dies
# with the shell -- which is what fzf's Ctrl-R widget reads, so it goes too.
HISTFILE=~/.zsh_history
export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY        # record timestamp and duration per entry
setopt APPEND_HISTORY          # don't truncate the file on exit (zsh default; explicit)
setopt INC_APPEND_HISTORY      # write each command as entered, not at shell exit
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicates, keeping Ctrl-R signal high
setopt HIST_REDUCE_BLANKS      # tidy whitespace before storing
setopt HIST_IGNORE_SPACE       # a command typed with a leading space isn't recorded
setopt HIST_VERIFY             # `!!` loads into the buffer instead of firing
# Deliberately NOT share_history: arrow-up stays session-local. Concurrent
# panes don't see each other's commands until a new shell starts.

setopt autocd
autoload -Uz compinit; compinit
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Map Ctrl+Left and Ctrl+Right to move word-by-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
# 1. Force Konsole's control sequence for Ctrl+W to bind to Zsh's widget
bindkey '^W' backward-kill-word

# 2. Tell Zsh exactly which non-alphanumeric symbols to consider "part of the word"
# Removing characters like /, -, ., and _ from this list forces Ctrl+W to stop at them.
export WORDCHARS='*?[]~==&;!#$%^(){}<>'


eval "$(starship init zsh)"
source <(fzf --zsh)
eval "$(zoxide init zsh)"

alias ls='ls --color=auto'

export PATH="$HOME/.local/bin:$PATH"

# source ~/.antidote/antidote.zsh

# # initialize plugins statically with ${ZDOTDIR:-$HOME}/.zsh_plugins.txt
# antidote load

# Per-machine additions: editor name, language managers, host-specific PATH.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
