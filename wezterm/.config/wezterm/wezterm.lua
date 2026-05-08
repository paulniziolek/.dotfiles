local function color_scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Tokyo Night"
  else
    return "Tokyo Night Light (Gogh)"
  end
end

local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 14
config.color_scheme = color_scheme_for_appearance(wezterm.gui.get_appearance())
config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = false
config.use_fancy_tab_bar = false

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"



if wezterm.target_triple:find("windows") then
  config.default_domain = "WSL:Ubuntu"
end

return config

