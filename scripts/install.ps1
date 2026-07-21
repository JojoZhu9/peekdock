$ErrorActionPreference = "Stop"

$appName = "PeekDock"
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDir = Join-Path $env:LOCALAPPDATA $appName
$scriptSource = Join-Path $sourceDir "PeekDock.ahk"
$iconSource = Join-Path $sourceDir "peekdock.ico"
$runtimeSource = Join-Path $sourceDir "AutoHotkey64.exe"
$scriptTarget = Join-Path $installDir "PeekDock.ahk"
$iconTarget = Join-Path $installDir "peekdock.ico"
$runtimeDir = Join-Path $installDir "runtime"
$runtimeTarget = Join-Path $runtimeDir "AutoHotkey64.exe"

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
        $runtimeTarget,
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

function Find-AutoHotkeyFromRegistry {
    $registryKeys = @(
        "HKCU:\SOFTWARE\AutoHotkey",
        "HKLM:\SOFTWARE\AutoHotkey",
        "HKLM:\SOFTWARE\WOW6432Node\AutoHotkey"
    )

    foreach ($key in $registryKeys) {
        if (-not (Test-Path $key)) {
            continue
        }

        $installDirValue = (Get-ItemProperty $key -ErrorAction SilentlyContinue).InstallDir
        if (-not $installDirValue) {
            continue
        }

        foreach ($candidate in @(
            (Join-Path $installDirValue "v2\AutoHotkey64.exe"),
            (Join-Path $installDirValue "AutoHotkey64.exe")
        )) {
            if (Test-Path $candidate) {
                return $candidate
            }
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
        Write-Host "winget.exe was not found."
        return $false
    }

    Write-Host "Installing $Name..."
    & $winget.Source install --id $Id --exact --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "winget could not install $Name. Exit code: $LASTEXITCODE"
        return $false
    }

    return $true
}

try {
    if (-not (Test-Path $scriptSource)) {
        throw "Installer payload is missing PeekDock.ahk."
    }

    if (-not (Test-Path $runtimeSource)) {
        throw "Installer payload is missing AutoHotkey64.exe."
    }

    if (-not (Find-Chrome)) {
        if (-not (Install-WingetPackage -Id "Google.Chrome" -Name "Google Chrome")) {
            throw "Chrome is required, but winget could not install it. Install Chrome manually, then run PeekDock setup again."
        }
    }

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
    Copy-Item -LiteralPath $runtimeSource -Destination $runtimeTarget -Force

    $ahk = Find-AutoHotkey
    if (-not $ahk) {
        $ahk = Find-AutoHotkeyFromRegistry
    }

    if (-not $ahk) {
        throw "AutoHotkey64.exe could not be found in the bundled runtime."
    }

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
