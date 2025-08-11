\
    # --- nvm auto-use on cd (zsh) ---
    # Requires nvm to be installed and sourced in this shell.
    _nvm_auto_use() {
      command -v nvm >/dev/null 2>&1 || return
      [ "$PWD" = "${NVM_AUTO_LAST_PWD:-}" ] && return
      NVM_AUTO_LAST_PWD="$PWD"

      local toplevel
      toplevel="$(command git rev-parse --show-toplevel 2>/dev/null)" || return

      local dir="$PWD" nvmrc=""
      while [[ "$dir" == "$toplevel"* ]]; do
        if [ -f "$dir/.nvmrc" ]; then nvmrc="$dir/.nvmrc"; break; fi
        [ "$dir" = "$toplevel" ] && break
        dir="$(dirname "$dir")"
      done

      if [ -n "$nvmrc" ]; then
        local wanted resolved current
        wanted="$(<"$nvmrc")"
        wanted="${wanted#"${wanted%%[![:space:]]*}"}"; wanted="${wanted%"${wanted##*[![:space:]]}"}"
        resolved="$(nvm version "$wanted")"
        current="$(nvm version)"
        if [ "$resolved" = "N/A" ]; then
          nvm install "$wanted" >/dev/null || return
          resolved="$(nvm version "$wanted")"
        fi
        if [ "$resolved" != "$current" ]; then
          nvm use "$wanted" >/dev/null && echo "nvm use $(nvm current)  # from $(realpath --relative-to="$toplevel" "$nvmrc" 2>/dev/null || echo "$nvmrc")"
        fi
      fi
    }
    autoload -U add-zsh-hook 2>/dev/null
    if typeset -f add-zsh-hook >/dev/null; then
      add-zsh-hook chpwd _nvm_auto_use
    else
      typeset -ga chpwd_functions
      chpwd_functions+=(_nvm_auto_use)
    fi
    _nvm_auto_use
    # --- end nvm auto-use (zsh) ---
