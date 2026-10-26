#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$IsccPath)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-Location (Split-Path $PSScriptRoot -Parent)
$version = (Select-String -Path project.godot -Pattern '^config/version="(.+)"$').Matches[0].Groups[1].Value
$releaseDir = Join-Path $PWD "dist/$version"
$portableDir = Join-Path $releaseDir 'portable'
New-Item -ItemType Directory -Path $portableDir -Force | Out-Null

mise run test
godot_console --headless --path . --export-release 'Windows Desktop' "$portableDir/HoverRacer.exe"
godot_console --headless --path . --script res://tools/write_notices.gd -- "$portableDir/THIRD-PARTY-NOTICES.txt"
Copy-Item packaging/PORTABLE-README.txt $portableDir

# Run the exported executable outside the source tree.
Push-Location $portableDir
& ./HoverRacer.exe --headless --quit-after 180 --log-file "$releaseDir/portable-smoke.log" | Out-Host
& ./HoverRacer.exe --quit-after 180 --log-file "$releaseDir/portable-render-smoke.log" | Out-Host
Pop-Location

& $IsccPath "/DAppVersion=$version" "/DPortableDir=$portableDir" "/DReleaseDir=$releaseDir" packaging/windows-installer.iss
Compress-Archive -Path "$portableDir/*" -DestinationPath "$releaseDir/HoverRacer-$version-Windows-Portable.zip" -Force
$artifacts = @("$releaseDir/HoverRacer-$version-Windows-Portable.zip", "$releaseDir/HoverRacer-$version-Windows-Setup.exe")
$artifacts | Get-FileHash -Algorithm SHA256 | ForEach-Object { '{0}  {1}' -f $_.Hash.ToLowerInvariant(), (Split-Path $_.Path -Leaf) } | Set-Content "$releaseDir/SHA256SUMS.txt"
Write-Host "Built Windows release $version in $releaseDir"
