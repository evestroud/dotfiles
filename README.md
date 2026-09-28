# dotfiles

Config files for my machines, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a **stow package**, laid out as if it were `$HOME`:

```
dotfiles/
├── common/       # (not yet) files identical on every machine
├── thinkpad/     # Arch, KDE Plasma (Wayland)
├── macbook/      # (not yet)
└── pop-os/       # (not yet)
```

A machine stows its own directory, plus `common/` once that exists:

```sh
cd ~/repos/dotfiles
stow -t ~ thinkpad          # symlinks ~/.zshrc -> ~/repos/dotfiles/thinkpad/.zshrc, etc.
stow -t ~ common thinkpad   # once common/ exists
```

Stow refuses to link two packages that contain the same path, so every file
lives in exactly one package — a file is either shared (`common/`) or
per-machine (`<host>/`), never both.

## Shared vs per-machine

Start per-machine; promote a file to `common/` (`git mv`) once it's actually
identical on two machines, rather than guessing up front.

For files that are *mostly* shared but need per-machine bits (e.g. `.zshrc` on
macOS needs Homebrew paths), the `common/` version ends with

```sh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

and each host package provides its own `.zshrc.local`.

## Setting up a new machine

```sh
git clone git@github.com:evestroud/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
mkdir <host>                          # if it's a new machine
stow --adopt -t ~ <host>              # moves existing real files into the package, then links them
git diff                              # --adopt overwrote the package with the machine's live files;
                                      # review, keep what's wanted, `git checkout --` the rest
```

Without `--adopt`, stow refuses to replace an existing real file — move it
aside first.

## Rules

- No secrets, even though the repo is private.
- Only files that carry actual choices; not app state or generated config.
