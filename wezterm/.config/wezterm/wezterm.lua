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
config.alternate_buffer_wheel_scroll_speed = 0

config.colors = {
  split = '#7aa2f7',
}

config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.575,
}


local is_windows = wezterm.target_triple:find("windows") ~= nil
local mod = is_windows and 'CTRL' or 'CMD'

local act = wezterm.action

-- Session saving via resurrect.wezterm: the whole session autosaves shortly
-- after anything changes and is restored on launch; closed tabs are kept in a
-- history that mod+shift+t reopens newest-first.
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'
local sessions = resurrect.state_manager
-- get_file_path concatenates the dir and type with no separator.
local save_dir = wezterm.home_dir .. '/.local/share/wezterm/resurrect/'
sessions.change_state_save_dir(save_dir)

local CLOSED_PREFIX = 'closed-'
local SAVED_PREFIX = 'saved-'
local CLOSED_KEEP = 50
local AUTOSAVE_CHECK_S = 5
local AUTOSAVE_QUIET_S = 10 -- save once a change has settled for this long
local AUTOSAVE_MAX_S = 60 -- but never let a busy session go unsaved longer

-- Saved text includes the screen's unused rows below the prompt, each ending
-- in an escape code, so the plugin's trailing-whitespace trim misses them and
-- the restored prompt lands after a gap. Drop trailing blank rows and cap blank
-- runs at two (gaps baked in by earlier restores), keeping their escape codes.
local ESCAPE = '\27[%[%(][%d;?]*%a'

local function tidy_scrollback(text)
  local out, run, run_escapes = {}, 0, ''
  for line in (text .. '\n'):gmatch '(.-)\n' do
    if line:gsub(ESCAPE, ''):match '^%s*$' then
      run = run + 1
      for seq in line:gmatch(ESCAPE) do
        run_escapes = run_escapes .. seq
      end
    else
      for _ = 1, math.min(run, 2) do
        table.insert(out, '')
      end
      table.insert(out, run_escapes .. line)
      run, run_escapes = 0, ''
    end
  end
  return table.concat(out, '\n') .. run_escapes .. '\27[0m\r\n'
end

local function on_pane_restore(pane_tree)
  if pane_tree.alt_screen_active or not pane_tree.text then
    return resurrect.tab_state.default_on_pane_restore(pane_tree)
  end
  pane_tree.pane:inject_output(tidy_scrollback(pane_tree.text))
end

local restore_opts = {
  relative = true,
  restore_text = true,
  on_pane_restore = on_pane_restore,
}

