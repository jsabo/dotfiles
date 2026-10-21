#!/usr/bin/env bash
# Report installed versions; does not source personal shell files or contact tenants.
for tool in bash ghostty herdr oh-my-posh tsh tmux vim stow jq python3; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '\n%s: %s\n' "$tool" "$(command -v "$tool")"
    case "$tool" in
      tmux) "$tool" -V ;;
      tsh) "$tool" version ;;
      *) "$tool" --version 2>&1 | head -3 ;;
    esac
  else
    printf '\n%s: not installed\n' "$tool"
  fi
done
# shellcheck disable=SC2016
printf '\nFor prompt timing, run: oh-my-posh debug --config "$HOME/.config/ohmyposh/sabo.toml"\n'
printf 'Measure Herdr remote tab status before changing its polling interval.\n'
