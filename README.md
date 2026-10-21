# dotfiles

**A coordinated macOS terminal setup for Ghostty, herdr, and everyday infrastructure work.**

Personal Bash configuration, matching Ghostty and Oh My Posh colors, Teleport
persona helpers, and agent workspaces with [herdr](https://herdr.dev) and
[Teleport Beams](https://beams.run). Files are linked into place with
[GNU Stow](https://www.gnu.org/software/stow/).

[Setup](#setup) · [Files](#files) · [Shortcuts](#herdr-beams-shortcuts) ·
[Update and reload](#update-and-reload) · [Personalization](#personalization)

These are personal dotfiles, primarily for Apple Silicon macOS with Homebrew in
`/opt/homebrew`. Review the files before linking them: shell startup, aliases,
Teleport demo environments, and editor save behavior reflect this setup.

## What this setup provides

- **Consistent appearance:** a dark Ghostty palette, matching herdr sidebar, and
  an Oh My Posh prompt with path, Git status, and the selected Teleport persona.
- **Agent workspaces:** Beams creation, profile selection, Claude/Codex launches,
  status, and teardown through herdr keybindings.
- **Infrastructure helpers:** Bash functions for Teleport personas, cluster
  selection, login, Connect windows, access-request discovery, and MCP demos.
- **Bash workflow:** login-shell setup, completion, aliases, and an Oh My Posh
  prompt. Additional tmux, Vim, and legacy Zsh configurations are retained.

## Files

| File | Purpose |
| --- | --- |
| [.bash_profile](.bash_profile) | Bash login setup: PATH, prompt, completion, database clients, Cargo and OrbStack integration. |
| [.bashrc](.bashrc) | Bash aliases and Teleport persona, Connect, access-request and MCP helpers. |
| [.zshrc](.zshrc) | Legacy Zsh setup; not part of the current Bash workflow. |
| [.colorprompt](.colorprompt) | Legacy Bash prompt, retained for reference; not sourced by the active shell configs. |
| [Ghostty config](.config/ghostty/config) | Font, window spacing, dark palette, selection, cursor and splits. |
| [herdr config](.config/herdr/config.toml) | Matching UI, agent sidebar, notifications, tab status and Beams shortcuts. |
| [sabo.toml](.config/ohmyposh/sabo.toml) | Active Oh My Posh theme with Teleport persona and Git status. |
| [zen.toml](.config/ohmyposh/zen.toml) | Alternative Oh My Posh theme with exit-status coloring. |
| [tmux.conf](.config/tmux/tmux.conf) | Ctrl+Space prefix, pane navigation, copy mode and TPM plugins. |
| [.vimrc](.vimrc) | Vim preferences, vim-plug/NERDTree, Makefile indentation and whitespace cleanup. |
| [.stow-local-ignore](.stow-local-ignore) | Excludes Git metadata and this README from linking. |

## Requirements

Install Git and GNU Stow before linking. Install the applications for the
components you intend to use:

| Component | Dependencies and assumptions |
| --- | --- |
| Bash | Homebrew Bash 4+, `bash-completion@2`; login setup also invokes `tsh`, registers Terraform completion, and sources Cargo's environment. |
| Prompt | `oh-my-posh`; both shell configs use `sabo.toml`. |
| Ghostty | Ghostty and the configured **MesloLGM Nerd Font Mono** font. |
| herdr | herdr; Beams shortcuts additionally require the herdr-beams plugin and a configured Teleport Beams tenant. |
| tmux | tmux and TPM; the plugin manager is not included in this repository. |
| Vim | Vim and `curl`; the current config bootstraps vim-plug and installs NERDTree. |
| Optional Bash integrations | OrbStack, PostgreSQL/MySQL clients, and Teleport Connect as needed. |

Application installation, login-shell selection, tenant enrollment, and plugin
configuration are separate from Stow. Linking files does not install dependencies.
Zinit, fzf, and zoxide are only referenced by the retained Zsh setup; they are not
required by the current Bash configuration.

## Setup

### 1. Clone

```sh
cd "$HOME"
git clone https://github.com/jsabo/dotfiles.git dotfiles
cd dotfiles
```

If you already have a checkout, use it rather than cloning again. Commands below
assume you are running from the repository root; `--target` explicitly selects
your home directory even when the checkout lives elsewhere.

### 2. Review and back up existing configuration

Inspect the files you plan to use and keep a backup of any existing destination
files. Stow reports conflicts with files it does not manage. Resolve those
conflicts individually; avoid `--adopt` unless you intend to import the destination
files into this checkout.

### 3. Preview, then link

```sh
stow --no-folding --target="$HOME" --simulate --verbose .
stow --no-folding --target="$HOME" .
```

`--no-folding` creates file-level symlinks instead of linking entire directories.
This keeps herdr's logs, sockets, plugin settings, and other generated state outside
the checkout. Keep this option when restowing too.

### 4. Initialize the applications you use

- Open a new Bash login shell after installing its dependencies. It reads
  `.bash_profile`, which sources `.bashrc` and initializes Oh My Posh with
  `~/.config/ohmyposh/sabo.toml`. The legacy `.zshrc` is not loaded by Bash.
- Install TPM if using tmux:

  ```sh
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ```

  Skip the clone if TPM is already installed. Start tmux, then press its prefix
  (**Ctrl+Space**), release it, and press **Shift+I** to install the listed plugins.
- On first Vim startup, the current config downloads vim-plug if missing and runs
  plugin installation. A network connection is required for that bootstrap.
- Install and configure the Beams plugin before using its herdr actions; see below.

## Herdr Beams shortcuts

Install [herdr-beams](https://github.com/jsabo/herdr-beams) and follow its
[setup instructions](https://github.com/jsabo/herdr-beams#requirements) for tenant
login, SSH configuration, and the plugin's `env` file:

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

The herdr prefix is **Ctrl+B**, released before the next key. Select **Local** in
the sidebar before invoking plugin bindings. The tmux prefix is **Ctrl+Space**.

The profile picker currently supports Claude Code and Codex. Bundled model IDs may
need overrides to match your tenant's inference proxy. Configure direct-launch
defaults with `BEAM_CLAUDE_PROFILE` and `BEAM_CODEX_PROFILE` in the plugin's `env` file.
Beams can run other installed harnesses, including Pi, from a shell in the runtime.

Plugin actions skip creation/deletion confirmations by default. Set `BEAMS_YES=0`
in the plugin's `env` file to restore interactive confirmations. Workspace labels
and prompts are still collected interactively.

## Teleport helpers

The Bash configuration contains personal demo environments and persona mappings.
Adapt these before using them with another account or tenant.

| Helper | Purpose |
| --- | --- |
| `tcloud` / `tself` | Select the configured cloud or self-hosted demo cluster. |
| `teleport_demo_user <persona>` | Select a configured persona and its separate `tsh` home. |
| `tnone` | Clear the persona environment. |
| `tlogin` / `tlogout` | Log the selected persona in or out. |
| `twho` / `tstatus` | Show persona information or Teleport status. |
| `tconnect [persona]` | Open Teleport Connect with persona-specific application data. |
| `treq` | List requestable roles and resources. |
| `mcp_call <app> <tool> [json-args]` | Make a demo MCP tool call through Teleport. |

These helpers live in `.bashrc` and are loaded by the Bash login setup.
Starting or sourcing `.bashrc` clears inherited Teleport persona variables.
`tconnect` rewrites the persona's Connect application configuration, so preserve
any custom settings before using it. MCP tool calls can change remote resources;
choose the tool and arguments deliberately.

## Update and reload

```sh
cd "$HOME/dotfiles"
git pull --ff-only
stow --no-folding --target="$HOME" --restow .
```

Use your actual checkout path if different. Existing symlinks pick up edits to
tracked files immediately; restowing also handles files added or removed.

| Component | Apply changes |
| --- | --- |
| Bash | Open a new login shell; this avoids repeatedly prepending PATH entries or resetting a live persona by re-sourcing. |
| herdr | Run `herdr server reload-config`. |
| Ghostty | Use **Cmd+Shift+,** on macOS to reload configuration; some settings apply only to new windows. |
| tmux | Run `tmux source-file "$HOME/.config/tmux/tmux.conf"`. |
| Vim | Restart Vim; repeatedly sourcing the current config can duplicate autocommands. |
| Oh My Posh | Open a new shell after editing the selected theme. |

Ghostty documents reload behavior in its [configuration guide](https://ghostty.org/docs/config).

To remove the managed symlinks:

```sh
stow --no-folding --target="$HOME" --delete .
```

Unstowing leaves the checkout and application-generated state in place. Restore
previous configuration from your backups if needed.

## Shell startup

The intended startup chain is **Ghostty → Bash login shell → `.bash_profile` → `.bashrc`**,
with Oh My Posh initialized from `.bash_profile` using `sabo.toml`.

Ghostty's config does not set an explicit shell command. Herdr also leaves
`default_shell` empty with `shell_mode = "auto"`. The actual shell therefore
still depends on the machine's shell selection; these files do not change it.
Confirm from a terminal with:

```sh
printf 'Bash: %s\nLogin shell: %s\n' "$BASH_VERSION" "$SHELL"
ps -p $$ -o comm=
```

A nonempty `BASH_VERSION` confirms the current shell is Bash; `$SHELL` describes
the configured login shell and can differ from the current process.

`.zshrc` and `.colorprompt` are retained as legacy references. Stowing the whole
repository still links them, but the Bash startup files do not source either one.
The Zsh-only fzf/zoxide integrations are not currently enabled for Bash.

## Personalization

- **Platform paths:** replace `/opt/homebrew` assumptions for Intel macOS or Linux.
  The current configs also contain macOS-specific application paths and UI options.
- **Teleport:** adapt the cluster, persona, browser-profile, and SSO connector
  mappings in `.bashrc`. Keep credentials and generated identity files outside Git.
- **Prompt:** change the Oh My Posh theme path in the shell config to use `zen.toml`.
- **Editor behavior:** `.vimrc` strips trailing whitespace from every buffer on save;
  review that preference before editing Markdown or whitespace-sensitive files.
- **Color aliases:** Bash currently uses `ls --color`; verify your installed
  `ls` supports it or adapt the alias for your platform.
- **Repository-only files:** the local Stow ignore file replaces the default ignore
  list. Extend it before adding documentation, CI, or other files you do not want
  linked into your home directory. See [Stow ignore rules](https://www.gnu.org/software/stow/manual/html_node/Types-And-Syntax-Of-Ignore-Lists.html).
