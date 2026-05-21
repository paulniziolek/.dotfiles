# .dotfiles

Personal dotfiles managed via [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./ubuntu        # on Ubuntu / WSL2
./macos         # on macOS
```

By default this stows `zsh,git,wezterm,bin`. To override, set `STOW_FOLDERS` (comma-separated):

```bash
STOW_FOLDERS=zsh,nvim,tmux ./ubuntu
```

To remove all symlinks: `./ubuntu --clean` (or `./macos --clean`).

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

WezTerm runs as a Windows GUI app, so it reads its config from Windows and renders fonts from Windows — but the dotfiles live in WSL. Bridge the two with a symlink:

```powershell
# 1. From WSL, get the Windows path to the config:
#    wslpath -w "$(realpath ~/.dotfiles/wezterm/.config/wezterm/wezterm.lua)"
# 2. From PowerShell (admin, or with Developer Mode on):
mkdir "$env:USERPROFILE\.config\wezterm" -Force
New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\.config\wezterm\wezterm.lua" `
  -Target "\\wsl.localhost\Ubuntu\home\nizio\.dotfiles\wezterm\.config\wezterm\wezterm.lua"
```

If `New-Item` complains about admin privilege, enable **Settings → System → For developers → Developer Mode** and reopen PowerShell. Windows `sudo` is not the WSL `sudo`.

Two config gotchas, since the same `wezterm.lua` is shared across macOS/Linux/Windows:

- **Default to WSL on Windows only** — guard with `wezterm.target_triple:find("windows")` before setting `config.default_domain = "WSL:Ubuntu"` (run `wsl -l -v` to confirm the distro name).
- **Install fonts on Windows** — the GUI host renders fonts, so `JetBrainsMono Nerd Font` must be installed on Windows even if WezTerm launches into WSL:

  ```powershell
  winget install DEVCOM.JetBrainsMonoNerdFont
  ```

## Layout

- `ubuntu` — Ubuntu bootstrap: apt prereqs + Homebrew install + dispatch to `install`.
- `macos` — macOS bootstrap: Xcode CLI tools + Homebrew install + system `defaults` (keyboard, Dock, Finder, screenshots, disable Spotlight ⌘Space) + dispatch to `install`.
- `install`, `clean-env` — symlink / unlink each folder in `$STOW_FOLDERS` via `stow`.
- `Brewfile` — cross-platform package list, applied via `brew bundle`.
- `zsh/`, `git/`, `wezterm/`, `bin/` — stow packages. `bin/` symlinks executables into `~/bin` (e.g. `gdoc`).
