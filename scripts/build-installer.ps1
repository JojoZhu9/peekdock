$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
$output = Join-Path $dist "PeekDock-Setup.exe"
$buildRoot = Join-Path $env:TEMP "PeekDockInstallerBuild"
$payload = Join-Path $buildRoot "payload"
$sed = Join-Path $buildRoot "PeekDock-Setup.sed"
$tempOutput = Join-Path $buildRoot "PeekDock-Setup.exe"
$iexpress = Join-Path $env:SystemRoot "system32\iexpress.exe"
$runtimeCandidates = @(
    "${env:LOCALAPPDATA}\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe"
)

if (-not (Test-Path $iexpress)) {
    throw "iexpress.exe was not found on this Windows installation."
}

$runtime = $runtimeCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $runtime) {
    throw "AutoHotkey v2 runtime was not found. Install AutoHotkey v2 before building PeekDock-Setup.exe."
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $buildRoot) {
    Remove-Item -LiteralPath $buildRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $payload | Out-Null

Copy-Item -LiteralPath (Join-Path $root "PeekDock.ahk") -Destination (Join-Path $payload "PeekDock.ahk") -Force
Copy-Item -LiteralPath (Join-Path $root "scripts\install.ps1") -Destination (Join-Path $payload "install.ps1") -Force
Copy-Item -LiteralPath (Join-Path $root "assets\peekdock.ico") -Destination (Join-Path $payload "peekdock.ico") -Force
Copy-Item -LiteralPath $runtime -Destination (Join-Path $payload "AutoHotkey64.exe") -Force

$sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=PeekDock setup has finished.
TargetName=$tempOutput
FriendlyName=PeekDock Setup
AppLaunched=powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$payload\
[SourceFiles0]
%FILE0%=PeekDock.ahk
%FILE1%=install.ps1
%FILE2%=peekdock.ico
%FILE3%=AutoHotkey64.exe
[Strings]
FILE0="PeekDock.ahk"
FILE1="install.ps1"
FILE2="peekdock.ico"
FILE3="AutoHotkey64.exe"
"@

Set-Content -LiteralPath $sed -Value $sedContent -Encoding ASCII
& $iexpress /N /Q $sed

for ($i = 0; $i -lt 20 -and -not (Test-Path $tempOutput); $i++) {
    Start-Sleep -Milliseconds 500
}

if (-not (Test-Path $tempOutput)) {
    throw "Installer build failed: temporary PeekDock-Setup.exe was not created."
}

Copy-Item -LiteralPath $tempOutput -Destination $output -Force
Write-Host "Built $output"
