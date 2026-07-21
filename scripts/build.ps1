$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root "PeekDock.ahk"
$icon = Join-Path $root "assets\peekdock.ico"
$dist = Join-Path $root "dist"
$output = Join-Path $dist "PeekDock.exe"

if (-not (Test-Path $source)) {
    throw "Missing PeekDock.ahk. Run this script from the repository checkout, or restore the source file and try again."
}

$compilerCandidates = @(
    "${env:LOCALAPPDATA}\Programs\AutoHotkey\Compiler\Ahk2Exe.exe",
    "${env:ProgramFiles}\AutoHotkey\Compiler\Ahk2Exe.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\Compiler\Ahk2Exe.exe"
)

$compilerFromPath = Get-Command "Ahk2Exe.exe" -ErrorAction SilentlyContinue
if ($compilerFromPath) {
    $compilerCandidates += $compilerFromPath.Source
}

$compiler = $compilerCandidates |
    Where-Object { $_ -and (Test-Path $_) } |
    Select-Object -First 1

if (-not $compiler) {
    throw "Ahk2Exe.exe was not found. Install AutoHotkey v2, then run scripts\build.ps1 again."
}

$baseCandidates = @(
    "${env:LOCALAPPDATA}\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe"
)

$base = $baseCandidates |
    Where-Object { $_ -and (Test-Path $_) } |
    Select-Object -First 1

if (-not $base) {
    throw "AutoHotkey v2 base executable was not found. Install AutoHotkey v2, then run scripts\build.ps1 again."
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null

$arguments = @("/in", $source, "/out", $output, "/base", $base)
if (Test-Path $icon) {
    $arguments += @("/icon", $icon)
}

& $compiler @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Build failed: Ahk2Exe exited with code $LASTEXITCODE."
}

if (-not (Test-Path $output)) {
    throw "Build failed: dist\PeekDock.exe was not created."
}

Write-Host "Built $output"
