setup_zsh_completion() {
  # Create cache and completions dir and add to $fpath.
  [[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"
  (( ${fpath[(Ie)$ZSH_CACHE_DIR/completions]} )) || fpath=("$ZSH_CACHE_DIR/completions" $fpath)

  # Completions shipped with these dotfiles, as opposed to the ones tools
  # generate into the cache dir above.
  if [[ -d "$ZDOTDIR/completions" ]]; then
    (( ${fpath[(Ie)$ZDOTDIR/completions]} )) || fpath=("$ZDOTDIR/completions" $fpath)
  fi

  # User-installed completions (e.g. `make install`); zsh doesn't search here by default.
  local xdg_site_functions="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
  if [[ -d "$xdg_site_functions" ]]; then
    (( ${fpath[(Ie)$xdg_site_functions]} )) || fpath=("$xdg_site_functions" $fpath)
  fi

  # Add zsh-completions plugin to fpath (must be before compinit).
  local zsh_completions_dir="$ZDOTDIR/plugins/zsh-completions/src"
  if [[ -d "$zsh_completions_dir" ]]; then
    (( ${fpath[(Ie)$zsh_completions_dir]} )) || fpath=("$zsh_completions_dir" $fpath)
  fi

  # Use cached compinit (skip validation) when zcompdump is less than 24h old.
  # `compinit -C` trusts the dump and never rescans $fpath, so a completion
  # added to completions/ would stay invisible for a day. Treat a dump older
  # than that directory as stale too.
  autoload -Uz compinit
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -n $zcompdump(#qN.mh-24) && ! "$ZDOTDIR/completions" -nt "$zcompdump" ]]; then
    compinit -C -d "$zcompdump"
  else
    compinit -d "$zcompdump"
  fi
  # compinit sources the dump, and source prefers a newer .zwc: ~20ms saved.
  [[ "$zcompdump.zwc" -nt "$zcompdump" ]] || zcompile "$zcompdump"

  # Bash completion fallback: bashcompinit must run AFTER compinit.
  autoload -U +X bashcompinit && bashcompinit

  # Completion styles
  zstyle ':completion:*' menu select          # Interactive highlighted menu; navigate with Tab/arrow keys
  zstyle ':completion:*' special-dirs true    # Complete . and .. special directories
  zstyle ':completion:*' list-colors ''       # Enable color for completion list
  zstyle ':completion:*' use-cache yes        # Use caching so that commands like apt and dpkg complete are useable
  zstyle ':completion:*' completer _expand_alias _complete _ignored # Expand aliases with tab
  zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*' # case-insensitive
  zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories # disable named-directories autocompletion

}

setup_fzf() {
  command -v fzf >/dev/null 2>&1 || return 0

  # Set up fzf key bindings and fuzzy completion (cached). The cache is keyed on
  # the binary's inode, which every upgrade replaces, so it never outlives a fix.
  zmodload -F zsh/stat b:zstat
  local _fzf_inode
  zstat -A _fzf_inode +inode -- "${commands[fzf]:A}" || return 0
  local _fzf_cache="$ZSH_CACHE_DIR/fzf-$_fzf_inode.zsh"
  if [[ ! -f "$_fzf_cache" ]]; then
    [[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
    rm -f "$ZSH_CACHE_DIR"/fzf(|-<->).zsh(N)
    {
      fzf --zsh
      # A blank gutter, as the default draws a bar; --gutter needs fzf 0.65+, Debian trixie ships 0.60.
      if fzf --gutter=' ' --version >/dev/null 2>&1; then
        print -r -- "FZF_DEFAULT_OPTS+=\" --gutter=' '\""
      fi
    } > "$_fzf_cache"
  fi
  source "$_fzf_cache"
}

setup_nvm_lazy_loading() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ ! -d "$NVM_DIR" ]]; then
    return
  fi

  # Add current node version to PATH without sourcing nvm.sh.
  local _nvm_alias
  _nvm_alias=$(<"$NVM_DIR/alias/default") 2>/dev/null
  local _nvm_default_path
  if [[ -d "$NVM_DIR/versions/node/$_nvm_alias/bin" ]]; then
    _nvm_default_path="$NVM_DIR/versions/node/$_nvm_alias/bin"
  else
    # Resolve partial alias (e.g. "22" -> latest v22.x.x).
    local -a _nvm_matches=("$NVM_DIR"/versions/node/v${_nvm_alias}*/bin(N/))
    (( ${#_nvm_matches} )) && _nvm_default_path="${_nvm_matches[-1]}"
  fi
  [[ -d "$_nvm_default_path" ]] && export PATH="$_nvm_default_path:$PATH"

  # Lazy-load nvm on first invocation.
  nvm() {
    unfunction nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if (( $+functions[nvm] )); then
      nvm "$@"
    else
      echo "nvm: failed to load from $NVM_DIR/nvm.sh" >&2
      return 1
    fi
  }
}
