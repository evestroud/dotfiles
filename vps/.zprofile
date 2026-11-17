# starship, fzf and zoxide are upstream release binaries in ~/.local/bin.
# Ubuntu's ~/.profile puts that on PATH, but only the desktop session reads it;
# a zsh login shell (ssh, a tty) doesn't, so common/.zshrc fails to find them.
#
# Here rather than in .zshrc.local: common/.zshrc calls fzf/zoxide before it
# sources .zshrc.local, so PATH has to be set earlier. typeset -U drops the
# duplicate where ~/.profile already added it.
typeset -U path
path=(~/.local/bin $path)
