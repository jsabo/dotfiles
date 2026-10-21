# Bash login shells share the same setup as non-login interactive shells.
# shellcheck disable=SC1091
if [ -r "$HOME/.bashrc" ]; then . "$HOME/.bashrc"; fi
