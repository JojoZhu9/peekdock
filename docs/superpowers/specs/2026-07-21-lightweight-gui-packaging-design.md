# PeekDock Lightweight GUI and Packaging Design

Date: 2026-07-21

## Goal

Turn PeekDock from a script-first AutoHotkey utility into a lightweight Windows desktop tool that can still be run as source, but can also be distributed as a single executable. The first GUI version should stay small, fast, and practical.

## Scope

This version keeps AutoHotkey v2 as the implementation platform. It does not introduce Electron, Tauri, .NET, or a browser-based UI. Chrome remains the supported browser for binding and launching the dedicated app window.

The release should provide:

- A native AutoHotkey GUI for startup and operation.
- Configurable hotkeys persisted in `config.ini`.
- A build script that compiles `PeekDock.ahk` into `dist/PeekDock.exe` with Ahk2Exe.
- Updated README and troubleshooting documentation with clean UTF-8 text.

## User Experience

On launch, PeekDock shows a compact main window instead of only a message box. The window presents the product name, the current binding status, and the most important controls.

The main page includes:

- Current bound URL, or an unbound state.
- `Bind Current Chrome Tab` action.
- `Show / Hide Dock` action.
- Always-on-top toggle.
- Startup-at-login toggle.
- Hotkey settings for:
  - Show / hide / restore dock.
  - Bind current Chrome tab.
  - Toggle always-on-top.
- Reset configuration action.

Closing the main window should hide it rather than exit the app. The app remains available from the tray. The tray menu should include show settings, show or hide dock, bind current tab, and exit.

## Hotkey Model

The current hard-coded hotkeys become configurable values:

- Toggle dock default: middle mouse button.
- Bind current Chrome tab default: `Ctrl + Alt + Shift + B`.
- Toggle always-on-top default: `Ctrl + Alt + T`.

Hotkeys are loaded from `config.ini` on startup and registered dynamically. When the user changes a hotkey in the GUI, PeekDock unregisters the old hotkey, registers the new one, writes it to config, and shows a clear error if the requested hotkey is invalid or already unavailable.

The first version can accept AutoHotkey hotkey syntax in text fields, with friendly labels beside the defaults. A richer key-capture widget can be added later if needed.

## Window Control Behavior

The existing Chrome app-window behavior remains:

- Bind the active Chrome tab by copying the address bar URL.
- Launch Chrome with `--app` and a dedicated `browser-profile/`.
- Hide and restore the app window instead of closing it.
- Preserve the user's last window size and position by avoiding forced `WinMove` during restore.
- Apply always-on-top when enabled.

## Configuration

`config.ini` remains local-only and untracked. Existing settings are preserved where possible.

Expected sections:

- `[Target]`: bound URL.
- `[Window]`: always-on-top setting.
- `[Hotkeys]`: user-configurable hotkeys.
- `[Startup]`: startup-at-login setting.
- `[Runtime]`: transient window handle.

Startup-at-login should be implemented by creating or removing a shortcut in the Windows Startup folder. It should not require administrator privileges.

## Packaging

Add `scripts/build.ps1`.

The build script should:

- Locate AutoHotkey v2 and Ahk2Exe in common install locations.
- Compile `PeekDock.ahk` into `dist/PeekDock.exe`.
- Fail with a helpful message if AutoHotkey v2 or Ahk2Exe is missing.
- Avoid bundling `config.ini` or `browser-profile/`.

The compiled exe still depends on Chrome being installed.

## Error Handling

The GUI should surface errors in concise message boxes:

- Chrome is not active when binding.
- The copied address is not a supported URL.
- Chrome cannot be found.
- A configured hotkey cannot be registered.
- Ahk2Exe is missing during packaging.

Unexpected runtime failures should not corrupt `config.ini`.

## Documentation

Update README as English-first with concise Chinese supplements. It should cover:

- What PeekDock does.
- Download or build options.
- Running from source.
- Running the compiled exe.
- Binding a page.
- Changing hotkeys.
- Startup-at-login.
- Privacy and local data.

Fix the current README encoding issue so Chinese text renders correctly.

## Verification

Validation should include:

- Existing PowerShell validation script updated for configurable hotkeys and GUI strings.
- AutoHotkey v2 `/Validate` against `PeekDock.ahk`.
- Build script dry run or real compile when Ahk2Exe is available.
- Manual smoke path:
  - Launch app.
  - Bind active Chrome tab.
  - Toggle dock with default hotkey.
  - Change a hotkey.
  - Restart and confirm the changed hotkey persists.

## Non-Goals

This version will not:

- Support browsers other than Chrome.
- Build a custom skinned modern UI.
- Add automatic update checks.
- Publish a signed installer.
- Rewrite history or alter unrelated repository metadata.
