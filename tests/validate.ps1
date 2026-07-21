$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root "PeekDock.ahk"
$readmePath = Join-Path $root "README.md"

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

function Assert-NotContains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -match $Pattern) {
        throw $Message
    }
}

if (-not (Test-Path $scriptPath)) {
    throw "Missing PeekDock.ahk"
}

if (-not (Test-Path $readmePath)) {
    throw "Missing README.md"
}

$script = Get-Content -Raw $scriptPath
$readme = Get-Content -Raw $readmePath

Assert-Contains $script 'MButton::ToggleWindow\(\)' "Missing middle mouse toggle hotkey"
Assert-Contains $script 'PeekDock' "Script should use the project name in user-facing titles"
Assert-NotContains $script '\^!b::ToggleWindow\(\)' "Ctrl+Alt+B should no longer toggle the app window"
Assert-Contains $script '\^!\+b::BindActiveBrowserUrl\(\)' "Missing Ctrl+Alt+Shift+B bind hotkey"
Assert-Contains $script '\^!t::ToggleAlwaysOnTop\(\)' "Missing Ctrl+Alt+T topmost hotkey"
Assert-Contains $script 'ShowStartupHelp\(\)' "Script should show hotkey help after launch"
Assert-Contains $script 'PeekDock is running' "Startup help should tell the user the script is running"
Assert-Contains $script 'Middle mouse: open / hide / restore the dock' "Startup help should document the middle mouse toggle"
Assert-Contains $script 'Ctrl \+ Alt \+ Shift \+ B: bind the active Chrome tab' "Startup help should document the bind hotkey"
Assert-Contains $script 'Ctrl \+ Alt \+ T: toggle always-on-top' "Startup help should document the topmost hotkey"
Assert-Contains $script 'chrome\.exe' "Script should target Chrome"
Assert-Contains $script '--app="' "Script should launch Chrome as an app window"
Assert-Contains $script '--user-data-dir="' "Script should use a dedicated Chrome profile"
Assert-Contains $script 'config\.ini' "Script should persist the bound URL in config.ini"
Assert-Contains $script 'A_Clipboard' "Script should read the active tab URL through the clipboard"
Assert-Contains $script 'WinHide' "Script should hide instead of closing the app window"
Assert-Contains $script 'WinShow' "Script should restore hidden app window"
Assert-Contains $script 'WinSetAlwaysOnTop' "Script should support toggling always-on-top"
Assert-NotContains $script 'WinSetAlwaysOnTop\([^,\r\n]*"On"' 'AutoHotkey v2 WinSetAlwaysOnTop should receive a numeric value, not "On"'
Assert-NotContains $script 'WinSetAlwaysOnTop\([^,\r\n]*"Off"' 'AutoHotkey v2 WinSetAlwaysOnTop should receive a numeric value, not "Off"'
Assert-NotContains $script 'WinMove\(' "Restoring the app window should keep its previous size and position"
Assert-Contains $script 'Runtime' "Script should persist the app window handle at runtime"
Assert-Contains $script 'FindChromeWindowByPid' "Script should find the app window from the launch PID"
Assert-NotContains $script 'GetProcessCommandLine' "Hotkey path should not depend on slow WMI command-line scanning"
Assert-NotContains $script 'ComObjGet\("winmgmts:"\)' "Hotkey path should not use WMI"
Assert-NotContains $script 'A_LocalAppData' "A_LocalAppData is not an AutoHotkey v2 built-in variable"
Assert-Contains $script 'EnvGet\("LOCALAPPDATA"\)' "Script should read LOCALAPPDATA through EnvGet"

Assert-Contains $readme 'AutoHotkey v2' "README should mention AutoHotkey v2"
Assert-Contains $readme '# PeekDock' "README should use the project name as its title"
Assert-Contains $readme 'Ctrl \+ Alt \+ Shift \+ B' "README should document bind hotkey"
Assert-Contains $readme 'Chrome' "README should document Chrome usage"

Write-Host "Validation passed."
