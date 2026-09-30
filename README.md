# dotfiles

Config files for my machines, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a **stow package**, laid out as if it were `$HOME`:

```
dotfiles/
├── common/       # files identical on every machine
├── thinkpad/     # Arch, KDE Plasma (Wayland)
├── pop-os/       # Pop!_OS 24.04, COSMIC
├── macbook/      # (not yet)
└── tools.txt     # not a package — the tool list, see below
```

`tools.txt` is repo data, not a dotfile, so it sits at the root and is never
stowed. Stow only touches the package directories you name.

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

## Required tools

The config here assumes tools are installed — `common/.zshrc` calls `starship`,
`fzf` and `zoxide` unguarded, so a machine missing any of them throws errors on
every shell startup. `tools.txt` states the whole set, each with the reason it's
wanted, in three tiers by how loudly its absence announces itself:

| tier | without it |
|---|---|
| `shell` | errors on every shell startup |
| `auto` | the vault's rollover / lint / digest automation breaks |
| `agent` | nothing errors; a capability is silently absent |

That last tier is why the file exists. `jq` sat missing on a machine for
a while without any signal, because the hook that needs it fails by exiting 0.

```sh
check-tools        # stowed to ~/.local/bin; reports what's absent and why
```

It installs nothing — package names differ across pacman / apt / brew and
mapping them isn't worth the maintenance. Install by hand, re-run the check.
Exits nonzero if anything is missing, so it can gate a setup script.

Adding a tool: a row in `tools.txt` needs a real consequence in its `why`
column. If nothing breaks when it's absent, it's a preference, not a
requirement, and it doesn't belong here.

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

Either route, finish by checking the machine actually has what the config
assumes — `check-tools` is only on PATH once `common/` is stowed and a new
shell has started, so the first run may need the full path:

```sh
~/.local/bin/check-tools
```

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
