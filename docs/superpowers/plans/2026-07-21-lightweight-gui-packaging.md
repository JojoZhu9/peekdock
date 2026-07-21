# PeekDock Lightweight GUI Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight native AutoHotkey GUI for PeekDock and add one-command exe packaging.

**Architecture:** Keep `PeekDock.ahk` as the single runtime entry point. Add small helper functions inside the script for configuration, dynamic hotkey registration, tray/menu behavior, and native GUI controls, while preserving the existing Chrome app-window control flow.

**Tech Stack:** AutoHotkey v2, Chrome app-window mode, PowerShell validation/build scripts, Ahk2Exe.

## Global Constraints

- Use AutoHotkey v2 as the implementation platform.
- Do not introduce Electron, Tauri, .NET, or a browser-based UI.
- Chrome remains the supported browser.
- Preserve the user's last window size and position by avoiding forced `WinMove` during restore.
- Keep `config.ini` and `browser-profile/` local-only and untracked.
- The compiled exe still depends on Chrome being installed.
- README must be English-first with concise Chinese supplements.

---

## File Structure

- `PeekDock.ahk`: runtime entry point, Chrome window control, GUI, tray, configuration, and dynamic hotkeys.
- `config.example.ini`: documented default configuration including new `[Hotkeys]` and `[Startup]` sections.
- `scripts/build.ps1`: compile `PeekDock.ahk` to `dist/PeekDock.exe` with Ahk2Exe.
- `tests/validate.ps1`: static checks for GUI, configurable hotkeys, build script, and encoding-sensitive README text.
- `README.md`: rewritten UTF-8 English-first user guide with Chinese supplement.
- `docs/troubleshooting.md`: updated troubleshooting for exe, hotkeys, Chrome binding, and startup.

## Task 1: Configurable Hotkeys

**Files:**
- Modify: `PeekDock.ahk`
- Modify: `config.example.ini`
- Modify: `tests/validate.ps1`

**Interfaces:**
- Consumes: existing `ToggleWindow()`, `BindActiveBrowserUrl()`, `ToggleAlwaysOnTop()`.
- Produces:
  - `LoadHotkeys() => Map`
  - `RegisterConfiguredHotkeys() => Boolean`
  - `UpdateHotkey(action, hotkeyText) => Boolean`
  - `FormatHotkeyLabel(hotkeyText) => String`

- [ ] **Step 1: Add failing validation checks**

Add these assertions to `tests/validate.ps1`:

```powershell
Assert-Contains $script 'LoadHotkeys\(\)' "Script should load hotkeys from config.ini"
Assert-Contains $script 'RegisterConfiguredHotkeys\(\)' "Script should register configurable hotkeys"
Assert-Contains $script 'UpdateHotkey\(action, hotkeyText\)' "Script should update hotkeys dynamically"
Assert-Contains $script '\[Hotkeys\]' "Script or config example should include a Hotkeys section"
Assert-Contains $script 'Hotkey\(' "Script should use AutoHotkey v2 dynamic Hotkey registration"
Assert-NotContains $script '^MButton::ToggleWindow\(\)' "Toggle hotkey should be registered from config instead of a hard-coded label"
```

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
```

Expected: FAIL because these functions do not exist yet and hard-coded hotkeys are still present.

- [ ] **Step 2: Replace hard-coded hotkey labels with defaults**

In `PeekDock.ahk`, replace the three top-level hotkey labels with:

```autohotkey
global DefaultHotkeys := Map(
    "ToggleDock", "MButton",
    "BindPage", "^!+b",
    "ToggleTopMost", "^!t"
)
global ConfiguredHotkeys := LoadHotkeys()
```

Call `RegisterConfiguredHotkeys()` after globals are initialized.

- [ ] **Step 3: Implement loading and registering**

Add:

```autohotkey
LoadHotkeys() {
    global ConfigFile, DefaultHotkeys

    hotkeys := Map()
    for action, defaultHotkey in DefaultHotkeys {
        hotkeys[action] := IniRead(ConfigFile, "Hotkeys", action, defaultHotkey)
    }
    return hotkeys
}

