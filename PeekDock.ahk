#Requires AutoHotkey v2.0
#SingleInstance Force

; PeekDock controls one dedicated Chrome app window.
; Hotkeys:
;   Ctrl+Alt+Shift+B  bind the active Chrome tab URL
;   Middle mouse      show/hide/open the bound app window
;   Ctrl+Alt+T        toggle always-on-top

Persistent
SetTitleMatchMode 2
DetectHiddenWindows True

global AppName := "PeekDock"
global ConfigFile := A_ScriptDir "\config.ini"
global ProfileDir := A_ScriptDir "\browser-profile"
global TopMost := IniRead(ConfigFile, "Window", "TopMost", "1") = "1"
global AppWindowHwnd := Integer(IniRead(ConfigFile, "Runtime", "Hwnd", "0"))

MButton::ToggleWindow()
^!+b::BindActiveBrowserUrl()
^!t::ToggleAlwaysOnTop()

ShowStartupHelp()

ShowStartupHelp() {
    global AppName

    MsgBox(
        "PeekDock is running.`n`n"
        . "First resize and position the Chrome window the way you want, then bind the page.`n`n"
        . "Middle mouse: open / hide / restore the dock`n"
        . "Ctrl + Alt + Shift + B: bind the active Chrome tab`n"
        . "Ctrl + Alt + T: toggle always-on-top",
        AppName
    )
}

ToggleWindow() {
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
            . "Open the target page in Chrome, then press Ctrl + Alt + Shift + B.",
            AppName
        )
        return
    }

    LaunchAppWindow(url)
}

BindActiveBrowserUrl() {
    if !WinActive("ahk_exe chrome.exe") {
        MsgBox(
            "Activate a Chrome tab first, then press Ctrl + Alt + Shift + B.",
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
    MsgBox(
        "Bound page:`n`n" url "`n`n"
        . "Use the middle mouse button to open or hide the dock.",
        AppName
    )
}

ToggleAlwaysOnTop() {
    global TopMost

    hwnd := FindAppWindow()
    TopMost := !TopMost
    IniWrite TopMost ? "1" : "0", ConfigFile, "Window", "TopMost"

    if hwnd {
        WinSetAlwaysOnTop(TopMost ? 1 : 0, "ahk_id " hwnd)
    }

    MsgBox("Always-on-top: " (TopMost ? "On" : "Off"), AppName)
}

LaunchAppWindow(url) {
    global ProfileDir

    DirCreate ProfileDir

    chromePath := FindChromePath()
    safeUrl := StrReplace(url, '"', "%22")
    command := '"' chromePath '" --user-data-dir="' ProfileDir '" --app="' safeUrl '"'

    Run(command,,, &pid)

    hwnd := WaitForAppWindow(pid, 8)
    if hwnd {
        RememberAppWindow(hwnd)
        RestoreAppWindow(hwnd)
    } else {
        MsgBox(
            "Chrome started, but PeekDock could not find the app window yet.`n`n"
            . "Wait a moment, then press the middle mouse button again.",
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
    global AppWindowHwnd

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
    global AppWindowHwnd

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

    return "chrome.exe"
}
