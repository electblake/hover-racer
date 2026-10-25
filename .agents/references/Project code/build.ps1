[CmdletBinding()]
param(
    [switch]$SkipSmokeTest
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Run this build on Windows.' }
if (-not [Environment]::Is64BitOperatingSystem) { throw 'This build requires 64-bit Windows.' }
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'index.html'))) {
    throw 'index.html is missing from the project directory.'
}

# A project-local, checksum-verified toolchain keeps the build independent of PATH.
$nodeVersion = '24.22.1'
$toolsDirectory = Join-Path $PSScriptRoot '.build-tools'
$nodeArchiveName = "node-v$nodeVersion-win-x64.zip"
$nodeDirectory = Join-Path $toolsDirectory "node-v$nodeVersion-win-x64"
$nodeExecutable = Join-Path $nodeDirectory 'node.exe'
$npmCli = Join-Path $nodeDirectory 'node_modules\npm\bin\npm-cli.js'

if (-not ((Test-Path -LiteralPath $nodeExecutable) -and (Test-Path -LiteralPath $npmCli))) {
    New-Item -ItemType Directory -Force -Path $toolsDirectory | Out-Null
    $archivePath = Join-Path $toolsDirectory $nodeArchiveName
    $baseUrl = "https://nodejs.org/dist/v$nodeVersion"
    Write-Host "Downloading Node.js $nodeVersion..."
    # Needed by Windows PowerShell 5.1 on older Windows configurations.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest "$baseUrl/$nodeArchiveName" -OutFile $archivePath -UseBasicParsing
    $checksums = (Invoke-WebRequest "$baseUrl/SHASUMS256.txt" -UseBasicParsing).Content
    $checksumLine = $checksums -split "`n" | Where-Object { $_.Trim().EndsWith("  $nodeArchiveName") } | Select-Object -First 1
    if (-not $checksumLine) { throw 'Node.js archive checksum was not found.' }
    $expectedHash = ($checksumLine.Trim() -split '\s+')[0]
    if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $expectedHash) {
        throw 'Node.js archive checksum does not match. Build stopped.'
    }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $toolsDirectory -Force
    Remove-Item -LiteralPath $archivePath
}

$previousPath = $env:PATH
$previousElectronRunAsNode = $env:ELECTRON_RUN_AS_NODE
$previousSigningDiscovery = $env:CSC_IDENTITY_AUTO_DISCOVERY
Push-Location $PSScriptRoot
try {
    $env:PATH = "$nodeDirectory;$previousPath"
    $env:ELECTRON_RUN_AS_NODE = $null
    $env:CSC_IDENTITY_AUTO_DISCOVERY = 'false'
    if (Test-Path -LiteralPath 'package-lock.json') {
        & $nodeExecutable $npmCli ci --no-audit --no-fund
    } else {
        & $nodeExecutable $npmCli install --no-audit --no-fund
    }
    if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
    if (-not $SkipSmokeTest) {
        & $nodeExecutable $npmCli run smoke
        if ($LASTEXITCODE -ne 0) { throw 'Game smoke test failed; no build was created.' }
    }
    & $nodeExecutable $npmCli run build:win
    if ($LASTEXITCODE -ne 0) { throw 'Windows packaging failed.' }
    $package = Get-Content -LiteralPath 'package.json' -Raw | ConvertFrom-Json
    $outputPath = Join-Path $PSScriptRoot "dist\WipeoutRacer-$($package.version)-x64-portable.exe"
    if (-not (Test-Path -LiteralPath $outputPath)) { throw "Expected build output is missing: $outputPath" }
    Write-Host "Portable app ready: $outputPath"
} finally {
    Pop-Location
    $env:PATH = $previousPath
    $env:ELECTRON_RUN_AS_NODE = $previousElectronRunAsNode
    $env:CSC_IDENTITY_AUTO_DISCOVERY = $previousSigningDiscovery
}
