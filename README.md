# dotfiles

This repo contains my shell + terminal config (zsh, tmux, vim, Oh My Posh) managed with **GNU Stow**.

## What’s in here

- `~/.zshrc` – Zsh config (plugins via zinit) + Oh My Posh prompt
- `~/.config/ohmyposh/` – Oh My Posh themes (e.g. `zen.toml`, `sabo.toml`)
- `~/.config/tmux/tmux.conf` – tmux config (TPM + theme/plugins)
- `~/.vimrc` – Vim config
- `~/.bash_profile` – Bash login config (if needed)
- `.stow-local-ignore` – files Stow should ignore

## Install

### 1) Clone this repo into your home directory

```sh
cd ~
git clone <REPO_URL> dotfiles
cd dotfiles
````

### 2) Create symlinks with Stow

From inside the repo:

```sh
stow .
```

That will symlink the dotfiles into the right places under your home directory (e.g. `~/.zshrc`, `~/.config/tmux/tmux.conf`, etc).

## Updating / managing dotfiles

### See what would happen (dry run)

```sh
stow -n -v .
```

### Re-apply symlinks after changes

```sh
stow -R .
```

### Remove symlinks

```sh
stow -D .
```

## Notes

* After running `stow .`, start a new terminal session (or `source ~/.zshrc`) to apply changes.
* Oh My Posh theme files live in `~/.config/ohmyposh/`.
* tmux plugins are managed via TPM (see `~/.config/tmux/tmux.conf`). After launching tmux, install plugins with: `prefix + I` (capital i).