RegisterConfiguredHotkeys() {
    global AppName, ConfiguredHotkeys

    bindings := Map(
        "ToggleDock", ToggleWindow,
        "BindPage", BindActiveBrowserUrl,
        "ToggleTopMost", ToggleAlwaysOnTop
    )

    for action, callback in bindings {
        try {
            Hotkey ConfiguredHotkeys[action], callback, "On"
        } catch as err {
            MsgBox("Could not register hotkey for " action ":`n`n" err.Message, AppName)
            return false
        }
    }
    return true
}
```

- [ ] **Step 4: Implement dynamic update**

Add:

```autohotkey
UpdateHotkey(action, hotkeyText) {
    global ConfigFile, ConfiguredHotkeys

    hotkeyText := Trim(hotkeyText)
    if !hotkeyText {
        return false
    }

    oldHotkey := ConfiguredHotkeys[action]
    callback := action = "ToggleDock" ? ToggleWindow
        : action = "BindPage" ? BindActiveBrowserUrl
        : ToggleAlwaysOnTop

    try {
        Hotkey oldHotkey, callback, "Off"
        Hotkey hotkeyText, callback, "On"
    } catch {
        try Hotkey oldHotkey, callback, "On"
        return false
    }

    ConfiguredHotkeys[action] := hotkeyText
    IniWrite hotkeyText, ConfigFile, "Hotkeys", action
    return true
}

FormatHotkeyLabel(hotkeyText) {
    label := StrReplace(hotkeyText, "^", "Ctrl + ")
    label := StrReplace(label, "!", "Alt + ")
    label := StrReplace(label, "+", "Shift + ")
    label := StrReplace(label, "MButton", "Middle Mouse")
    return Trim(label)
}
```

- [ ] **Step 5: Update config example**

Change `config.example.ini` to:

```ini
[Target]
Url=https://example.com/

[Window]
TopMost=1

[Hotkeys]
ToggleDock=MButton
BindPage=^!+b
ToggleTopMost=^!t

[Startup]
RunAtLogin=0

[Runtime]
Hwnd=0
```

- [ ] **Step 6: Verify and commit**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
```

Expected: PASS after the validation script is updated to read both `PeekDock.ahk` and `config.example.ini` for `[Hotkeys]`.

Commit:

```powershell
git add PeekDock.ahk config.example.ini tests/validate.ps1
git commit -m "Add configurable hotkeys"
```

## Task 2: Native GUI and Tray

**Files:**
- Modify: `PeekDock.ahk`
- Modify: `tests/validate.ps1`

**Interfaces:**
- Consumes: `UpdateHotkey(action, hotkeyText)`, `ToggleWindow()`, `BindActiveBrowserUrl()`, `ToggleAlwaysOnTop()`.
- Produces:
  - `BuildMainGui() => Gui`
  - `RefreshMainGui() => Void`
  - `SaveSettingsFromGui(*) => Void`
  - `ConfigureTray() => Void`
  - `ToggleStartup(enabled) => Boolean`
  - `IsStartupEnabled() => Boolean`

- [ ] **Step 1: Add failing GUI and tray checks**

Add these assertions to `tests/validate.ps1`:

```powershell
Assert-Contains $script 'BuildMainGui\(\)' "Script should build a native settings GUI"
Assert-Contains $script 'RefreshMainGui\(\)' "Script should refresh GUI state after actions"
Assert-Contains $script 'SaveSettingsFromGui\(\*\)' "Script should save GUI settings"
Assert-Contains $script 'ConfigureTray\(\)' "Script should configure a tray menu"
Assert-Contains $script 'ToggleStartup\(enabled\)' "Script should support startup-at-login"
Assert-Contains $script 'Gui\(' "Script should use AutoHotkey native GUI"
Assert-Contains $script 'A_TrayMenu' "Script should expose tray actions"
Assert-NotContains $script 'ShowStartupHelp\(\)' "Startup should use the main GUI instead of a help-only message box"
```

Run validation and expect failure.

- [ ] **Step 2: Add main GUI globals and startup flow**

