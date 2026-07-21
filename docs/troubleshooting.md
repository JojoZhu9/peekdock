# Troubleshooting

## The dock hotkey does nothing

Open the PeekDock settings window from the tray and confirm the dock hotkey field uses valid AutoHotkey v2 syntax. If another app captures the same global hotkey, choose a different dock hotkey and save settings.

## Binding fails

Activate a normal Chrome tab first, then click `Bind Current Chrome Tab` or use the bind hotkey. PeekDock binds the current Chrome window itself; it does not create a duplicate app window.

## The exe does not start

Build again with AutoHotkey v2 installed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

The compiled app still requires Chrome to be installed. If Windows blocks the exe after download or transfer, unblock it from the file properties dialog and try again.

## Start with Windows does not work

Toggle `Start with Windows` off and on again. PeekDock creates a shortcut in the current user's Startup folder and does not require administrator permissions.

## Reset everything

1. Exit PeekDock from the tray menu.
2. Delete `config.ini`.
3. Delete `browser-profile/` if you also want to reset the dedicated Chrome login/session.
4. Start `PeekDock.ahk` or `dist\PeekDock.exe` again.
