#Requires AutoHotkey v2.0
#SingleInstance Force

; PeekDock controls one dedicated Chrome app window.
; Default hotkeys:
;   Middle mouse             show / hide / restore the dock
;   Ctrl + Alt + Shift + B   bind the active Chrome tab URL
;   Ctrl + Alt + T           toggle always-on-top

Persistent
SetTitleMatchMode 2
DetectHiddenWindows True

global AppName := "PeekDock"
global ConfigFile := A_ScriptDir "\config.ini"
global ProfileDir := A_ScriptDir "\browser-profile"
global TopMost := IniRead(ConfigFile, "Window", "TopMost", "1") = "1"
global AppWindowHwnd := Integer(IniRead(ConfigFile, "Runtime", "Hwnd", "0"))
global DefaultHotkeys := Map(
    "ToggleDock", "MButton",
    "BindPage", "^!+b",
    "ToggleTopMost", "^!t"
)
global ConfiguredHotkeys := LoadHotkeys()
global MainGui := ""
global UrlText := ""
global TopMostCheck := ""
global StartupCheck := ""
global ToggleHotkeyEdit := ""
global BindHotkeyEdit := ""
global TopMostHotkeyEdit := ""

RegisterConfiguredHotkeys()
MainGui := BuildMainGui()
ConfigureTray()
MainGui.Show()

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
            Hotkey(ConfiguredHotkeys[action], callback, "On")
        } catch as err {
            MsgBox("Could not register hotkey for " action ":`n`n" err.Message, AppName)
            return false
        }
    }
    return true
}

UpdateHotkey(action, hotkeyText) {
    global ConfigFile, ConfiguredHotkeys

    hotkeyText := Trim(hotkeyText)
    if !hotkeyText {
        return false
    }

    oldHotkey := ConfiguredHotkeys[action]
    callback := GetHotkeyCallback(action)

    try {
        Hotkey(oldHotkey, "Off")
    } catch {
        ; Invalid existing config should not prevent recovery through the GUI.
    }

    try {
        Hotkey(hotkeyText, callback, "On")
    } catch {
        try {
            Hotkey(oldHotkey, callback, "On")
        }
        return false
    }

    ConfiguredHotkeys[action] := hotkeyText
    IniWrite hotkeyText, ConfigFile, "Hotkeys", action
    return true
}

UpdateHotkeys(newHotkeys) {
    global AppName

    seen := Map()
    for action, hotkeyText in newHotkeys {
        hotkeyText := Trim(hotkeyText)
        if !hotkeyText {
            MsgBox("Hotkey for " action " cannot be empty.", AppName)
            return false
        }

        normalized := CanonicalizeHotkey(hotkeyText)
        if seen.Has(normalized) {
            MsgBox("Duplicate hotkey: " hotkeyText "`n`nChoose a different key for each action.", AppName)
            return false
        }
        seen[normalized] := action
    }

    registered := []
    for action, oldHotkey in ConfiguredHotkeys {
        try {
            Hotkey(oldHotkey, "Off")
        }
    }

    for action, hotkeyText in newHotkeys {
        callback := GetHotkeyCallback(action)
        try {
            Hotkey(Trim(hotkeyText), callback, "On")
            registered.Push(action)
        } catch {
            for registeredAction in registered {
                try {
                    Hotkey(Trim(newHotkeys[registeredAction]), "Off")
                }
            }
            for oldAction, oldHotkey in ConfiguredHotkeys {
                try {
                    Hotkey(oldHotkey, GetHotkeyCallback(oldAction), "On")
                }
            }
            MsgBox("Hotkey for " action " could not be saved.", AppName)
            return false
        }
    }

    for action, hotkeyText in newHotkeys {
        ConfiguredHotkeys[action] := Trim(hotkeyText)
        IniWrite Trim(hotkeyText), ConfigFile, "Hotkeys", action
    }
    return true
}

