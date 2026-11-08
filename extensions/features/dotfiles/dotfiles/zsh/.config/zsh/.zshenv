# Every zsh reads this file, nested shells included; ~/.zshenv only sets
# ZDOTDIR for the first one and sources it.

# Skip Ubuntu's global compinit in /etc/zsh/zshrc; we run our own in .zshrc.
skip_global_compinit=1

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Machine-specific environment that has to exist before .zshrc runs, and for
# non-interactive shells that never read .zshrc at all: package-manager shims
# (homebrew, mise, ...) that put tools on PATH. Tracked, one file per machine.
for _zshenv_layer in "$ZDOTDIR"/host.d/*.zshenv(N); do
  source "$_zshenv_layer"
done
unset _zshenv_layer

# Nested shells prepend the same directories again. -U dedupes in place (keeping
# the first copy) but ignores later `PATH=` assignments, so .zshrc repeats it.
typeset -U path fpath
