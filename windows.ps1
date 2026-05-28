#!/usr/bin/env pwsh
# windows.ps1 - install Windows-side dotfiles.
# Run from Windows PowerShell with the dotfiles repo as cwd:
#     cd \\wsl.localhost\Ubuntu\home\nizio\.dotfiles
#     .\windows.ps1
# Source of truth stays in the repo; this script copies into the Windows profile.

$ErrorActionPreference = 'Stop'

$Repo = $PSScriptRoot

$Targets = @(
    @{
        Src = Join-Path $Repo 'wezterm\.config\wezterm\wezterm.lua'
        Dst = Join-Path $env:USERPROFILE '.config\wezterm\wezterm.lua'
    }
)

foreach ($t in $Targets) {
    if (-not (Test-Path -LiteralPath $t.Src)) {
        throw "Missing source: $($t.Src)"
    }

    $dstDir = Split-Path -Parent $t.Dst
    if (-not (Test-Path -LiteralPath $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    # Remove any existing file/symlink (Test-Path returns false for broken
    # symlinks, so fall back to a low-level delete).
    if (Test-Path -LiteralPath $t.Dst) {
        Remove-Item -LiteralPath $t.Dst -Force
    } else {
        try { [System.IO.File]::Delete($t.Dst) } catch {}
    }

    Copy-Item -LiteralPath $t.Src -Destination $t.Dst -Force
    Write-Host "Installed $($t.Dst)"
}

Write-Host "Done. Restart WezTerm to pick up changes."
