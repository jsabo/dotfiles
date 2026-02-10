# --- Homebrew (macOS) ---------------------------------------------------------
# Silence Homebrew "cleanup" + "env hints" messages
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# ---  (macOS) ---------------------------------------------------------
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
export EDITOR="vim"
export HISTIGNORE="&:ls:"
export HISTSIZE=""
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$HOME/bin:$PATH"
export EDITOR="vim"

# --- Aliases ------------------------------------------------------------------
[ -f ~/.bashrc ]        && source ~/.bashrc

# --- Prompt (Oh My Posh) ------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/sabo.toml")"
fi
