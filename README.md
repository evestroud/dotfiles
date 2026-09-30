# dotfiles

Config files for my machines, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a **stow package**, laid out as if it were `$HOME`:

```
dotfiles/
├── common/       # files identical on every machine
├── thinkpad/     # Arch, KDE Plasma (Wayland)
├── pop-os/       # Pop!_OS 24.04, COSMIC
└── macbook/      # (not yet)
```

A machine stows `common/` plus its own directory:

```sh
cd <wherever the repo is cloned>
stow -t ~ common pop-os     # symlinks ~/.zshrc -> common/.zshrc, ~/.zshrc.local -> pop-os/.zshrc.local
```

The clone path is per-machine and doesn't matter (`~/repos` on the ThinkPad,
`~/eve-repos` on pop-os); stow only cares about `-t ~` and the cwd.

Stow refuses to link two packages that contain the same path, so every file
lives in exactly one package — a file is either shared (`common/`) or
per-machine (`<host>/`), never both.

## Shared vs per-machine

Start per-machine; promote a file to `common/` (`git mv`) once it's actually
identical on two machines, rather than guessing up front.

For files that are *mostly* shared but need per-machine bits, `common/.zshrc`
ends with

```sh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

and each host package provides its own `.zshrc.local`. That file is where the
editor's binary name lives (`helix` on Arch, `hx` on Debian/Pop and Homebrew)
along with any language managers, so `common/.gitconfig` can drop
`core.editor` entirely and let git fall back to `$EDITOR`.

## Setting up a new machine

```sh
git clone git@github.com:evestroud/dotfiles.git <path>
cd <path>
mkdir <host>                          # if it's a new machine
```

Then one of two routes, depending on what you want to keep:

**Keeping the machine's existing config** — adopt it into the package:

```sh
stow --adopt -t ~ <host>              # moves existing real files into the package, then links them
git diff                              # --adopt overwrote the package with the machine's live files;
                                      # review, keep what's wanted, `git checkout --` the rest
```

**Replacing it with the shared config** — do *not* use `--adopt`, which would
overwrite the repo with the files you're trying to discard. Move them aside and
stow plainly:

```sh
mkdir -p ~/dotfiles-pre-stow.bak
mv ~/.zshrc ~/.gitconfig ~/dotfiles-pre-stow.bak/
stow -t ~ common <host>
```

Stow refuses to replace an existing real file, so anything left behind will
show up as a conflict rather than being silently clobbered.

## Re-stowing after files move between packages

Promoting a file to `common/` breaks the symlinks on every machine that was
getting it from its host package — they keep pointing at the old path. On each
of those machines:

```sh
stow -D -t ~ <host>          # unlink the old set
stow -t ~ common <host>      # relink from the new layout
```

## Rules

- No secrets, even though the repo is private.
- Only files that carry actual choices; not app state or generated config.
