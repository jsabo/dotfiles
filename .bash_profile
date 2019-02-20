# User specific environment and startup programs
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
export EDITOR="vim"
export HISTIGNORE="&:ls:"
export HISTSIZE=""
export GOPATH="$HOME/Projects/go"
export PATH=$PATH:$GOPATH/bin:$HOME/bin

[ -f ~/.bashrc ]        && source ~/.bashrc
[ -f ~/.colorprompt ]   && source ~/.colorprompt

eval "$(pyenv init -)"
