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

export CLAUDE_CODE_NO_FLICKER=1

eval "$(starship init zsh)"

# WezTerm shell integration: marks prompts (Cmd+Up/Down jumps between them) and
# reports the cwd. Sourced after starship so its PS1 markers wrap starship's prompt.
if [[ "${TERM_PROGRAM-}" == "WezTerm" && -r /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then
    source /Applications/WezTerm.app/Contents/Resources/wezterm.sh
fi

# Option+Left/Right move by word (WezTerm sends xterm-style ESC[1;3D / ESC[1;3C).
# Adding Shift selects instead, by word (ESC[1;4D/C) or by character with
# Shift alone (ESC[1;2D/C). Backspace deletes the selection, and Alt+W copies it
# (WezTerm's Cmd+C sends Alt+W when nothing is selected with the mouse).
_select_move() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle ${WIDGET#select-}
}
_deselect_move() {
  REGION_ACTIVE=0
  zle ${WIDGET#deselect-}
}
_backward_delete_selection() {
  if (( REGION_ACTIVE )); then
    zle kill-region
  else
    zle backward-delete-char
  fi
}
_copy_selection() {
  zle copy-region-as-kill
  (( $+commands[pbcopy] )) && print -rn -- "$CUTBUFFER" | pbcopy
  REGION_ACTIVE=0
}
for _widget in backward-word forward-word backward-char forward-char; do
  zle -N select-$_widget _select_move
  zle -N deselect-$_widget _deselect_move
done
unset _widget
zle -N backward-delete-selection _backward_delete_selection
zle -N copy-selection _copy_selection
bindkey '^?' backward-delete-selection
bindkey '^[[1;3D' deselect-backward-word
bindkey '^[[1;3C' deselect-forward-word
bindkey '^[[1;4D' select-backward-word
bindkey '^[[1;4C' select-forward-word
bindkey '^[[1;2D' select-backward-char
bindkey '^[[1;2C' select-forward-char
bindkey '^[w' copy-selection

# Aliases
alias gs="git status"
alias gc="git checkout"
alias wl="git worktree list"
# Open the GitHub PR for the current branch in the browser
alias ghpr='gh pr view --web'
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
alias venv="python3 -m venv .venv && source .venv/bin/activate"

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
