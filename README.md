# dotfiles

This repo contains my shell + terminal config (bash, zsh, Ghostty, herdr, tmux, vim, Oh My Posh) managed with **GNU Stow**.

## What’s in here

- `~/.bashrc`, `~/.bash_profile` – Bash config (completion, Teleport persona helpers, PATH) + Oh My Posh prompt
- `~/.zshrc` – Zsh config (plugins via zinit) + Oh My Posh prompt
- `~/.colorprompt` – ANSI color variables for a hand-built PS1; not sourced by the current shell configs, kept for reference
- `~/.config/ohmyposh/` – Oh My Posh themes (`sabo.toml` is the active one, `zen.toml` an alternative)
- `~/.config/ghostty/config` – Ghostty terminal config (font, window, custom color palette)
- `~/.config/herdr/config.toml` – herdr theme overrides matching the Ghostty palette, sidebar rows (agent state word, Claude activity title), tab-bar status (hostname, beam-init service count, clock) and macOS notifications
- `~/.config/tmux/tmux.conf` – tmux config (TPM + theme/plugins)
- `~/.vimrc` – Vim config
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
stow --no-folding .
```

That will symlink the dotfiles into the right places under your home directory (e.g. `~/.zshrc`, `~/.config/tmux/tmux.conf`, etc).

`--no-folding` links individual files instead of whole directories. That matters for `~/.config/herdr/`: herdr keeps its sockets, logs and `session.json` next to `config.toml`, and a folded directory symlink would drop that runtime state into this repo.

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

## Herdr Beams shortcuts

Requires the [herdr-beams plugin](https://github.com/jsabo/herdr-beams):

```sh
herdr plugin install jsabo/herdr-beams
```

| Shortcut | Action |
| --- | --- |
| `prefix+shift+b` | Create a Beam |
| `prefix+a` | Choose an agent profile |
| `prefix+shift+c` | Launch the configured Claude profile |
| `prefix+shift+o` | Launch the configured Codex profile |
| `prefix+s` | Show Beam status |
| `prefix+d` | Remove a Beam |
| `prefix+shift+q` | Remove every Beam |

The default prefix is **Ctrl+B**, released before the next key.
Select **Local** in the sidebar before invoking plugin bindings.
The picker supports Claude Code and Codex profiles; bundled model IDs may need
overrides to match the tenant's inference proxy. Configure direct-launch defaults
with `BEAM_CLAUDE_PROFILE` and `BEAM_CODEX_PROFILE` in the plugin's `env` file.

After pulling these dotfiles (and applying the Stow links if needed), reload Herdr:

```sh
herdr server reload-config
```

Plugin actions skip creation/deletion confirmations by default. Set `BEAMS_YES=0`
in the plugin's `env` file to restore interactive confirmations. The profile
bindings still ask for the workspace label and prompt.

## Notes

* After running `stow .`, start a new terminal session (or `source ~/.zshrc`) to apply changes.
* Oh My Posh theme files live in `~/.config/ohmyposh/`.
* tmux plugins are managed via TPM (see `~/.config/tmux/tmux.conf`). After launching tmux, install plugins with: `prefix + I` (capital i).

