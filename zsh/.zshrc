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

# Aliases
alias gs="git status"
alias rl="source ~/.zshrc"

