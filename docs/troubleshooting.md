# Troubleshooting

## PeekDock starts, but the middle mouse button does nothing

Check that `PeekDock.ahk` is running. If another application captures the middle mouse button globally, close that application or change PeekDock's `MButton::ToggleWindow()` hotkey in `PeekDock.ahk`.

## The dock opens the wrong page

Open the desired page in a normal Chrome window and press `Ctrl + Alt + Shift + B` again.

## The app window cannot be found after Chrome starts

Wait a few seconds and press the middle mouse button again. PeekDock records the app window handle after launch, but Chrome can occasionally take longer to create the visible window.

## The window size or position is wrong

PeekDock does not force a size when restoring the window. Resize and move the Chrome app window manually; subsequent hide/restore actions keep that state.

## Reset everything

1. Exit PeekDock from the AutoHotkey tray icon.
2. Delete `config.ini`.
3. Delete `browser-profile/` if you also want to reset the dedicated Chrome login/session.
4. Start `PeekDock.ahk` again.
