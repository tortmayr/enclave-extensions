# zsh reads this only while ZDOTDIR is unset, i.e. in the first shell of a
# session. Child shells inherit ZDOTDIR and read $ZDOTDIR/.zshenv directly.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
