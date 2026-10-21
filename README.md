# dotfiles

**A coordinated macOS terminal setup for Ghostty, herdr, and everyday infrastructure work.**

[![checks](https://github.com/jsabo/dotfiles/actions/workflows/checks.yml/badge.svg)](https://github.com/jsabo/dotfiles/actions/workflows/checks.yml)
[![MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

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
| [.bash_profile](.bash_profile) | Login-shell entry point; delegates to `.bashrc`. |
| [.bashrc](.bashrc) | Interactive-shell entry point, shared by login and non-login Bash. |
| [Bash initialization](.config/bash/init.sh) | Guarded dependencies, deduplicated PATH, history, aliases, completion and Oh My Posh. |
| [Teleport helpers](.config/bash/teleport.sh) | Persona, Connect, login, access-request and MCP wrapper functions. |
| [MCP client](.config/bash/mcp_call.py) | One stdio MCP tool call through tsh with a handshake and bounded response wait. |
| [Archived Zsh](archive/zshrc) | Legacy reference, excluded from Stow. |
| [Archived prompt](archive/colorprompt) | Old Bash prompt, excluded from Stow. |
| [Ghostty config](.config/ghostty/config) | Font, window spacing, dark palette, selection, cursor and splits. |
| [herdr config](.config/herdr/config.toml) | Matching UI, agent sidebar, notifications, tab status and Beams shortcuts. |
| [sabo.toml](.config/ohmyposh/sabo.toml) | Active Oh My Posh theme with Teleport persona and Git status. |
| [zen.toml](.config/ohmyposh/zen.toml) | Alternative Oh My Posh theme with exit-status coloring. |
| [tmux.conf](.config/tmux/tmux.conf) | Ctrl+Space prefix, pane navigation, copy mode and TPM plugins. |
| [.vimrc](.vimrc) | Vim preferences, optional NERDTree, buffer-local Makefile indentation and code-only whitespace cleanup. |
| [.stow-local-ignore](.stow-local-ignore) | Excludes repository metadata, documentation, archives, tests and development files from linking. |

## Requirements

Install Git and GNU Stow before linking. Install the applications for the
components you intend to use:

| Component | Dependencies and assumptions |
| --- | --- |
| Bash | Homebrew Bash 4+ recommended, with optional `bash-completion@2`; missing integrations are skipped. |
| Prompt | `oh-my-posh`; both shell configs use `sabo.toml`. |
| Ghostty | Ghostty and the configured **MesloLGM Nerd Font Mono** font. |
| herdr | herdr; Beams shortcuts additionally require the herdr-beams plugin and a configured Teleport Beams tenant. |
| tmux | tmux and TPM; the plugin manager is not included in this repository. |
| Vim | Vim; vim-plug/NERDTree are optional and installed explicitly. |
| Teleport helpers | `tsh`; `tconnect` additionally requires `jq`, and `mcp_call` requires Python 3. |
| Optional Bash integrations | OrbStack, PostgreSQL/MySQL clients, and Teleport Connect as needed. |

Application installation, login-shell selection, tenant enrollment, and plugin
configuration are separate from Stow. Linking files does not install dependencies.
The [Brewfile](Brewfile) installs the active Bash/Ghostty/Oh My Posh toolchain:

```sh
brew bundle --file=Brewfile
```

Herdr, tsh, Terraform, Connect and optional editor/database tools are installed
separately. Zinit, fzf and zoxide are only referenced by the excluded Zsh archive.

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
  `.bash_profile`, which sources `.bashrc`; both login and non-login interactive
  shells load `.config/bash/init.sh` and initialize Oh My Posh with `sabo.toml`.
- Install TPM if using tmux:

  ```sh
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  git -C "$HOME/.tmux/plugins/tpm" checkout e261deb1b47614eed3400089ce7197dc68acc4eb
  ```

  Skip the clone if TPM is already installed. Plugin revisions are pinned in
  `tmux.conf`; update pins deliberately after testing. Existing plugin checkouts
  need their corresponding pinned revisions checked out explicitly. Start tmux, then press its prefix
  (**Ctrl+Space**), release it, and press **Shift+I** to install the listed plugins.
- Vim works without plugins. To use NERDTree, install
  [vim-plug](https://github.com/junegunn/vim-plug#installation), restart Vim, and
  run `:PlugInstall`. Opening the editor never downloads plugins automatically.
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

These helpers live in `.config/bash/teleport.sh`. Shell startup preserves inherited
persona variables; use `tnone` to clear them explicitly. `tcloud` and `tself` succeed
even when no persona is selected.

`tconnect` preserves existing application preferences, updates only `tshHome`, and
creates defaults only for missing settings. Invalid JSON is left unchanged.
The helper selection is kept in `DOTFILES_TELEPORT_CLUSTER`, leaving tsh's native
`TELEPORT_CLUSTER` variable unchanged. Self-hosted personas use separate `~/.connect-<persona>-sh` application data.
`TELEPORT_CONNECT_BIN` can select an alternate Connect executable.

`mcp_call` validates JSON arguments, waits for initialization before sending the
tool request, prints the structured result, and retains transport errors. It
supports MCP stdio protocol `2025-03-26`. `MCP_CALL_WAIT` sets the total timeout in
seconds (default 30); timeouts, protocol errors and tool errors return nonzero.
MCP tool calls can change remote resources; choose tools and arguments deliberately.

## Update and reload

```sh
cd "$HOME/dotfiles"
git pull --ff-only
python3 scripts/remove-legacy-links.py
stow --no-folding --target="$HOME" --restow .
```

Use your actual checkout path if different. Existing symlinks pick up edits to
tracked files immediately; restowing also handles files added or removed.

| Component | Apply changes |
| --- | --- |
| Bash | Open a new shell. Initialization runs once per shell, preserving PATH and personas. |
| herdr | Run `herdr server reload-config`. |
| Ghostty | Use **Cmd+Shift+,** on macOS to reload configuration; some settings apply only to new windows. |
| tmux | Run `tmux source-file "$HOME/.config/tmux/tmux.conf"`. |
| Vim | Restart Vim or run `:source $MYVIMRC`; autocommands are grouped and replaced on reload. |
| Oh My Posh | Open a new shell after editing the selected theme. |

Ghostty documents reload behavior in its [configuration guide](https://ghostty.org/docs/config).

To remove the managed symlinks:

```sh
stow --no-folding --target="$HOME" --delete .
```

Unstowing leaves the checkout and application-generated state in place. Restore
previous configuration from your backups if needed.

## Shell startup

The login chain is **Ghostty → Bash → `.bash_profile` → `.bashrc` → `.config/bash/init.sh`**.
Non-login interactive shells enter at `.bashrc` and get the same prompt and helpers.
Initialization runs once per shell; open a new shell after changing it.

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

The old `.zshrc` and `.colorprompt` are archived under `archive/` and excluded from
Stow. Run `python3 scripts/remove-legacy-links.py` once before restowing to remove
only obsolete links into this checkout. Independent files and unrelated symlinks
remain untouched; Stow alone does not remove links to files moved into the archive. The Zsh-only fzf/zoxide integrations are not enabled for Bash.

## Personalization

- **Platform paths:** Bash discovers Homebrew from PATH or the Apple Silicon/Intel
  prefixes. Ghostty UI settings and Connect application paths remain macOS-specific.
- **Teleport:** adapt the cluster, persona, browser-profile, and SSO connector
  mappings in `.config/bash/teleport.sh`. Keep credentials and generated identity files outside Git.
- **Prompt:** change the Oh My Posh theme path in the shell config to use `zen.toml`.
- **Editor behavior:** `.vimrc` trims whitespace only for the listed code filetypes
  (shell, Python, Go, JSON and TOML). Markdown and other formats are preserved.
- **Color aliases:** Bash prefers GNU `gls` when installed, uses `ls -G` on macOS,
  and uses GNU-style `ls --color=auto` elsewhere.
- **Repository-only files:** the local Stow ignore file replaces the default ignore
  list. Extend it before adding documentation, CI, or other files you do not want
  linked into your home directory. See [Stow ignore rules](https://www.gnu.org/software/stow/manual/html_node/Types-And-Syntax-Of-Ignore-Lists.html).

## Validation and maintenance

```sh
scripts/check.sh
scripts/doctor.sh
```

Checks require Bash, ShellCheck, Python 3.11+, jq and GNU Stow. CI also installs Vim
and Zsh to exercise editor behavior and check archived Zsh syntax. The tests use
isolated homes and fake tsh/Connect processes; they never log in or call real MCP
tools. `doctor.sh` reports tool versions without changing configuration.

Use `oh-my-posh debug --config "$HOME/.config/ohmyposh/sabo.toml"` on a large working
repository before reducing Git prompt detail. Verify actual `beamctl list` output
and Herdr remote polling costs before changing the tab-bar count or interval.
The palette, service counter, and prompt detail remain unchanged pending those
measurements.

Licensed under [MIT](LICENSE). Third-party applications and plugins retain their
own licenses; they are installed separately.
