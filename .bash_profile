# User specific environment and startup programs
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
export EDITOR="vim"
export HISTIGNORE="&:ls:"
export HISTSIZE=""
export GOPATH="$HOME/Source/go"
export PATH="/usr/local/opt/python/libexec/bin:$GOPATH/bin:$HOME/bin:$PATH"

[ -f ~/.bashrc ]        && source ~/.bashrc
[ -f ~/.colorprompt ]   && source ~/.colorprompt
