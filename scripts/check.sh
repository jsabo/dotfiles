#!/usr/bin/env bash
# Offline checks; no shell startup file is installed or real tenant contacted.
set -euo pipefail
cd "$(dirname "$0")/.."
for file in .bash_profile .bashrc archive/colorprompt .config/bash/*.sh scripts/*.sh; do bash -n "$file"; done
shellcheck -s bash .bash_profile .bashrc .config/bash/*.sh scripts/*.sh
if command -v zsh >/dev/null 2>&1; then zsh -n archive/zshrc; else echo "Archived Zsh syntax check skipped (zsh unavailable)"; fi
python3 -m unittest discover -s tests -v
