# Enclave layer for the portable dotfiles, installed into
# ~/.config/zsh/host.d/. The core .zshrc sources this after its own config, so
# everything here overrides a portable default.

# Enclave bind-mounts a per-project, per-tool directory at ~/.shell_history and
# points bash's HISTFILE inside it. $HOME itself does not survive a session, so
# the portable ~/.zsh_history would be discarded every time. Guarded because
# `enclave --no-history` leaves the directory unmounted.
if [[ -d "$HOME/.shell_history" ]]; then
  HISTFILE="$HOME/.shell_history/zsh_history"
fi

# Enclave mounts the project at its own absolute host path, so repositories sit
# under the host's home directory rather than the container's ($HOME is
# /home/agent here). Only mounted paths exist, so a broad search root is free.
# Overridable with `enclave --env USER_GIT_DIR=...`.
export USER_GIT_DIR="${USER_GIT_DIR:-/home/tobias/Git}"

# Core deliberately leaves EDITOR to the machine layer. `code` is not here.
export EDITOR="nano"

# The image appends `direnv hook bash` to ~/.bashrc and would append the zsh
# hook to ~/.zshrc — which never exists, because ZDOTDIR points at
# ~/.config/zsh. So zsh has to install its own hook.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
