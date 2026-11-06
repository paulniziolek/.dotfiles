# WezTerm config changelog

Changes to `wezterm.lua` and to the WezTerm install, newest first. Each entry
lists what to remove or restore to revert it.

## 2026-10-23 — Agent status on tabs, prompt jumping

- **Agent status:** [wezterm-agent-deck](https://github.com/Eric162/wezterm-agent-deck)
  via `agent_deck.apply_to_config(config, { update_interval = 1000 })`, next to
  `key_hint` in `wezterm.lua`. It registers its own `format-tab-title` and
  `update-status` handlers and sets `config.status_update_interval`. Tab titles
  now come from the plugin.
- **Prompt jumping:** `mod+Up` / `mod+Down` → `jump_prompt(-1/1)`. At a shell
  prompt it runs `act.ScrollToPrompt`, which needs the shell integration below.
  While a command is running (last semantic zone is `Output`, e.g. Claude Code)
  it opens `act.Search { Regex = '^❯ ' }`, which matches Claude Code user
  messages and starship prompts. `config.key_tables.search_mode` extends the
  default table with `mod+Up/Down` → Prior/NextMatch.
- **Shell integration (outside this directory):** `~/.dotfiles/zsh/.zshrc`
  sources `/Applications/WezTerm.app/Contents/Resources/wezterm.sh` right after
  `starship init`, guarded on `TERM_PROGRAM == WezTerm`. It adds OSC 133 prompt
  markers and OSC 7 cwd reporting.
- **Menu:** `my_commands` gained "Quick select…", "Jump to previous prompt" and
  "Jump to next prompt".

**To revert:** delete the `agent_deck` lines, `jump_prompt`, `config.key_tables`, the two `mod+Up/Down` keys,
the three menu entries, and the `wezterm.sh` block in `.zshrc`. Optionally
delete the plugin clone `…/wezterm/plugins/httpssCssZssZsgithubsDscomsZsEric162sZswezterm-agent-deck`.

## 2026-10-22 — Session saving, saved tabs, closed-tab history, command menu

Added the [resurrect.wezterm](https://github.com/MLFlexer/resurrect.wezterm)
plugin (archived upstream on 2026-05-24, so unmaintained) plus custom glue.

**In `wezterm.lua`**, everything is in one block that starts at the comment
`-- Session saving via resurrect.wezterm` and ends just before
`config.keys = {`:

- `wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'`
- Saves go to `~/.local/share/wezterm/resurrect/{workspace,window,tab}/`
  (`change_state_save_dir`), not to the plugin directory.
- **Autosave:** a `call_after` timer started from the first `update-status`
  event checks a cheap fingerprint of every pane (cwd, title, scrollback rows,
  cursor) every 5 s. It saves the whole workspace once changes have been quiet
  for 10 s, or every 60 s at most while busy, and writes `current_state` so the
  session restores on launch. Timer generations live in `wezterm.GLOBAL.autosave_*`.
- **Restore on launch:** a `gui-startup` handler that mirrors
  `sessions.resurrect_on_gui_startup` but passes our `restore_opts`.
- **Restore hook:** `on_pane_restore` / `tidy_scrollback` replace the plugin's
  `default_on_pane_restore` for non-alt-screen panes. Saved text includes the
  blank rows below the prompt, which end in escape codes, so the plugin's trim
  missed them and restored prompts appeared after a gap. The hook drops trailing
  blank rows and caps blank runs at two.
- **Closed-tab history:** `save_closed_tab` writes `tab/closed-<timestamp>-<tab id>-<title>.json`
  and keeps the newest 50. `reopen_closed_tab` restores the newest into a new
  tab and deletes its file. Both it and the palette picker go through
  `restore_tab_in_new_tab`, because the plugin's `restore_tab` otherwise splits
  the current tab.
- **Saved tabs:** `save_tab_as` prompts for a name and writes
  `tab/saved-<name>.json`, kept until deleted. `tab_save_picker` lists saves
  with a prefix (`saved-` or `closed-`) and restores the pick in a new tab.
  `file_safe` strips filenames to ASCII; `%w` let bytes of `✳` through in the GUI.
- **Command menu:** `my_commands` is the list of curated commands. `my_menu`
  shows it as a fuzzy `InputSelector`, and `augment-command-palette` also adds
  each one to the full palette prefixed with "My: ".

**In `config.keys`:**

- `mod+w` changed from `act.CloseCurrentPane { confirm = false }` to
  `close_pane_saving_tab`, which saves the tab to the history and then closes the pane.
- `mod+shift+t` added → `reopen_closed_tab`.
- `mod+shift+p` added → `my_menu`. WezTerm's full palette stays on its
  default Ctrl+Shift+P and is also the menu's last entry.

**To revert:** delete the block above, restore
`{ key = 'w', mods = mod, action = act.CloseCurrentPane { confirm = false } },`
and remove the `mod+shift+t` and `mod+shift+p` lines. Optionally delete
`~/.local/share/wezterm/resurrect/` (saved sessions, in plain-text JSON that
includes scrollback) and the plugin clone under
`~/Library/Application Support/wezterm/plugins/httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm`.

## 2026-10-22 — Switched to WezTerm nightly

Not a config change. Replaced the Homebrew cask `wezterm` (20240203) with
`wezterm@nightly` to get the macOS fullscreen notch fix (wezterm#3807,
PR #5515). Upgrade with `brew upgrade --cask --greedy wezterm@nightly`.

**To revert:** `brew uninstall --cask wezterm@nightly && brew install --cask wezterm`
(the two casks conflict, so one must be removed first).

A custom tab-bar layout that left a gap under the notch was added and then
fully removed the same day; nothing remains of it in `wezterm.lua`.
