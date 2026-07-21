$ErrorActionPreference = "Stop"

$appName = "PeekDock"
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDir = Join-Path $env:LOCALAPPDATA $appName
$scriptSource = Join-Path $sourceDir "PeekDock.ahk"
$iconSource = Join-Path $sourceDir "peekdock.ico"
$scriptTarget = Join-Path $installDir "PeekDock.ahk"
$iconTarget = Join-Path $installDir "peekdock.ico"

function Show-Message {
    param(
        [string]$Text,
        [int]$Icon = 64
    )

    $shell = New-Object -ComObject WScript.Shell
    $null = $shell.Popup($Text, 0, $appName, $Icon)
}

function Find-Chrome {
    $paths = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
    )

    foreach ($path in $paths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    $appPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe"
    if (Test-Path $appPath) {
        $value = (Get-ItemProperty $appPath)."(default)"
        if ($value -and (Test-Path $value)) {
            return $value
        }
    }

    return $null
}

function Find-AutoHotkey {
    $paths = @(
        "${env:LOCALAPPDATA}\Programs\AutoHotkey\v2\AutoHotkey64.exe",
        "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe"
    )

    foreach ($path in $paths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    return $null
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Name
    )

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw "winget.exe was not found. Install $Name manually, then run PeekDock setup again."
    }

    Write-Host "Installing $Name..."
    & $winget.Source install --id $Id --exact --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget could not install $Name. Exit code: $LASTEXITCODE"
    }
}

try {
    if (-not (Test-Path $scriptSource)) {
        throw "Installer payload is missing PeekDock.ahk."
    }

    if (-not (Find-Chrome)) {
        Install-WingetPackage -Id "Google.Chrome" -Name "Google Chrome"
    }

    $ahk = Find-AutoHotkey
    if (-not $ahk) {
        Install-WingetPackage -Id "AutoHotkey.AutoHotkey" -Name "AutoHotkey v2"
        $ahk = Find-AutoHotkey
    }

    if (-not $ahk) {
        throw "AutoHotkey v2 was installed, but AutoHotkey64.exe could not be found."
    }

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Copy-Item -LiteralPath $scriptSource -Destination $scriptTarget -Force
    if (Test-Path $iconSource) {
        Copy-Item -LiteralPath $iconSource -Destination $iconTarget -Force
    }

    $shell = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath("DesktopDirectory")
    $startMenu = Join-Path ([Environment]::GetFolderPath("Programs")) $appName
    New-Item -ItemType Directory -Force -Path $startMenu | Out-Null

    foreach ($shortcutPath in @(
        (Join-Path $desktop "$appName.lnk"),
        (Join-Path $startMenu "$appName.lnk")
    )) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $ahk
        $shortcut.Arguments = '"' + $scriptTarget + '"'
        $shortcut.WorkingDirectory = $installDir
        $shortcut.IconLocation = if (Test-Path $iconTarget) { "$iconTarget,0" } else { "$ahk,0" }
        $shortcut.Save()
    }

    Start-Process -FilePath $ahk -ArgumentList ('"' + $scriptTarget + '"') -WorkingDirectory $installDir
    Show-Message "PeekDock has been installed and started.`n`nDesktop and Start Menu shortcuts were created."
} catch {
    Show-Message "PeekDock setup failed:`n`n$($_.Exception.Message)" 16
    throw
}
