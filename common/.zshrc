export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY
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
