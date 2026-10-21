# shellcheck shell=bash
# Idempotent interactive setup shared by login and non-login Bash.
[ "${DOTFILES_BASH_INITIALIZED:-}" != 1 ] || return 0
DOTFILES_BASH_INITIALIZED=1
export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1
export EDITOR="${EDITOR:-vim}"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
HISTIGNORE='&:ls:'
shopt -s histappend
export GOPATH="${GOPATH:-$HOME/go}"

_dotfiles_prepend_path() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
}
# Homebrew can be installed at either macOS prefix.
if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix)"
elif [ -x /opt/homebrew/bin/brew ]; then
  HOMEBREW_PREFIX=/opt/homebrew
elif [ -x /usr/local/bin/brew ]; then
  HOMEBREW_PREFIX=/usr/local
fi
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  export HOMEBREW_PREFIX
  _dotfiles_prepend_path "$HOMEBREW_PREFIX/bin"
  _dotfiles_prepend_path "$HOMEBREW_PREFIX/opt/postgresql@17/bin"
  _dotfiles_prepend_path "$HOMEBREW_PREFIX/opt/mysql-client/bin"
fi
for _dotfiles_dir in "$GOPATH/bin" "$HOME/bin" "$HOME/.local/bin" "$HOME/.cmux/bin"; do
  _dotfiles_prepend_path "$_dotfiles_dir"
done
unset _dotfiles_dir
export PATH
unset -f _dotfiles_prepend_path

# shellcheck disable=SC1091
if [ -r "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env"; fi
# shellcheck disable=SC1091
if [ -r "$HOME/.orbstack/shell/init.bash" ]; then . "$HOME/.orbstack/shell/init.bash"; fi

if command -v gls >/dev/null 2>&1; then alias ls='gls --color=auto'
elif [ "$(uname -s)" = Darwin ]; then alias ls='ls -G'
else alias ls='ls --color=auto'; fi
alias vi=vim c=clear k=kubectl ctx=kubectx

# shellcheck disable=SC1091
. "$HOME/.config/bash/teleport.sh"

if [ "${BASH_VERSINFO[0]}" -ge 4 ] && [ -n "${HOMEBREW_PREFIX:-}" ]; then
  if [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
  fi
  if [ -r "$HOMEBREW_PREFIX/etc/bash_completion.d/kubectl" ]; then
    # shellcheck disable=SC1091
    . "$HOMEBREW_PREFIX/etc/bash_completion.d/kubectl"
    declare -F __start_kubectl >/dev/null && complete -o default -F __start_kubectl k
  fi
  if [ -r "$HOMEBREW_PREFIX/etc/bash_completion.d/kubectx" ]; then
    # shellcheck disable=SC1091
    . "$HOMEBREW_PREFIX/etc/bash_completion.d/kubectx"
    declare -F _kube_contexts >/dev/null && complete -F _kube_contexts ctx
  fi
fi
if command -v terraform >/dev/null 2>&1; then complete -C "$(command -v terraform)" terraform; fi
if command -v tsh >/dev/null 2>&1; then
  if _dotfiles_completion="$(tsh --completion-script-bash)"; then eval "$_dotfiles_completion"; fi
  unset _dotfiles_completion
fi
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/sabo.toml")"
fi