Replace `ShowStartupHelp()` startup call with:

```autohotkey
RegisterConfiguredHotkeys()
ConfigureTray()
global MainGui := BuildMainGui()
MainGui.Show()
```

Add control globals:

```autohotkey
global UrlText := unset
global TopMostCheck := unset
global StartupCheck := unset
global ToggleHotkeyEdit := unset
global BindHotkeyEdit := unset
global TopMostHotkeyEdit := unset
```

- [ ] **Step 3: Build the compact GUI**

Add:

```autohotkey
BuildMainGui() {
    global AppName, UrlText, TopMostCheck, StartupCheck
    global ToggleHotkeyEdit, BindHotkeyEdit, TopMostHotkeyEdit, ConfiguredHotkeys

    gui := Gui("+Resize", AppName)
    gui.SetFont("s10", "Segoe UI")
    gui.AddText("w460", "PeekDock")
    UrlText := gui.AddText("w460 r2", "")
    gui.AddButton("w145", "Bind Current Chrome Tab").OnEvent("Click", (*) => (BindActiveBrowserUrl(), RefreshMainGui()))
    gui.AddButton("x+8 w145", "Show / Hide Dock").OnEvent("Click", (*) => ToggleWindow())
    gui.AddButton("x+8 w145", "Toggle Always On Top").OnEvent("Click", (*) => (ToggleAlwaysOnTop(), RefreshMainGui()))

    TopMostCheck := gui.AddCheckbox("xm y+16", "Always on top")
    StartupCheck := gui.AddCheckbox("x+24", "Start with Windows")

    gui.AddText("xm y+16 w140", "Dock hotkey")
    ToggleHotkeyEdit := gui.AddEdit("x+8 w220", ConfiguredHotkeys["ToggleDock"])
    gui.AddText("xm y+8 w140", "Bind hotkey")
    BindHotkeyEdit := gui.AddEdit("x+8 w220", ConfiguredHotkeys["BindPage"])
    gui.AddText("xm y+8 w140", "Topmost hotkey")
    TopMostHotkeyEdit := gui.AddEdit("x+8 w220", ConfiguredHotkeys["ToggleTopMost"])

    gui.AddButton("xm y+16 w120", "Save").OnEvent("Click", SaveSettingsFromGui)
    gui.AddButton("x+8 w120", "Reset").OnEvent("Click", ResetConfiguration)
    gui.AddButton("x+8 w120", "Exit").OnEvent("Click", (*) => ExitApp())

    gui.OnEvent("Close", (*) => gui.Hide())
    RefreshMainGui()
    return gui
}
```

- [ ] **Step 4: Refresh and save GUI state**

Add:

```autohotkey
RefreshMainGui() {
    global ConfigFile, TopMost, UrlText, TopMostCheck, StartupCheck

    url := IniRead(ConfigFile, "Target", "Url", "")
    UrlText.Text := url ? "Bound page: " url : "No page bound yet."
    TopMostCheck.Value := TopMost ? 1 : 0
    StartupCheck.Value := IsStartupEnabled() ? 1 : 0
}

SaveSettingsFromGui(*) {
    global AppName, ConfigFile, TopMost, TopMostCheck, StartupCheck
    global ToggleHotkeyEdit, BindHotkeyEdit, TopMostHotkeyEdit

    if !UpdateHotkey("ToggleDock", ToggleHotkeyEdit.Value)
        return MsgBox("Dock hotkey could not be saved.", AppName)
    if !UpdateHotkey("BindPage", BindHotkeyEdit.Value)
        return MsgBox("Bind hotkey could not be saved.", AppName)
    if !UpdateHotkey("ToggleTopMost", TopMostHotkeyEdit.Value)
        return MsgBox("Topmost hotkey could not be saved.", AppName)

    TopMost := TopMostCheck.Value = 1
    IniWrite TopMost ? "1" : "0", ConfigFile, "Window", "TopMost"
    ToggleStartup(StartupCheck.Value = 1)
    RefreshMainGui()
    MsgBox("Settings saved.", AppName)
}
```

