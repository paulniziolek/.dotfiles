# .dotfiles

Personal dotfiles managed via [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./ubuntu        # on Ubuntu / WSL2
./macos         # on macOS
```

By default this stows the `zsh/` folder. To stow more, set `STOW_FOLDERS` (comma-separated):

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

## Layout

- `ubuntu` — Ubuntu bootstrap: apt prereqs + Homebrew install + dispatch to `install`.
- `macos` — macOS bootstrap: Xcode CLI tools + Homebrew install + dispatch to `install`.
- `install`, `clean-env` — symlink / unlink each folder in `$STOW_FOLDERS` via `stow`.
- `Brewfile` — cross-platform package list, applied via `brew bundle`.
- `zsh/` — zsh stow package.
