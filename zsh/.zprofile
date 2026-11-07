# Optional private Roblox login configuration, installed by the roblox submodule.
_roblox_zprofile="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/roblox.zprofile"
[[ -r "$_roblox_zprofile" ]] && source "$_roblox_zprofile"
unset _roblox_zprofile

# Optional unsynchronized machine-specific login configuration, loaded last.
[[ -r "$HOME/.zprofile.local" ]] && source "$HOME/.zprofile.local"
