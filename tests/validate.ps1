$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root "PeekDock.ahk"
$readmePath = Join-Path $root "README.md"
$buildPath = Join-Path $root "scripts\build.ps1"
$buildInstallerPath = Join-Path $root "scripts\build-installer.ps1"
$installPath = Join-Path $root "scripts\install.ps1"
$troubleshootingPath = Join-Path $root "docs\troubleshooting.md"
$configExamplePath = Join-Path $root "config.example.ini"

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

foreach ($path in @($scriptPath, $readmePath, $buildPath, $buildInstallerPath, $installPath, $troubleshootingPath, $configExamplePath)) {
    if (-not (Test-Path $path)) {
        throw "Missing $path"
    }
}

$script = Get-Content -Raw -Encoding UTF8 $scriptPath
$readme = Get-Content -Raw -Encoding UTF8 $readmePath
$build = Get-Content -Raw -Encoding UTF8 $buildPath
$buildInstaller = Get-Content -Raw -Encoding UTF8 $buildInstallerPath
$install = Get-Content -Raw -Encoding UTF8 $installPath
$troubleshooting = Get-Content -Raw -Encoding UTF8 $troubleshootingPath
$configExample = Get-Content -Raw -Encoding UTF8 $configExamplePath
$chineseSupplementHeading = "## " + [string][char]0x4E2D + [string][char]0x6587 + [string][char]0x8865 + [string][char]0x5145

Assert-Contains $script 'PeekDock' "Script should use the project name in user-facing titles"
Assert-Contains $script 'LoadHotkeys\(\)' "Script should load hotkeys from config.ini"
Assert-Contains $script 'RegisterConfiguredHotkeys\(\)' "Script should register configurable hotkeys"
Assert-Contains $script 'UpdateHotkey\(action, hotkeyText\)' "Script should update hotkeys dynamically"
Assert-Contains $script 'UpdateHotkeys\(newHotkeys\)' "Script should save all GUI hotkeys as a checked set"
Assert-Contains $script 'CanonicalizeHotkey\(hotkeyText\)' "Script should canonicalize hotkeys before duplicate checks"
Assert-Contains $script 'Duplicate hotkey' "Script should reject duplicate hotkeys"
Assert-Contains $script 'Hotkey\(' "Script should use AutoHotkey v2 dynamic Hotkey registration"
Assert-Contains $script 'BuildMainGui\(\)' "Script should build a native settings GUI"
Assert-Contains $script 'RefreshMainGui\(\)' "Script should refresh GUI state after actions"
Assert-Contains $script 'SaveSettingsFromGui\(\*\)' "Script should save GUI settings"
Assert-Contains $script 'ConfigureTray\(\)' "Script should configure a tray menu"
Assert-Contains $script 'ToggleStartup\(enabled\)' "Script should support startup-at-login"
Assert-Contains $script 'Gui\(' "Script should use AutoHotkey native GUI"
Assert-NotContains $script 'gui := Gui\(' "Script should not shadow the AutoHotkey Gui constructor with a local gui variable"
Assert-Contains $script 'A_TrayMenu' "Script should expose tray actions"
Assert-Contains $script 'Bind Current Chrome Tab' "Script should expose the bind action in the GUI"
Assert-Contains $script 'BindActiveBrowserUrl\(true\)' "GUI and tray bind actions should activate Chrome before reading the URL"
Assert-Contains $script 'FindBindableChromeWindow\(\)' "Script should find a Chrome window for GUI-triggered binding"
Assert-Contains $script 'Show / Hide Dock' "Script should expose the dock toggle action in the GUI"
Assert-Contains $script 'Start with Windows' "Script should expose the startup option in the GUI"
Assert-NotContains $script '^MButton::ToggleWindow\(\)' "Toggle hotkey should be registered from config instead of a hard-coded label"
Assert-NotContains $script '\^!b::ToggleWindow\(\)' "Ctrl+Alt+B should no longer toggle the app window"
Assert-NotContains $script 'ShowStartupHelp\(\)' "Startup should use the main GUI instead of a help-only message box"
Assert-Contains $script 'chrome\.exe' "Script should target Chrome"
Assert-Contains $script 'Chrome cannot be found' "Script should show a clear message when Chrome is missing"
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

Assert-Contains $configExample '\[Hotkeys\]' "Config example should include a Hotkeys section"
Assert-Contains $configExample 'ToggleDock=MButton' "Config example should include the default dock hotkey"
Assert-Contains $configExample 'BindPage=\^!\+b' "Config example should include the default bind hotkey"
Assert-Contains $configExample 'ToggleTopMost=\^!t' "Config example should include the default topmost hotkey"
Assert-Contains $configExample '\[Startup\]' "Config example should include a Startup section"

