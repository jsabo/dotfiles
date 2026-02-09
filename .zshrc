# --- Homebrew (macOS) ---------------------------------------------------------
# Silence Homebrew "cleanup" + "env hints" messages
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Zinit --------------------------------------------------------------------
if [[ -r "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/zinit/zinit.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/zinit/zinit.zsh"
else
  echo "zinit not found. Install with: brew install zinit"
fi

# --- Plugins ------------------------------------------------------------------
# Completions + autosuggestions + fzf-tab (must load before compinit)
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Oh-My-Zsh snippets (functions/completions/aliases)
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# --- Completion init ----------------------------------------------------------
autoload -Uz compinit
compinit
zinit cdreplay -q

# --- Keybindings --------------------------------------------------------------
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region


# --- History ------------------------------------------------------------------
HISTSIZE=1000000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# --- Completion styling -------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# fzf-tab previews (now active because fzf-tab is loaded)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- Aliases ------------------------------------------------------------------
alias ls='ls --color'
alias vi='vim'
alias c='clear'
alias k='kubectl'
alias ctx='kubectx'

# --- Shell integrations --------------------------------------------------------
# fzf
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# --- Prompt (Oh My Posh) ------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/sabo.toml")"
fi

