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

By default this stows `zsh,git,wezterm,bin,codex,claude,herdr,nvim`. To override, set `STOW_FOLDERS` (comma-separated):

```bash
STOW_FOLDERS=zsh,nvim,tmux ./ubuntu
```

To stow or re-stow packages without the bootstrap (no Homebrew or `defaults`), e.g. after adding one, run `install` with the package names:

```bash
./install herdr
```

To remove all symlinks: `./ubuntu --clean` (or `./macos --clean`).

Stow runs with `--no-folding`, so it links individual files rather than whole directories. Apps that write runtime files next to their config (e.g. herdr's sockets and logs) then don't write into the repo.

## Optional private and local Zsh configuration

The public Zsh configuration supports two additive layers, loaded after the
main `.zshrc`:

1. `~/.config/zsh/roblox.zsh` for private, Git-synchronized Roblox settings.
2. `~/.zshrc.local` for unsynchronized settings specific to one machine.

`.zprofile` does the same for login shells with `~/.config/zsh/roblox.zprofile`
and `~/.zprofile.local`, and `~/.config/git/config` includes
`~/.config/git/roblox` when the submodule provides it.

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

Portable defaults live in `codex-system/etc/codex/config.toml`. The installer
links that file to `/etc/codex/config.toml`, the Unix system configuration
layer. This keeps shared model, reasoning, sandbox, marketplace, and plugin
defaults synchronized through Git. Installing or removing this system symlink
may prompt for `sudo`.

Mutable machine state stays in the untracked `~/.codex/config.toml`. Codex can
record trusted projects, writable roots, MCP servers, and UI state there
without dirtying the dotfiles checkout. User settings override the portable
system defaults when the same key appears in both files.

## Shared agent instructions

The `codex` Stow package also links the portable global prompt to
`~/.codex/AGENTS.md`. Machine-specific guidance lives outside Git at
`~/.config/agents/machine.md`; the global prompt tells agents to load it when
the client has not already supplied it. This overlay is optional: the installer
does not create or symlink it, and agents simply skip it when it is absent.

The `claude` Stow package links `~/.claude/CLAUDE.md`. That file imports both
the portable global prompt and, when present, the optional machine overlay,
giving Codex and Claude Code the same baseline without committing
machine-specific paths or shell rules. Stow's `--no-folding` links these
Markdown files individually rather than taking over `~/.codex` and `~/.claude`.

## Manual steps after install

These don't fit cleanly into the install scripts — run once per machine:

- **`gh auth login`** — authenticate the GitHub CLI (browser flow).
- **SSH key for GitHub** — generate and register a key so you can clone/push via SSH:
  ```bash
  ssh-keygen -t ed25519 -C "niziolek.paul@gmail.com"
  gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
  ```
  Requires `gh auth login` to have run first. Skip entirely if you only clone via HTTPS.
- **herdr** — install from [herdr.dev](https://herdr.dev), then `herdr integration install claude` and `herdr integration install codex` for agent status. Config is in the `herdr/` package.
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
- `macos` — macOS bootstrap: Xcode CLI tools + Homebrew install + system `defaults` (keyboard, Caps Lock → F18 as the herdr leader, Dock, Finder, screenshots, disable Spotlight ⌘Space) + dispatch to `install`.
- `windows.ps1` — Windows bootstrap: copies Windows-side configs (currently just `wezterm.lua`) into `%USERPROFILE%`.
- `install`, `clean-env` — symlink / unlink each folder in `$STOW_FOLDERS` (or the packages named to `install`) via `stow`.
- `Brewfile` — cross-platform package list, applied via `brew bundle`.
- `zsh/`, `git/`, `wezterm/`, `bin/`, `codex/`, `claude/`, `herdr/`, `nvim/` — home-directory Stow packages. `nvim/` is a LazyVim config; the roblox submodule adds its game-engine plugin to the same `~/.config/nvim`. `codex-system/` provides portable Codex defaults under `/etc/codex`. `macos-defaults/` holds app preference plists that `macos` loads with `defaults import` (Rectangle). To refresh one after changing settings in the app: `defaults export com.knollsoft.Rectangle - > macos-defaults/com.knollsoft.Rectangle.plist`. `bin/` symlinks executables into `~/bin` (e.g. `gdoc`).