- [ ] **Step 5: Add tray and startup helpers**

Add:

```autohotkey
ConfigureTray() {
    global AppName

    A_TrayMenu.Delete()
    A_TrayMenu.Add("Show Settings", (*) => MainGui.Show())
    A_TrayMenu.Add("Show / Hide Dock", (*) => ToggleWindow())
    A_TrayMenu.Add("Bind Current Chrome Tab", (*) => (BindActiveBrowserUrl(), RefreshMainGui()))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_IconTip := AppName
}

StartupShortcutPath() {
    global AppName
    return A_Startup "\" AppName ".lnk"
}

IsStartupEnabled() {
    return FileExist(StartupShortcutPath()) ? true : false
}

ToggleStartup(enabled) {
    shortcut := StartupShortcutPath()
    if enabled {
        FileCreateShortcut A_ScriptFullPath, shortcut, A_ScriptDir
    } else if FileExist(shortcut) {
        FileDelete shortcut
    }
    IniWrite enabled ? "1" : "0", ConfigFile, "Startup", "RunAtLogin"
    return true
}
```

- [ ] **Step 6: Replace reset/help behavior**

Add:

```autohotkey
ResetConfiguration(*) {
    global AppName, ConfigFile, ConfiguredHotkeys

    if MsgBox("Reset PeekDock settings?", AppName, "YesNo Icon?") != "Yes"
        return
    if FileExist(ConfigFile)
        FileDelete ConfigFile
    ConfiguredHotkeys := LoadHotkeys()
    MsgBox("Settings reset. Restart PeekDock to reload hotkeys cleanly.", AppName)
}
```

- [ ] **Step 7: Verify and commit**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
```

Expected: PASS.

Run AutoHotkey validation:

```powershell
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut /Validate .\PeekDock.ahk
```

Expected: no parser errors.

Commit:

```powershell
git add PeekDock.ahk tests/validate.ps1
git commit -m "Add lightweight settings GUI"
```

## Task 3: Build Script

**Files:**
- Create: `scripts/build.ps1`
- Modify: `tests/validate.ps1`

**Interfaces:**
- Produces: `dist/PeekDock.exe` when AutoHotkey v2 and Ahk2Exe are installed.

- [ ] **Step 1: Add failing build-script checks**

Add to `tests/validate.ps1`:

```powershell
$buildPath = Join-Path $root "scripts\build.ps1"
if (-not (Test-Path $buildPath)) {
    throw "Missing scripts/build.ps1"
}
$build = Get-Content -Raw $buildPath
Assert-Contains $build 'Ahk2Exe' "Build script should compile with Ahk2Exe"
Assert-Contains $build 'dist' "Build script should write to dist"
Assert-Contains $build 'PeekDock.exe' "Build script should produce PeekDock.exe"
Assert-NotContains $build 'config\.ini' "Build script should not bundle local config.ini"
Assert-NotContains $build 'browser-profile' "Build script should not bundle browser profile data"
```

Run validation and expect failure.

- [ ] **Step 2: Create the build script**

Create `scripts/build.ps1`:

```powershell
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root "PeekDock.ahk"
$dist = Join-Path $root "dist"
$output = Join-Path $dist "PeekDock.exe"

$candidates = @(
    "$env:LOCALAPPDATA\Programs\AutoHotkey\Compiler\Ahk2Exe.exe",
    "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\Compiler\Ahk2Exe.exe"
)

$compiler = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $compiler) {
    throw "Ahk2Exe.exe was not found. Install AutoHotkey v2, then run this script again."
}