local function tab_save_names(prefix)
  local names = {}
  for _, path in ipairs(wezterm.read_dir(save_dir .. 'tab')) do
    local name = path:match '([^/]+)%.json$'
    if name and name:sub(1, #prefix) == prefix then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

local function closed_tab_names()
  return tab_save_names(CLOSED_PREFIX)
end

-- Explicit ASCII ranges: %w can match bytes of multi-byte UTF-8 characters
-- (e.g. Claude Code's ✳ title prefix), leaving invalid filenames.
local function file_safe(s)
  local safe = s:gsub('[^A-Za-z0-9 ._-]', ''):gsub('^[ .]+', '')
  return safe:sub(1, 40)
end

local function save_closed_tab(tab)
  local title = tab:get_title()
  if title == '' then
    title = tab:active_pane():get_title()
  end
  local name = CLOSED_PREFIX .. os.date '%Y%m%d-%H%M%S' .. '-' .. tab:tab_id() .. '-' .. file_safe(title)
  sessions.save_state(resurrect.tab_state.get_tab_state(tab), name)
  local names = closed_tab_names()
  for i = 1, #names - CLOSED_KEEP do
    os.remove(save_dir .. 'tab/' .. names[i] .. '.json')
  end
end

local close_pane_saving_tab = wezterm.action_callback(function(win, pane)
  save_closed_tab(pane:tab())
  win:perform_action(act.CloseCurrentPane { confirm = false }, pane)
end)

-- restore_tab without opts.pane splits the current tab, so give it a fresh one.
local function restore_tab_in_new_tab(win, state)
  local tab, new_pane = win:mux_window():spawn_tab { cwd = state.pane_tree.cwd }
  local opts = { pane = new_pane }
  for k, v in pairs(restore_opts) do
    opts[k] = v
  end
  resurrect.tab_state.restore_tab(tab, state, opts)
end

local reopen_closed_tab = wezterm.action_callback(function(win, _)
  local names = closed_tab_names()
  local name = names[#names]
  if not name then
    win:toast_notification('wezterm', 'No closed tabs to reopen', nil, 2000)
    return
  end
  restore_tab_in_new_tab(win, sessions.load_state(name, 'tab'))
  os.remove(save_dir .. 'tab/' .. name .. '.json')
end)

local function save_session()
  local workspace = wezterm.mux.get_active_workspace()
  sessions.save_state(resurrect.workspace_state.get_workspace_state())
  sessions.write_current_state(workspace, 'workspace')
end

local function restore_from_picker(win, pane)
  resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
    local type = id:match '^([^/]+)'
    local name = id:match '([^/]+)$':match '(.+)%..+$'
    local state = sessions.load_state(name, type)
    if type == 'workspace' then
      resurrect.workspace_state.restore_workspace(state, restore_opts)
    elseif type == 'window' then
      resurrect.window_state.restore_window(pane:window(), state, restore_opts)
    elseif type == 'tab' then
      restore_tab_in_new_tab(win, state)
    end
  end)
end

local function delete_from_picker(win, pane)
  resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
    sessions.delete_state(id)
  end, { title = 'Delete saved session', description = 'Select a save to delete', is_fuzzy = true })
end

-- A cheap fingerprint of every pane, so the expensive full save (which
-- captures scrollback) only runs when something actually changed.
local function session_fingerprint()
  local parts = {}
  for _, mux_win in ipairs(wezterm.mux.all_windows()) do
    for _, tab in ipairs(mux_win:tabs()) do
      for _, p in ipairs(tab:panes()) do
        local dims = p:get_dimensions()
        local cursor = p:get_cursor_position()
        table.insert(parts, table.concat({
          p:pane_id(), tostring(p:get_current_working_dir()), p:get_title(),
          dims.scrollback_rows, cursor.x, cursor.y,
        }, '|'))
      end
    end
  end
  return #parts > 0 and table.concat(parts, '\n') or nil
end

-- WezTerm evaluates this file more than once per reload, and call_after
-- timers from the throwaway evaluations never fire. So the timer is started
-- from the first event this evaluation receives (proof it is the live one),
-- and the generation check retires the previous evaluation's timer.
local autosave_started = false

local function autosave_check()
  local g = wezterm.GLOBAL
  local now = os.time()
  local fingerprint = session_fingerprint()
  if fingerprint and fingerprint ~= g.autosave_fingerprint then
    g.autosave_fingerprint = fingerprint
    g.autosave_changed_at = now
    g.autosave_dirty_since = g.autosave_dirty_since or now
  end
  if g.autosave_dirty_since
    and (now - g.autosave_changed_at >= AUTOSAVE_QUIET_S or now - g.autosave_dirty_since >= AUTOSAVE_MAX_S) then
    save_session()
    g.autosave_dirty_since = nil
  end
end

local function autosave_tick(gen)
  if wezterm.GLOBAL.autosave_gen ~= gen then
    return
  end
  autosave_check()
  wezterm.time.call_after(AUTOSAVE_CHECK_S, function() autosave_tick(gen) end)
end

wezterm.on('update-status', function()
  if autosave_started then
    return
  end
  autosave_started = true
  local gen = (wezterm.GLOBAL.autosave_gen or 0) + 1
  wezterm.GLOBAL.autosave_gen = gen
  autosave_tick(gen)
end)

-- Same as sessions.resurrect_on_gui_startup, but with our on_pane_restore.
wezterm.on('gui-startup', function()
  local f = io.open(save_dir .. 'current_state')
  if not f then
    return
  end
  local name, type = f:read '*l', f:read '*l'
  f:close()
  if type == 'workspace' then
    local opts = { spawn_in_workspace = true }
    for k, v in pairs(restore_opts) do
      opts[k] = v
    end
    resurrect.workspace_state.restore_workspace(sessions.load_state(name, 'workspace'), opts)
    wezterm.mux.set_active_workspace(name)
  end
end)

-- Tabs saved on purpose ("saved-<name>") are kept until deleted, unlike the
-- closed-tab history.
local save_tab_as = act.PromptInputLine {
  description = 'Save this tab as',
  action = wezterm.action_callback(function(win, pane, line)
    if line and file_safe(line) ~= '' then
      sessions.save_state(resurrect.tab_state.get_tab_state(pane:tab()), SAVED_PREFIX .. file_safe(line))
      win:toast_notification('wezterm', 'Saved tab: ' .. file_safe(line), nil, 2000)
    end
  end),
}

-- Lists tab saves with the given prefix; picking one restores it in a new tab.
local function tab_save_picker(title, prefix, remove_after_restore)
  return wezterm.action_callback(function(win, pane)
    local names = tab_save_names(prefix)
    if #names == 0 then
      win:toast_notification('wezterm', 'Nothing saved yet', nil, 2000)
      return
    end
    local choices = {}
    for i = #names, 1, -1 do
      table.insert(choices, { id = names[i], label = names[i]:sub(#prefix + 1) })
    end
    win:perform_action(act.InputSelector {
      title = title,
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(w, _, id)
        if id then
          restore_tab_in_new_tab(w, sessions.load_state(id, 'tab'))
          if remove_after_restore then
            os.remove(save_dir .. 'tab/' .. id .. '.json')
          end
        end
      end),
    }, pane)
  end)
end

local key_hint = is_windows and 'Ctrl' or 'Cmd'

-- Agent status (working / waiting / idle) on each tab, via its own
-- format-tab-title and update-status handlers. It reads the last 100 lines of
-- each pane every update_interval ms.
-- Claude Code prints no prompt markers: while a command is running (the last
-- semantic zone is Output) jump via scrollback search for lines starting with
-- '❯ ', which matches both Claude Code's user messages and starship prompts.
local PROMPT_LINE = '^❯ '

local function jump_prompt(direction)
  return wezterm.action_callback(function(win, pane)
    local zones = pane:get_semantic_zones()
    local last = zones[#zones]
    if last and last.semantic_type ~= 'Output' then
      win:perform_action(act.ScrollToPrompt(direction), pane)
    else
      win:perform_action(act.Search { Regex = PROMPT_LINE }, pane)
    end
  end)
end

if wezterm.gui then
  local search_mode = wezterm.gui.default_key_tables().search_mode
  table.insert(search_mode, { key = 'UpArrow', mods = mod, action = act.CopyMode 'PriorMatch' })
  table.insert(search_mode, { key = 'DownArrow', mods = mod, action = act.CopyMode 'NextMatch' })
  config.key_tables = { search_mode = search_mode }
end

local agent_deck = wezterm.plugin.require 'https://github.com/Eric162/wezterm-agent-deck'
agent_deck.apply_to_config(config, { update_interval = 1000 })

-- The short menu on mod+shift+p. These also appear in the full palette.
local my_commands = {
  { label = 'Save this tab as…', action = save_tab_as },
  { label = 'Open a saved tab…', action = tab_save_picker('Open a saved tab', SAVED_PREFIX, false) },
  { label = 'Delete a save (tab, closed tab or session)…', action = wezterm.action_callback(function(win, pane)
    resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
      sessions.delete_state(id)
    end, { title = 'Delete a save', description = 'Select a save to delete', is_fuzzy = true })
  end) },
  { label = 'Reopen last closed tab  (' .. key_hint .. '+Shift+T)', action = reopen_closed_tab },
  { label = 'Reopen a closed tab…', action = tab_save_picker('Reopen a closed tab', CLOSED_PREFIX, true) },
  { label = 'Rename tab…', action = act.PromptInputLine {
    description = 'Tab name',
    action = wezterm.action_callback(function(win, _, line)
      if line then
        win:active_tab():set_title(line)
      end
    end),
  } },
  { label = 'Save whole session now', action = wezterm.action_callback(function() save_session() end) },
  { label = 'Restore a saved session or window…', action = wezterm.action_callback(restore_from_picker) },
  { label = 'Quick select: copy a URL, path or hash  (Ctrl+Shift+Space)', action = act.QuickSelect },
  { label = 'Jump to previous prompt / Claude message  (' .. key_hint .. '+Up)', action = jump_prompt(-1) },
  { label = 'Jump to next prompt / Claude message  (' .. key_hint .. '+Down)', action = jump_prompt(1) },
  { label = 'Split right  (' .. key_hint .. '+\\)', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { label = 'Split down  (' .. key_hint .. '+-)', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { label = 'Toggle fullscreen  (Opt+Enter)', action = act.ToggleFullScreen },
  { label = 'Reload config', action = act.ReloadConfiguration },
  { label = 'All commands…  (Ctrl+Shift+P)', action = act.ActivateCommandPalette },
}

local my_menu = wezterm.action_callback(function(win, pane)
  local choices = {}
  for i, c in ipairs(my_commands) do
    table.insert(choices, { id = tostring(i), label = c.label })
  end
  win:perform_action(act.InputSelector {
    title = 'Commands',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(w, p, id)
      if id then
        w:perform_action(my_commands[tonumber(id)].action, p)
      end
    end),
  }, pane)
end)

wezterm.on('augment-command-palette', function()
  local entries = {}
  for _, c in ipairs(my_commands) do
    table.insert(entries, { brief = 'My: ' .. c.label, action = c.action })
  end
  return entries
end)

-- While herdr is the pane's foreground program, the tab and pane shortcuts
-- drive herdr through its ctrl+b prefix instead of WezTerm. The resize chords
-- are herdr direct bindings set in ~/.config/herdr/config.toml.
local function in_herdr(pane)
  return (pane:get_foreground_process_name() or ''):match '/herdr$' ~= nil
end

local function herdr_or(default_action, herdr_action)
  return wezterm.action_callback(function(win, pane)
    win:perform_action(in_herdr(pane) and herdr_action or default_action, pane)
  end)
end

local function herdr_prefixed(key)
  return act.Multiple { act.SendKey { key = 'b', mods = 'CTRL' }, act.SendKey { key = key } }
end

local herdr_resize = 'CTRL|ALT|SHIFT'

config.keys = {
  { key = '\\', mods = mod, action = herdr_or(act.SplitHorizontal { domain = 'CurrentPaneDomain' }, herdr_prefixed 'v') },
  { key = '-', mods = mod, action = herdr_or(act.SplitVertical { domain = 'CurrentPaneDomain' }, herdr_prefixed '-') },
  { key = 'h', mods = mod, action = herdr_or(act.ActivatePaneDirection 'Left', herdr_prefixed 'h') },
  { key = 'j', mods = mod, action = herdr_or(act.ActivatePaneDirection 'Down', herdr_prefixed 'j') },
  { key = 'k', mods = mod, action = herdr_or(act.ActivatePaneDirection 'Up', herdr_prefixed 'k') },
  { key = 'l', mods = mod, action = herdr_or(act.ActivatePaneDirection 'Right', herdr_prefixed 'l') },
  { key = 'w', mods = mod, action = herdr_or(close_pane_saving_tab, herdr_prefixed 'x') },
  { key = 't', mods = mod, action = herdr_or(act.SpawnTab 'CurrentPaneDomain', herdr_prefixed 'c') },
  { key = 't', mods = mod .. '|SHIFT', action = reopen_closed_tab },
  { key = 'p', mods = mod .. '|SHIFT', action = my_menu },
  { key = 'UpArrow', mods = mod, action = jump_prompt(-1) },
  { key = 'DownArrow', mods = mod, action = jump_prompt(1) },
  { key = 'h', mods = mod .. '|SHIFT', action = herdr_or(act.AdjustPaneSize { 'Left', 5 }, act.SendKey { key = 'LeftArrow', mods = herdr_resize }) },
  { key = 'j', mods = mod .. '|SHIFT', action = herdr_or(act.AdjustPaneSize { 'Down', 5 }, act.SendKey { key = 'DownArrow', mods = herdr_resize }) },
  { key = 'k', mods = mod .. '|SHIFT', action = herdr_or(act.AdjustPaneSize { 'Up', 5 }, act.SendKey { key = 'UpArrow', mods = herdr_resize }) },
  { key = 'l', mods = mod .. '|SHIFT', action = herdr_or(act.AdjustPaneSize { 'Right', 5 }, act.SendKey { key = 'RightArrow', mods = herdr_resize }) },
}

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = mod, action = herdr_or(act.ActivateTab(i - 1), herdr_prefixed(tostring(i))) })
end

-- mod+click opens a link under the cursor even while a TUI (e.g. Claude Code)
-- has mouse reporting enabled and would otherwise swallow the click.
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = mod,
    mouse_reporting = true,
    action = act.OpenLinkAtMouseCursor,
  },
}

if is_windows then
  config.default_domain = "WSL:Ubuntu"
end

return config

