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
export PATH="$GOPATH/bin:$HOME/bin:/opt/homebrew/bin:$PATH"
export EDITOR="vim"

# --- Aliases ------------------------------------------------------------------
[ -f ~/.bashrc ]        && source ~/.bashrc

# --- Prompt (Oh My Posh) ------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/sabo.toml")"
fi

# Terraform completion
complete -C /opt/homebrew/bin/terraform terraform

# Teleport bash completion
eval "$(tsh --completion-script-bash)" 2> /dev/null

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
