if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# fzf (Ctrl+R history, Ctrl+T files, Alt+C cd, ** completion)
if command -v brew >/dev/null; then
    source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
    source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    # syntax-highlighting must be sourced after any plugin that defines ZLE widgets
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

eval "$(starship init zsh)"

# WezTerm shell integration: marks prompts (Cmd+Up/Down jumps between them) and
# reports the cwd. Sourced after starship so its PS1 markers wrap starship's prompt.
if [[ "${TERM_PROGRAM-}" == "WezTerm" && -r /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then
    source /Applications/WezTerm.app/Contents/Resources/wezterm.sh
fi

# Aliases
alias gs="git status"
alias rl="source ~/.zshrc"
alias ls="eza --icons"
alias ll="eza -lg --icons"
alias lt="eza -lTg --icons"
alias lt1="eza -lTg --level=1 --icons"
alias lt2="eza -lTg --level=2 --icons"
alias lt3="eza -lTg --level=3 --icons"
alias lta="eza -lTag --icons"
alias lta1="eza -lTag --level=1 --icons"
alias lta2="eza -lTag --level=2 --icons"
alias lta3="eza -lTag --level=3 --icons"

# Functions
zindex() {
  local root="${1:-.}"

  fd . "$root" \
    --type d \
    --hidden \
    --exclude .git \
    --exec zoxide add
}

cl() {
  tput cuu "${1:-1}"
  tput ed
}

# Initialize zoxide after aliases and functions.
eval "$(zoxide init zsh --cmd cd)"

# Optional private Roblox configuration, installed by the roblox submodule.
_roblox_zsh="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/roblox.zsh"
[[ -r "$_roblox_zsh" ]] && source "$_roblox_zsh"
unset _roblox_zsh

# Optional unsynchronized machine-specific configuration. Load this last so it
# can override both the public configuration and the private Roblox overlay.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
