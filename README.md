# PeekDock

PeekDock 是一个基于 AutoHotkey v2 的 Chrome 专用网页小窗工具。它把你选定的网页变成一个独立 Chrome 应用窗口，并用鼠标中键快速打开、隐藏或恢复，不影响其他浏览器窗口。

## 适合什么场景

- 常驻一个网页工具、视频页、仪表盘或聊天页。
- 希望网页保持登录状态、播放状态和输入状态。
- 想用一个轻量快捷键控制小窗，而不是在多个浏览器窗口里找标签页。

## 功能

- 使用 Chrome `--app` 模式打开独立网页窗口。
- 使用独立 `browser-profile/` 配置目录，和普通 Chrome 会话隔离。
- 绑定当前 Chrome 标签页 URL，不需要在脚本里写死网址。
- 鼠标中键打开、隐藏或恢复小窗。
- 恢复时保持你上次调整过的窗口大小和位置。
- 可切换始终置顶。

## 安装要求

- Windows
- Google Chrome
- [AutoHotkey v2](https://www.autohotkey.com/)

## 快速开始

1. 安装 AutoHotkey v2。
2. 双击运行 `PeekDock.ahk`。
3. 在普通 Chrome 窗口中打开目标网页。
4. 先把 Chrome 窗口调整到你想要的位置和大小。
5. 按 `Ctrl + Alt + Shift + B` 绑定当前标签页。
6. 按鼠标中键打开、隐藏或恢复 PeekDock。

## 快捷键

| 快捷键 | 功能 |
| --- | --- |
| 鼠标中键 | 打开 / 隐藏 / 恢复小窗 |
| `Ctrl + Alt + Shift + B` | 绑定当前 Chrome 标签页 URL |
| `Ctrl + Alt + T` | 切换小窗始终置顶 |

## 项目文件

| 文件 | 用途 |
| --- | --- |
| `PeekDock.ahk` | 主脚本 |
| `tests/validate.ps1` | 静态校验脚本 |
| `config.ini` | 本地运行配置，自动生成，不应提交 |
| `browser-profile/` | 独立 Chrome 用户配置，自动生成，不应提交 |

## 验证

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
```

如果本机已安装 AutoHotkey v2，也可以运行：

```powershell
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut /Validate .\PeekDock.ahk
```

## 开机自启

按 `Win + R`，输入：

```text
shell:startup
```

把 `PeekDock.ahk` 的快捷方式放进去即可。
