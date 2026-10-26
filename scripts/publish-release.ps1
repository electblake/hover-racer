#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$IsccPath)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-Location (Split-Path $PSScriptRoot -Parent)
& "$PSScriptRoot/build-windows.ps1" -IsccPath $IsccPath
$version = (Select-String -Path project.godot -Pattern '^config/version="(.+)"$').Matches[0].Groups[1].Value
$releaseDir = Join-Path $PWD "dist/$version"
$tag = "v$version"
git tag -a $tag -m "Hover Racer $version"
git push origin HEAD
git push origin $tag
gh release create $tag "$releaseDir/HoverRacer-$version-Windows-Portable.zip" "$releaseDir/HoverRacer-$version-Windows-Setup.exe" "$releaseDir/SHA256SUMS.txt" --repo electblake/hover-racer --verify-tag --title "Hover Racer $version" --notes-file "packaging/releases/$version.md"