CanonicalizeHotkey(hotkeyText) {
    text := StrLower(StrReplace(Trim(hotkeyText), " ", ""))
    pos := 1
    flags := Map("*", false, "~", false, "$", false)
    modifiers := Map("^", false, "!", false, "+", false, "#", false)

    while pos <= StrLen(text) {
        one := SubStr(text, pos, 1)
        if flags.Has(one) {
            flags[one] := true
            pos += 1
            continue
        }
        if modifiers.Has(one) {
            modifiers[one] := true
            pos += 1
            continue
        }
        break
    }

    keyName := SubStr(text, pos)
    canonical := ""
    for flag in ["*", "~", "$"] {
        if flags[flag] {
            canonical .= flag
        }
    }
    for modifier in ["^", "!", "+", "#"] {
        if modifiers[modifier] {
            canonical .= modifier
        }
    }
    return canonical keyName
}

GetHotkeyCallback(action) {
    if action = "ToggleDock" {
        return ToggleWindow
    }
    if action = "BindPage" {
        return BindActiveBrowserUrl
    }
    return ToggleAlwaysOnTop
}

FormatHotkeyLabel(hotkeyText) {
    label := StrReplace(hotkeyText, "^", "Ctrl + ")
    label := StrReplace(label, "!", "Alt + ")
    label := StrReplace(label, "+", "Shift + ")
    label := StrReplace(label, "MButton", "Middle Mouse")
    return Trim(label)
}

BuildMainGui() {
    global AppName, UrlText, TopMostCheck, StartupCheck
    global ToggleHotkeyEdit, BindHotkeyEdit, TopMostHotkeyEdit, ConfiguredHotkeys

    mainWindow := Gui("+Resize", AppName)
    mainWindow.SetFont("s10", "Segoe UI")
    mainWindow.MarginX := 16
    mainWindow.MarginY := 14

    mainWindow.SetFont("s16 Bold", "Segoe UI")
    mainWindow.AddText("w460", AppName)
    mainWindow.SetFont("s9 Norm", "Segoe UI")
    mainWindow.AddText("w460", "Bind one Chrome page, then keep it one hotkey away.")
    UrlText := mainWindow.AddText("w460 r2 y+10", "")

    mainWindow.AddButton("xm y+10 w145 h30", "Bind Current Chrome Tab")
        .OnEvent("Click", (*) => (BindActiveBrowserUrl(), RefreshMainGui()))
    mainWindow.AddButton("x+8 w145 h30", "Show / Hide Dock")
        .OnEvent("Click", (*) => ToggleWindow())
    mainWindow.AddButton("x+8 w145 h30", "Toggle Always On Top")
        .OnEvent("Click", (*) => (ToggleAlwaysOnTop(), RefreshMainGui()))

    TopMostCheck := mainWindow.AddCheckbox("xm y+16", "Always on top")
    StartupCheck := mainWindow.AddCheckbox("x+24", "Start with Windows")

    mainWindow.AddText("xm y+16 w140", "Dock hotkey")
    ToggleHotkeyEdit := mainWindow.AddEdit("x+8 w220", ConfiguredHotkeys["ToggleDock"])
    mainWindow.AddText("xm y+8 w140", "Bind hotkey")
    BindHotkeyEdit := mainWindow.AddEdit("x+8 w220", ConfiguredHotkeys["BindPage"])
    mainWindow.AddText("xm y+8 w140", "Topmost hotkey")
    TopMostHotkeyEdit := mainWindow.AddEdit("x+8 w220", ConfiguredHotkeys["ToggleTopMost"])

    mainWindow.AddButton("xm y+16 w120 h30", "Save").OnEvent("Click", SaveSettingsFromGui)
    mainWindow.AddButton("x+8 w120 h30", "Reset").OnEvent("Click", ResetConfiguration)
    mainWindow.AddButton("x+8 w120 h30", "Exit").OnEvent("Click", (*) => ExitApp())

    mainWindow.OnEvent("Close", (*) => mainWindow.Hide())
    RefreshMainGui()
    return mainWindow
}

