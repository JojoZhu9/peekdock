# Security Policy

## Supported Versions

PeekDock is a small script project. Security updates target the latest version on `main`.

## Reporting a Vulnerability

Please open a private security advisory on GitHub or contact the repository owner.

Do not include personal URLs, cookies, exported Chrome profiles, or screenshots containing private web content in public issues.

## Local Data

PeekDock stores runtime data locally:

- `config.ini` stores the bound URL, always-on-top setting, and window handle.
- `browser-profile/` stores the dedicated Chrome profile created by Chrome.

Both paths are ignored by Git.
