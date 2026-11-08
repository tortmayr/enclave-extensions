#!/bin/bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Install the dotfiles in dotfiles/ into an agent image and make interactive
# sessions land in zsh.
#
# dotfiles/ is generated from the owner's private dotfiles repository and
# holds only its container profile; do not edit it here. Enclave copies this
# feature into the image, so nothing is cloned and nothing is pinned.
#
# Runs in the user phase (needsRoot is false), so it is the agent user with
# $HOME already set and ~/.local/bin on PATH. Everything is done from here
# rather than from files/home/, because the image bakes files/home *after* the
# feature install phase, too late to pre-generate the caches below.
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The container profile is the desktop-free subset. --method copy because the
# image has no GNU Stow, and symlinks into the build context would dangle.
"$script_dir/dotfiles/link.sh" --profile container --method copy --target "$HOME"

# Command shims (fd -> fdfind, bat -> batcat) and the pinned zsh plugins.
"$script_dir/dotfiles/bootstrap.sh"

# The container layer of the three-layer scheme (portable -> host.d -> local.d).
mkdir -p "$HOME/.config/zsh/host.d"
cp "$script_dir/container.d/"*.zsh "$HOME/.config/zsh/host.d/"

# Pre-generate what would otherwise be rebuilt on every session start: $HOME is
# not persistent, so these caches never survive to a second session. Both are
# deterministic and need no TTY. The powerlevel10k instant-prompt cache is
# deliberately not pre-generated; it is only written by a real prompt.
mkdir -p "$HOME/.cache/zsh"
zsh -c 'autoload -Uz compinit; compinit -d "$HOME/.config/zsh/.zcompdump"' || true
fzf --zsh > "$HOME/.cache/zsh/fzf.zsh" || true

# powerlevel10k ships no gitstatusd binary — its usrbin/ holds only a .gitkeep —
# so the first prompt downloads one into ~/.cache/gitstatus. With an ephemeral
# $HOME that is every session: a ~2MB fetch through the gateway, announced as
# "[powerlevel10k] fetching gitstatusd ..". The same script the prompt would
# run pulls it now instead, into the image.
sh "$HOME/.config/zsh/plugins/powerlevel10k/gitstatus/install" || true

# `enclave shell` and `enclave exec` both exec a hard-coded /bin/bash and never
# consult the login shell (internal/runtime/command_builder.go,
# internal/runtime/exec.go), so `chsh` would have no effect and ~/.bashrc is the
# only hook that fires on both paths. The `case $-` guard keeps this to
# interactive sessions: the agent itself is started with
# `bash -c '. ~/.bashrc; exec "$@"'`, which is not interactive and must not be
# hijacked. This block is appended last so nothing useful sits below the exec.
cat >> "$HOME/.bashrc" <<'BASHRC'

# dotfiles: hand interactive sessions to zsh (ENCLAVE_NO_ZSH=1 opts out).
# The TTY test matters as much as the interactive flag: `bash -ic '<cmd>'` is
# interactive but has no terminal, and exec'ing there would swallow <cmd>.
case $- in
    *i*)
        if [ -t 0 ] && [ -t 1 ] && [ -z "${ENCLAVE_NO_ZSH:-}" ] \
           && command -v zsh >/dev/null 2>&1; then
            exec zsh
        fi
        ;;
esac
BASHRC

# Fail the build rather than shipping an image whose interactive shell is
# broken: a non-interactive zsh must start cleanly with the config in place.
if ! zsh -c 'source "$HOME/.config/zsh/.zshrc"' >/dev/null 2>&1; then
    echo "warning: sourcing .zshrc in a non-interactive zsh reported an error" >&2
fi
for required in "$HOME/.zshenv" "$HOME/.config/zsh/.zshenv" "$HOME/.config/zsh/.zshrc" \
                "$HOME/.config/zsh/host.d/00-enclave.zsh" \
                "$HOME/.config/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme"; do
    if [ ! -e "$required" ]; then
        echo "error: expected $required after install" >&2
        exit 1
    fi
done

echo "dotfiles installed (container profile)"