if (-not (Test-Path $source)) {
    throw "Missing PeekDock.ahk"
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
& $compiler /in $source /out $output /base "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"

if (-not (Test-Path $output)) {
    throw "Build failed: dist\PeekDock.exe was not created."
}

Write-Host "Built $output"
```

- [ ] **Step 3: Verify and commit**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
```

Expected: PASS.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

Expected when Ahk2Exe is installed: `dist\PeekDock.exe` exists. Expected when Ahk2Exe is missing: helpful failure message.

Commit:

```powershell
git add scripts/build.ps1 tests/validate.ps1
git commit -m "Add exe build script"
```

## Task 4: Documentation and Final Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/troubleshooting.md`
- Modify: `tests/validate.ps1`

**Interfaces:**
- Consumes: completed GUI and build behavior.
- Produces: clean UTF-8 English-first documentation.

- [ ] **Step 1: Add documentation validation checks**

Add to `tests/validate.ps1`:

```powershell
Assert-Contains $readme '## Quick Start' "README should include Quick Start"
Assert-Contains $readme '## Build an exe' "README should explain exe packaging"
Assert-Contains $readme '## 中文补充' "README should include concise Chinese supplement"
Assert-Contains $readme 'Bind Current Chrome Tab' "README should document GUI binding"
Assert-Contains $readme 'Start with Windows' "README should document startup option"
Assert-NotContains $readme '鏄|榧|涓|缃' "README should not contain mojibake"
```

Run validation and expect failure until README is rewritten.

- [ ] **Step 2: Rewrite README**

Rewrite `README.md` with these sections:

```markdown
# PeekDock

PeekDock is a lightweight Windows utility that turns one Chrome page into a dedicated dock window. It can bind the URL from your active Chrome tab, open it as a Chrome app window, and show or hide that window without disturbing your normal browser windows.

## Features

- Bind the current Chrome tab instead of hard-coding a URL.
- Show, hide, and restore one dedicated Chrome app window.
- Keep the page state alive by hiding instead of closing.
- Configure hotkeys from a small native settings window.
- Toggle always-on-top.
- Start with Windows.
- Build a standalone exe with AutoHotkey v2.

## Quick Start

1. Install AutoHotkey v2 if you want to run from source.
2. Run `PeekDock.ahk`, or run `dist/PeekDock.exe` after building.
3. Open the target page in Chrome.
4. Resize and position the Chrome window the way you want.
5. Click `Bind Current Chrome Tab`.
6. Use the configured dock hotkey to show or hide PeekDock.

## Default Hotkeys

| Action | Default |
| --- | --- |
| Show / hide / restore dock | Middle mouse button |
| Bind current Chrome tab | `Ctrl + Alt + Shift + B` |
| Toggle always-on-top | `Ctrl + Alt + T` |

## Build an exe

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

The executable is written to `dist\PeekDock.exe`.

## 中文补充

PeekDock 是一个轻量 Windows 小工具，用来把当前 Chrome 页面绑定成独立小窗。你可以在设置窗口里绑定页面、修改快捷键、切换置顶和开机自启。打包后的 `PeekDock.exe` 不需要用户额外安装 AutoHotkey，但仍然需要电脑上有 Chrome。

## Privacy

PeekDock stores the bound URL, hotkeys, startup preference, and runtime window handle in local `config.ini`. The dedicated Chrome profile lives in `browser-profile/`. Both are excluded from Git.

## License

MIT
```

- [ ] **Step 3: Update troubleshooting**

Ensure `docs/troubleshooting.md` covers:

```markdown
# Troubleshooting

## The dock hotkey does nothing

Open the PeekDock settings window from the tray and confirm the hotkey field is valid AutoHotkey v2 syntax.

## Binding fails

Activate a normal Chrome tab first, then click `Bind Current Chrome Tab` or use the bind hotkey.

## The exe does not start

Build again with AutoHotkey v2 installed. The compiled app still requires Chrome to be installed.

## Start with Windows does not work

Toggle `Start with Windows` off and on again. PeekDock creates a shortcut in the current user's Startup folder and does not require administrator permissions.
```

- [ ] **Step 4: Final verification**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
```

Expected: PASS.

Run:

```powershell
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut /Validate .\PeekDock.ahk
```

Expected: no parser errors.

Run:

```powershell
git status --short
```

Expected: only intentional files changed before commit; no `config.ini`, `browser-profile/`, `dist/`, or local profile files staged.

- [ ] **Step 5: Commit**

```powershell
git add README.md docs/troubleshooting.md tests/validate.ps1
git commit -m "Refresh documentation for GUI release"
```

