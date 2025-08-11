#!/usr/bin/env bash
set -euo pipefail

info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" ; }

append_once() {
  local file="$1"; shift
  local line="$*"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" || printf "%s\n" "$line" >> "$file"
}

shell_rc_file() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/zsh}")"
  case "$shell_name" in
    zsh)  echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
    bash) echo "$HOME/.bash_profile" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *)    echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
  esac
}

ensure_xcode_clt() {
  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools not found. Triggering installation (GUI)."
    xcode-select --install || true
    echo "Please complete the Command Line Tools installation, then re-run this script."
    exit 1
  fi
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    info "Homebrew already installed."
  fi

  BREW_PREFIX="$(brew --prefix)"
  info "Homebrew prefix: $BREW_PREFIX"

  local profile
  profile="$(shell_rc_file)"
  if [ -d "/opt/homebrew/bin" ]; then
    append_once "$profile" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  fi
  if [ -d "/usr/local/bin" ]; then
    append_once "$profile" 'eval "$(/usr/local/bin/brew shellenv)"'
  fi

  append_once "$HOME/.profile" 'command -v brew >/dev/null 2>&1 && eval "$($(command -v brew) shellenv)"'
}

install_gnu_tools() {
  info "Installing GNU userland via Homebrew…"
  local formulas=(
    coreutils
    findutils
    gnu-sed
    gnu-tar
    gawk
    grep
    make
    diffutils
    gnu-indent
    gnu-getopt
    bash
    wget
    moreutils
  )
  brew update
  brew install "${formulas[@]}" || true
}

write_gnubin_env() {
  local env_file="$HOME/.gnu-paths.sh"
  info "Writing GNU path shim to $env_file"

  cat > "$env_file" <<'EOF'
# --- BEGIN GNU PATHS (managed by bootstrap-gnu.sh) ---
if command -v brew >/dev/null 2>&1; then
  _GNU_DIRS=""
  _GNMAN_DIRS=""

  add_gnubin()  { [ -d "$1" ] && _GNU_DIRS="${_GNU_DIRS:+$_GNU_DIRS:}$1"; }
  add_gnuman()  { [ -d "$1" ] && _GNMAN_DIRS="${_GNMAN_DIRS:+$_GNMAN_DIRS:}$1"; }

  add_gnubin  "$(brew --prefix coreutils)/libexec/gnubin"
  add_gnuman  "$(brew --prefix coreutils)/libexec/gnuman"

  add_gnubin  "$(brew --prefix findutils)/libexec/gnubin"
  add_gnuman  "$(brew --prefix findutils)/libexec/gnuman"

  add_gnubin  "$(brew --prefix gnu-sed)/libexec/gnubin"
  add_gnuman  "$(brew --prefix gnu-sed)/libexec/gnuman"

  add_gnubin  "$(brew --prefix gnu-tar)/libexec/gnubin"
  add_gnuman  "$(brew --prefix gnu-tar)/libexec/gnuman"

  add_gnubin  "$(brew --prefix gawk)/libexec/gnubin"
  add_gnuman  "$(brew --prefix gawk)/libexec/gnuman"

  add_gnubin  "$(brew --prefix grep)/libexec/gnubin"
  add_gnuman  "$(brew --prefix grep)/libexec/gnuman"

  add_gnubin  "$(brew --prefix make)/libexec/gnubin"
  add_gnuman  "$(brew --prefix make)/libexec/gnuman"

  add_gnubin  "$(brew --prefix diffutils)/libexec/gnubin"
  add_gnuman  "$(brew --prefix diffutils)/libexec/gnuman"

  add_gnubin  "$(brew --prefix gnu-indent)/libexec/gnubin"
  add_gnuman  "$(brew --prefix gnu-indent)/libexec/gnuman"

  add_gnubin  "$(brew --prefix gnu-getopt)/libexec/gnubin"
  add_gnuman  "$(brew --prefix gnu-getopt)/libexec/gnuman"

  case ":$PATH:" in
    *":$_GNU_DIRS:"*) : ;;
    *) PATH="$_GNU_DIRS${PATH:+:$PATH}" ;;
  esac

  if [ -n "${MANPATH:-}" ]; then
    case ":$MANPATH:" in
      *":$_GNMAN_DIRS:"*) : ;;
      *) MANPATH="$_GNMAN_DIRS${MANPATH:+:$MANPATH}" ;;
    esac
  else
    MANPATH="$_GNMAN_DIRS:"
  fi

  export PATH MANPATH
  unset _GNU_DIRS _GNMAN_DIRS
fi
# --- END GNU PATHS ---
EOF
}

wire_shell_startup() {
  local rc
  rc="$(shell_rc_file)"
  info "Wiring shell startup in $rc"
  append_once "$rc" '[ -f "$HOME/.gnu-paths.sh" ] && . "$HOME/.gnu-paths.sh"'

  append_once "$HOME/.profile" '[ -f "$HOME/.gnu-paths.sh" ] && . "$HOME/.gnu-paths.sh"'

  if [ -d "$HOME/.config/fish" ]; then
    local fish_config="$HOME/.config/fish/config.fish"
    append_once "$fish_config" 'test -f ~/.gnu-paths.sh; and bash -lc ". ~/.gnu-paths.sh; env" | sed -n '\''s/^PATH=\(.*\)$/set -x PATH \1/p'\'' | tr ":" "\n" | while read -l p; set -x PATH $p $PATH; end'
  fi
}

install_nvm_and_node() {
  if [ ! -d "$HOME/.nvm" ]; then
    info "Installing NVM…"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  else
    info "NVM already installed."
  fi

  local rc
  rc="$(shell_rc_file)"
  append_once "$rc" 'export NVM_DIR="$HOME/.nvm"'
  append_once "$rc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm'
  append_once "$rc" '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'

  append_once "$HOME/.profile" 'export NVM_DIR="$HOME/.nvm"'
  append_once "$HOME/.profile" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

  . "$HOME/.nvm/nvm.sh"

  info "Installing Node LTS (default) and latest…"
  nvm install --lts
  nvm alias default 'lts/*'
  nvm install node || true
}

main() {
  ensure_xcode_clt
  install_homebrew
  install_gnu_tools
  write_gnubin_env
  wire_shell_startup
  install_nvm_and_node

  info "Done. Open a NEW terminal, then run:"
  echo
  echo "    make --version      # should show GNU Make"
  echo "    sed --version       # should show GNU sed"
  echo "    tar --version       # should show GNU tar"
  echo "    node -v             # should show Node LTS by default"
  echo
  info "If any command still shows BSD versions, confirm your shell sourced ~/.gnu-paths.sh"
}

main "$@"
