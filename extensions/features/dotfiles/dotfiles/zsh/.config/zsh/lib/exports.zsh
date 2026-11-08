#!/usr/bin/env sh
# Portable environment. Anything that names a specific machine, package
# manager, GUI application or client belongs in host.d/ instead.

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Shell libraries shipped alongside these dotfiles (worktree.sh, git.sh).
export SCRIPT_LIBRARY_DIR="$ZDOTDIR/lib"

# USER_GIT_DIR — the root `sgit` / `cgit` scan for repositories — is owned by
# the machine layer and deliberately not defaulted here. This file runs before
# host.d, so a default set here would already be non-empty by the time an
# overlay tries its own `${USER_GIT_DIR:-...}`, and the overlay would silently
# lose. $HOME/Git is also simply wrong wherever repositories are not below the
# local home, such as a container that mirrors the host's absolute paths.
# git.sh keeps a $HOME/Git fallback for the case where no layer sets it.

# EDITOR is deliberately not set here either: it is `code` on a workstation and
# a terminal editor everywhere else. Every host.d layer must set both.

# Path additions. Listing a directory that does not exist is harmless.
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# fzf in the terminal's 16 colours, so the desktop theme's palette applies (bg+ is muted, color8)
# A blank gutter: fzf draws it as a bar in the foreground colour when gutter is the default
export FZF_DEFAULT_OPTS="
  --color=16,fg:7,bg:-1,hl:4
  --color=fg+:15,bg+:8,hl+:12
  --color=info:8,prompt:4,pointer:5
  --color=marker:5,spinner:6,header:8
  --color=border:8,label:8,query:7
  --color=gutter:-1,selected-bg:8,selected-fg:15
  --gutter=' '
  --border='rounded'"


# `fd` and `bat` are the upstream names. Debian ships them as `fdfind` and
# `batcat`; bootstrap.sh links the short names into ~/.local/bin so this
# config reads the same on every distribution.
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
# fzf overrides
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'if [ -d {} ]; then eza -ah -1 --color=always --icons=always {}; else bat -n --color=always --style=numbers {} 2>/dev/null || file -b {}; fi'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# Configure man to use bat
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"
