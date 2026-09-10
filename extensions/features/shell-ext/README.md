# shell-ext

Installs the portable dotfiles from
[`tortmayr/dotfiles`](https://github.com/tortmayr/dotfiles) into the agent
home, so an interactive session in an enclave looks and behaves like the host
shell: zsh with powerlevel10k, syntax highlighting, autosuggestions,
completions, the usual keybindings, aliases and helper functions.

Use this **instead of** the built-in `shell-extras` feature. That one installs
oh-my-zsh and writes `~/.zshrc`; this one uses `ZDOTDIR=~/.config/zsh`, so the
two do not collide on a file — but enabling both just leaves a dead oh-my-zsh
tree in the image.

## What it does

- Clones `tortmayr/dotfiles` at the commit pinned in `dotfiles.version` and
  installs its `container` profile (`bash bat bin git lazygit tmux zsh`) with
  `--method copy`. The desktop packages and the agent CLI configs are excluded:
  enclave composes the tool's own config from its stores, and a baked
  `~/.claude/settings.json` would collide with that.
- Runs the dotfiles' `bootstrap.sh`, which links `fd`/`bat` to Debian's
  `fdfind`/`batcat` and clones the four zsh plugins at their pinned versions.
- Installs `host.d/00-enclave.zsh` as the container layer of the dotfiles'
  three-layer scheme (portable → `host.d` → `local.d`). It redirects `HISTFILE`
  into the mounted history directory, sets `USER_GIT_DIR` and `EDITOR`, and
  installs the zsh direnv hook.
- Appends an interactive-only `exec zsh` to `~/.bashrc`.

Everything happens in `install.sh` rather than `files/home/`, because the image
bakes `files/home` *after* the feature install phase — too late to pre-generate
the completion and fzf caches.

## Why `~/.bashrc` and not `chsh`

`enclave shell` and `enclave exec` both run a hard-coded `/bin/bash`
(`internal/runtime/command_builder.go`, `internal/runtime/exec.go`); neither
consults `/etc/passwd`, so changing the login shell would have no effect.
`~/.bashrc` is the one hook both paths reach.

The agent is started with `bash -c '. ~/.bashrc; exec "$@"'`, which is *not*
interactive, so the `case $-` guard keeps the switch away from it. The agent's
own `Bash` tool calls also stay on bash — anything the agent needs must not
live only in the zsh layer.

Set `ENCLAVE_NO_ZSH=1` to get plain bash for a session.

## Persistence

`$HOME` is not persistent. Shell history is, via the directory enclave mounts
at `~/.shell_history`, so the overlay points `HISTFILE` there; with
`--no-history` the directory is absent and the portable default applies. The
completion dump and fzf cache are pre-generated at build time. The
powerlevel10k instant-prompt cache is not — only a real prompt writes it — so
the first prompt of each session pays for it.

## Updating

```bash
scripts/update-shell-ext.sh            # pin to the dotfiles' current main
scripts/update-shell-ext.sh <ref|sha>  # pin to something specific
enclave --rebuild
```

The workstation tracks the same repository through a submodule in `dev-xp`;
that pin and this one move independently, and the script prints both.

## Enabling

```json
{ "features": ["+shell-ext"] }
```

## Known gaps

- `fman` needs a man page database; the base image ships none.
- `openLazygit`'s `sgit` fallback searches `$USER_GIT_DIR`, which only contains
  what enclave actually mounted. A `--add-dir` outside the project tree lands
  at its own host path and is not found.