Assert-Contains $readme '# PeekDock' "README should use the project name as its title"
Assert-Contains $readme 'AutoHotkey v2' "README should mention AutoHotkey v2"
Assert-Contains $readme 'Chrome' "README should document Chrome usage"
Assert-Contains $readme '## Features' "README should include Features"
Assert-Contains $readme '## Quick Start' "README should include Quick Start"
Assert-Contains $readme '## Default Hotkeys' "README should document default hotkeys"
Assert-Contains $readme 'Ctrl \+ Alt \+ Shift \+ B' "README should document bind hotkey"
Assert-Contains $readme 'Ctrl \+ Alt \+ T' "README should document topmost hotkey"
Assert-Contains $readme '## Build an exe' "README should explain exe packaging"
Assert-Contains $readme '## Build a one-click installer' "README should explain one-click installer packaging"
Assert-Contains $readme ([regex]::Escape($chineseSupplementHeading)) "README should include concise Chinese supplement"
Assert-Contains $readme '## Privacy' "README should include privacy notes"
Assert-Contains $readme '## License' "README should include license"
Assert-Contains $readme 'Bind Current Chrome Tab' "README should document GUI binding"
Assert-Contains $readme 'Show / Hide Dock' "README should document dock button"
Assert-Contains $readme 'Start with Windows' "README should document startup option"
Assert-Contains $readme 'PeekDock\.exe' "README should mention the packaged executable"

Assert-Contains $troubleshooting '## The dock hotkey does nothing' "Troubleshooting should cover dock hotkey issues"
Assert-Contains $troubleshooting '## Binding fails' "Troubleshooting should cover binding failures"
Assert-Contains $troubleshooting 'Bind Current Chrome Tab' "Troubleshooting should mention the bind action"
Assert-Contains $troubleshooting '## The exe does not start' "Troubleshooting should cover exe startup"
Assert-Contains $troubleshooting '## Start with Windows does not work' "Troubleshooting should cover startup-at-login"
Assert-Contains $troubleshooting 'Start with Windows' "Troubleshooting should mention the startup option"

$mojibakeTokens = @(
    [string][char]0xFFFD,
    ([string][char]0x93E1 + [string][char]0x93C4),
    ([string][char]0x69A7),
    ([string][char]0x7F03),
    ([string][char]0x95BA),
    ([string][char]0x59D2),
    ([string][char]0x9428),
    ([string][char]0x9354),
    ([string][char]0x9359),
    ([string][char]0x9286 + [string][char]0x3006),
    [string][char]0x6D93,
    [string][char]0x93C4,
    [string][char]0x69A7,
    [string][char]0x951B,
    [string][char]0x20AC
)
$mojibakePattern = ($mojibakeTokens | ForEach-Object { [regex]::Escape($_) }) -join '|'
Assert-NotContains $readme $mojibakePattern "README should not contain mojibake or replacement characters"
Assert-NotContains $troubleshooting $mojibakePattern "Troubleshooting should not contain mojibake or replacement characters"

Assert-Contains $build 'Ahk2Exe' "Build script should compile with Ahk2Exe"
Assert-Contains $build 'AutoHotkey v2 base executable was not found' "Build script should require an AutoHotkey v2 base executable"
Assert-Contains $build 'dist' "Build script should write to dist"
Assert-Contains $build 'PeekDock.exe' "Build script should produce PeekDock.exe"
Assert-NotContains $build 'config\.ini' "Build script should not bundle local config.ini"
Assert-NotContains $build 'browser-profile' "Build script should not bundle browser profile data"

Assert-Contains $buildInstaller 'PeekDock-Setup.exe' "Installer build script should produce PeekDock-Setup.exe"
Assert-Contains $buildInstaller 'iexpress.exe' "Installer build script should use the Windows IExpress packager"
Assert-Contains $install 'AutoHotkey.AutoHotkey' "Installer should install AutoHotkey v2 when missing"
Assert-Contains $install 'Google.Chrome' "Installer should install Chrome when missing"
Assert-Contains $install 'DesktopDirectory' "Installer should create a Desktop shortcut"

$ahkCandidates = @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe"
)
$ahk = $ahkCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if ($ahk) {
    & $ahk /ErrorStdOut /Validate $scriptPath
    if (-not $?) {
        throw "AutoHotkey /Validate failed"
    }
} else {
    Write-Host "AutoHotkey v2 not found; skipped /Validate."
}

Write-Host "Validation passed."
