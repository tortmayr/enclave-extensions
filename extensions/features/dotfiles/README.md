# dotfiles

Makes an interactive enclave session look and behave like my host shell: zsh
with powerlevel10k and pinned plugins, plus the bash, bat, git, lazygit and
tmux configs. Use it **instead of** the built-in `shell-extras`, which installs
oh-my-zsh and writes `~/.zshrc`. The two do not collide on a file (`ZDOTDIR` is
`~/.config/zsh` here), but enabling both leaves a dead oh-my-zsh tree in the
image.

```bash
enclave features add tortmayr/enclave-extensions --name dotfiles
```

Enable it per project with `+dotfiles`.

| Path | Role |
|---|---|
| `spec.yaml` | feature metadata and the apt packages the config calls |
| `install.sh` | installs `dotfiles/` with `--method copy`, the plugins and the caches below |
| `container.d/00-enclave.zsh` | the container's `host.d` layer: history, `USER_GIT_DIR`, `EDITOR`, direnv |
| `dotfiles/` | **generated**; do not edit here |

`dotfiles/` is the container profile of my private dotfiles repository,
regenerated there by `export-enclave.sh`. It holds only tracked files from the
packages that profile names.

## Why `~/.bashrc` and not `chsh`

`enclave shell` and `enclave exec` both run a hard-coded `/bin/bash`
(`internal/runtime/command_builder.go`, `internal/runtime/exec.go`); neither
consults `/etc/passwd`, so changing the login shell would have no effect.
`~/.bashrc` is the one hook both paths reach, and `install.sh` appends an
interactive-only `exec zsh` to it.

The agent is started with `bash -c '. ~/.bashrc; exec "$@"'`, which is *not*
interactive, so the `case $-` guard keeps the switch away from it. The agent's
own `Bash` tool calls also stay on bash, so anything the agent needs must not
live only in the zsh layer. Set `ENCLAVE_NO_ZSH=1` for plain bash in a session.

## Persistence

`$HOME` is not persistent. Shell history is, via the directory enclave mounts
at `~/.shell_history`, so `container.d/00-enclave.zsh` points `HISTFILE` there;
with `--no-history` the directory is absent and the portable default applies.

The completion dump, the fzf cache and `gitstatusd` are pre-generated at build
time, because an ephemeral `$HOME` means each would otherwise be rebuilt on
every session start. `gitstatusd` is the expensive one: powerlevel10k ships no
binary and downloads it on first prompt, which is the
`[powerlevel10k] fetching gitstatusd ..` line. The powerlevel10k instant-prompt
cache is deliberately *not* pre-generated (only a real prompt writes it), so
the first prompt of each session still pays for that one.

## Known gaps

- `fman` needs a man page database; the base image ships none.
- `openLazygit`'s `sgit` fallback searches `$USER_GIT_DIR`, which only contains
  what enclave actually mounted. A `--add-dir` outside the project tree lands
  at its own host path and is not found.

