# .dotfiles

Personal dotfiles managed via [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./ubuntu        # on Ubuntu / WSL2
./macos         # on macOS
```

On Windows (after running `./ubuntu` in WSL), install the Windows-side configs by running PowerShell **from Windows** against the WSL-hosted repo:

```powershell
cd \\wsl.localhost\Ubuntu\home\<user>\.dotfiles
.\windows.ps1
```

If PowerShell refuses to run the script, allow scripts for the current user once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

By default this stows `zsh,git,wezterm,bin,codex`. To override, set `STOW_FOLDERS` (comma-separated):

```bash
STOW_FOLDERS=zsh,nvim,tmux ./ubuntu
```

To remove all symlinks: `./ubuntu --clean` (or `./macos --clean`).

## Optional private and local Zsh configuration

The public Zsh configuration supports two additive layers, loaded after the
main `.zshrc`:

1. `~/.config/zsh/roblox.zsh` for private, Git-synchronized Roblox settings.
2. `~/.zshrc.local` for unsynchronized settings specific to one machine.

The private Roblox configuration lives in the optional `roblox` submodule. On
an authorized work machine, initialize it and rerun the platform installer:

```bash
cd ~/.dotfiles
git submodule update --init roblox
./ubuntu # or ./macos
```

When initialized, the installer automatically includes `roblox` as a Stow
package. The private repository can provide `.config/zsh/roblox.zsh`; when the
submodule or that file is absent, startup continues normally. Personal machines
can leave the submodule uninitialized.

For settings that should never be synchronized, create `~/.zshrc.local`. This
file lives outside the dotfiles repository and is loaded last, so it can add to
or override both public and Roblox configuration.

## Codex configuration

The `codex` Stow package installs the tracked user configuration directly at
`~/.codex/config.toml`. Codex loads this file automatically, so no shell alias
or named profile is required.

This single file synchronizes defaults, writable roots, trusted projects, MCP
servers, and UI settings across machines. Machine- or project-specific
exceptions can still use a trusted repository's `.codex/config.toml` or CLI
overrides.

## Manual steps after install

These don't fit cleanly into the install scripts — run once per machine:

- **`gh auth login`** — authenticate the GitHub CLI (browser flow).
- **SSH key for GitHub** — generate and register a key so you can clone/push via SSH:
  ```bash
  ssh-keygen -t ed25519 -C "niziolek.paul@gmail.com"
  gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
  ```
  Requires `gh auth login` to have run first. Skip entirely if you only clone via HTTPS.
- **`rclone config`** — set up a remote named `gdrive` (Google Drive) if you use `gdoc`. Also drop `md2gdoc-template.docx` at `~/bin/md2gdoc-template.docx` — it's the pandoc reference doc for styling.

## WezTerm on Windows + WSL

WezTerm runs as a Windows GUI app, so it reads its config from Windows and renders fonts from Windows — but the dotfiles live in WSL. `windows.ps1` copies the config into `%USERPROFILE%\.config\wezterm\` so the GUI host can read it without depending on WSL being up. Re-run after editing `wezterm.lua` in the repo.

Two config gotchas, since the same `wezterm.lua` is shared across macOS/Linux/Windows:

- **Default to WSL on Windows only** — guard with `wezterm.target_triple:find("windows")` before setting `config.default_domain = "WSL:Ubuntu"` (run `wsl -l -v` to confirm the distro name).
- **Install fonts on Windows** — the GUI host renders fonts, so `JetBrainsMono Nerd Font` must be installed on Windows even if WezTerm launches into WSL:

  ```powershell
  winget install DEVCOM.JetBrainsMonoNerdFont
  ```

## Layout

- `ubuntu` — Ubuntu bootstrap: apt prereqs + Homebrew install + dispatch to `install`.
- `macos` — macOS bootstrap: Xcode CLI tools + Homebrew install + system `defaults` (keyboard, Dock, Finder, screenshots, disable Spotlight ⌘Space) + dispatch to `install`.
- `windows.ps1` — Windows bootstrap: copies Windows-side configs (currently just `wezterm.lua`) into `%USERPROFILE%`.
- `install`, `clean-env` — symlink / unlink each folder in `$STOW_FOLDERS` via `stow`.
- `Brewfile` — cross-platform package list, applied via `brew bundle`.
- `zsh/`, `git/`, `wezterm/`, `bin/`, `codex/` — stow packages. `bin/` symlinks executables into `~/bin` (e.g. `gdoc`).
