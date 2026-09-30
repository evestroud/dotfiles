# MacPorts, ahead of Homebrew: packages move over one at a time as Homebrew
# stops shipping bottles for this (out-of-support) macOS, so a ported tool
# should win over any leftover Homebrew copy.
#
# Here rather than in .zshrc.local: common/.zshrc calls fzf/zoxide before it
# sources .zshrc.local, so PATH has to be set earlier. And not .zshenv: macOS's
# /etc/zprofile runs path_helper, which would push /usr/local/bin back in front.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
