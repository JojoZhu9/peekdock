# Contributing

Thanks for improving PeekDock.

## Development Setup

1. Install AutoHotkey v2.
2. Clone the repository.
3. Edit `PeekDock.ahk`.
4. Run validation before opening a pull request.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut /Validate .\PeekDock.ahk
```

## Guidelines

- Keep the script lightweight and dependency-free.
- Do not commit `config.ini` or `browser-profile/`.
- Prefer stable AutoHotkey v2 APIs.
- Keep hotkey changes documented in `README.md` and `tests/validate.ps1`.
- Add focused validation rules for behavior that has regressed before.

## Pull Requests

Please include:

- What changed.
- Why the change is useful.
- How you verified it.
