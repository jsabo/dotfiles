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

# --- Shell completion ---------------------------------------------------------
# bash-completion v2 (brew install bash-completion@2) is the framework: it
# lazy-loads every script Homebrew drops into /opt/homebrew/etc/bash_completion.d
# (kubectl, kubectx, kubens, helm, git, gh, docker, aws, az, ...) on first Tab,
# so nothing below has to enumerate tools. Needs bash >= 4; the login shell is
# Homebrew's bash 5, the macOS /bin/bash 3.2 would silently get nothing.
[[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]] && . /opt/homebrew/etc/profile.d/bash_completion.sh

# Aliases are invisible to lazy loading (it keys on the command name), so the
# kubectl and kubectx scripts are loaded eagerly and their completion functions
# attached to the k and ctx aliases from .bashrc. `kubectl completion bash`
# would produce the same script; sourcing brew's copy avoids a fork per shell
# and tracks the kubectl version through brew upgrade.
if [[ -r /opt/homebrew/etc/bash_completion.d/kubectl ]]; then
  . /opt/homebrew/etc/bash_completion.d/kubectl
  complete -o default -F __start_kubectl k
fi
if [[ -r /opt/homebrew/etc/bash_completion.d/kubectx ]]; then
  . /opt/homebrew/etc/bash_completion.d/kubectx
  complete -F _kube_contexts ctx
fi

# Terraform ships its own completer binary rather than a script.
complete -C /opt/homebrew/bin/terraform terraform

# Teleport: tsh generates its completion script at runtime.
eval "$(tsh --completion-script-bash)" 2> /dev/null

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
. "$HOME/.cargo/env"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :
