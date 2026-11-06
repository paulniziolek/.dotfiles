# WezTerm config changelog

Changes to `wezterm.lua` and to the WezTerm install, newest first. Each entry
lists what to remove or restore to revert it.

## 2026-10-22 — Switched to WezTerm nightly

Not a config change. Replaced the Homebrew cask `wezterm` (20240203) with
`wezterm@nightly` to get the macOS fullscreen notch fix (wezterm#3807,
PR #5515). Upgrade with `brew upgrade --cask --greedy wezterm@nightly`.

**To revert:** `brew uninstall --cask wezterm@nightly && brew install --cask wezterm`
(the two casks conflict, so one must be removed first).

A custom tab-bar layout that left a gap under the notch was added and then
fully removed the same day; nothing remains of it in `wezterm.lua`.
