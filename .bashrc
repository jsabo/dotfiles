# Interactive Bash only; do not change environments in scripted shells.
case $- in *i*) ;; *) return ;; esac
# shellcheck disable=SC1091
if [ -r "$HOME/.config/bash/init.sh" ]; then . "$HOME/.config/bash/init.sh"; fi