RefreshMainGui() {
    global ConfigFile, TopMost, UrlText, TopMostCheck, StartupCheck

    if !IsObject(UrlText) {
        return
    }

    url := IniRead(ConfigFile, "Target", "Url", "")
    UrlText.Text := url ? "Bound page: " url : "No page bound yet. Open Chrome, resize it, then bind the page."
    TopMostCheck.Value := TopMost ? 1 : 0
    StartupCheck.Value := IsStartupEnabled() ? 1 : 0
}

SaveSettingsFromGui(*) {
    global AppName, ConfigFile, TopMost, TopMostCheck, StartupCheck
    global ToggleHotkeyEdit, BindHotkeyEdit, TopMostHotkeyEdit

    newHotkeys := Map(
        "ToggleDock", ToggleHotkeyEdit.Value,
        "BindPage", BindHotkeyEdit.Value,
        "ToggleTopMost", TopMostHotkeyEdit.Value
    )

    if !UpdateHotkeys(newHotkeys) {
        return
    }

    TopMost := TopMostCheck.Value = 1
    IniWrite TopMost ? "1" : "0", ConfigFile, "Window", "TopMost"
    ToggleStartup(StartupCheck.Value = 1)
    RefreshMainGui()
    MsgBox("Settings saved.", AppName)
}

ConfigureTray() {
    global AppName, MainGui

    A_TrayMenu.Delete()
    A_TrayMenu.Add("Show Settings", (*) => MainGui.Show())
    A_TrayMenu.Add("Show / Hide Dock", (*) => ToggleWindow())
    A_TrayMenu.Add("Bind Current Chrome Tab", (*) => (BindActiveBrowserUrl(), RefreshMainGui()))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.Default := "Show Settings"
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
    global ConfigFile

    shortcut := StartupShortcutPath()
    if enabled {
        FileCreateShortcut A_ScriptFullPath, shortcut, A_ScriptDir
    } else if FileExist(shortcut) {
        FileDelete shortcut
    }
    IniWrite enabled ? "1" : "0", ConfigFile, "Startup", "RunAtLogin"
    return true
}

ResetConfiguration(*) {
    global AppName, ConfigFile, ConfiguredHotkeys

    if MsgBox("Reset PeekDock settings?", AppName, "YesNo Icon?") != "Yes" {
        return
    }
    if FileExist(ConfigFile) {
        FileDelete ConfigFile
    }
    ConfiguredHotkeys := LoadHotkeys()
    MsgBox("Settings reset. Restart PeekDock to reload hotkeys cleanly.", AppName)
    RefreshMainGui()
}

ToggleWindow(*) {
    global AppName, ConfigFile

    hwnd := FindAppWindow()

    if hwnd {
        if IsWindowVisible(hwnd) {
            WinHide("ahk_id " hwnd)
            return
        }

        RestoreAppWindow(hwnd)
        return
    }

    url := IniRead(ConfigFile, "Target", "Url", "")
    if !url {
        MsgBox(
            "No page is bound yet.`n`n"
            . "Open the target page in Chrome, resize and position it, then bind the page.",
            AppName
        )
        return
    }

    LaunchAppWindow(url)
}

BindActiveBrowserUrl(*) {
    global AppName, ConfigFile, ConfiguredHotkeys

    if !WinActive("ahk_exe chrome.exe") {
        MsgBox(
            "Activate a Chrome tab first, then bind the current page.",
            AppName
        )
        return
    }

    oldClipboard := ClipboardAll()
    A_Clipboard := ""

    Send "^l"
    Sleep 80
    Send "^c"
    Send "{Esc}"

    if !ClipWait(1) {
        A_Clipboard := oldClipboard
        MsgBox("Could not read the address bar. Please try again.", AppName)
        return
    }

    url := Trim(A_Clipboard)
    A_Clipboard := oldClipboard

    if !IsSupportedUrl(url) {
        MsgBox("The copied text does not look like a supported URL:`n`n" url, AppName)
        return
    }

    IniWrite url, ConfigFile, "Target", "Url"
    RefreshMainGui()
    MsgBox(
        "Bound page:`n`n" url "`n`n"
        . "Use " FormatHotkeyLabel(ConfiguredHotkeys["ToggleDock"]) " to open or hide the dock.",
        AppName
    )
}

ToggleAlwaysOnTop(*) {
    global AppName, TopMost, ConfigFile

    hwnd := FindAppWindow()
    TopMost := !TopMost
    IniWrite TopMost ? "1" : "0", ConfigFile, "Window", "TopMost"

    if hwnd {
        WinSetAlwaysOnTop(TopMost ? 1 : 0, "ahk_id " hwnd)
    }

    RefreshMainGui()
    MsgBox("Always-on-top: " (TopMost ? "On" : "Off"), AppName)
}

LaunchAppWindow(url) {
    global AppName, ProfileDir

    DirCreate ProfileDir

    chromePath := FindChromePath()
    if !chromePath {
        MsgBox("Chrome cannot be found. Install Google Chrome, then try again.", AppName)
        return
    }

    safeUrl := StrReplace(url, '"', "%22")
    command := '"' chromePath '" --user-data-dir="' ProfileDir '" --app="' safeUrl '"'

    try {
        Run(command,,, &pid)
    } catch as err {
        MsgBox("Chrome could not be started:`n`n" err.Message, AppName)
        return
    }

    hwnd := WaitForAppWindow(pid, 8)
    if hwnd {
        RememberAppWindow(hwnd)
        RestoreAppWindow(hwnd)
    } else {
        MsgBox(
            "Chrome started, but PeekDock could not find the app window yet.`n`n"
            . "Wait a moment, then use the dock hotkey again.",
            AppName
        )
    }
}

RestoreAppWindow(hwnd) {
    global TopMost

    WinShow("ahk_id " hwnd)
    WinRestore("ahk_id " hwnd)
    WinSetAlwaysOnTop(TopMost ? 1 : 0, "ahk_id " hwnd)
    WinActivate("ahk_id " hwnd)
}

WaitForAppWindow(pid, seconds) {
    deadline := A_TickCount + seconds * 1000

    while A_TickCount < deadline {
        hwnd := FindChromeWindowByPid(pid)
        if hwnd {
            return hwnd
        }
        Sleep 150
    }

    return 0
}

FindAppWindow() {
    global AppWindowHwnd, ConfigFile

    if AppWindowHwnd && WinExist("ahk_id " AppWindowHwnd) {
        return AppWindowHwnd
    }

    savedHwnd := Integer(IniRead(ConfigFile, "Runtime", "Hwnd", "0"))
    if savedHwnd && WinExist("ahk_id " savedHwnd) {
        AppWindowHwnd := savedHwnd
        return savedHwnd
    }

    return 0
}

FindChromeWindowByPid(pid) {
    if !pid {
        return 0
    }

    for hwnd in WinGetList("ahk_pid " pid) {
        try {
            title := WinGetTitle("ahk_id " hwnd)
            className := WinGetClass("ahk_id " hwnd)
            if title && className = "Chrome_WidgetWin_1" {
                return hwnd
            }
        }
    }

    return 0
}

RememberAppWindow(hwnd) {
    global AppWindowHwnd, ConfigFile

    AppWindowHwnd := hwnd
    IniWrite hwnd, ConfigFile, "Runtime", "Hwnd"
}

IsWindowVisible(hwnd) {
    return (WinGetStyle("ahk_id " hwnd) & 0x10000000) != 0
}

IsSupportedUrl(value) {
    return RegExMatch(value, "i)^(https?://|file://|chrome-extension://)")
}

FindChromePath() {
    localAppData := EnvGet("LOCALAPPDATA")
    candidates := [
        A_ProgramFiles "\Google\Chrome\Application\chrome.exe",
        A_ProgramFiles " (x86)\Google\Chrome\Application\chrome.exe",
        localAppData "\Google\Chrome\Application\chrome.exe"
    ]

    for path in candidates {
        if FileExist(path) {
            return path
        }
    }

    try {
        pathFromShell := RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe", "")
        if pathFromShell && FileExist(pathFromShell) {
            return pathFromShell
        }
    }

    return ""
}
