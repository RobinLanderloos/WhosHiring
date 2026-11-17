# Builds the release files in dist/:
#   WhosHiring-<version>.zip  the addon folder at the zip's root, game files only
#   release.json              tells WowUp the zip is for WoW Forever (interface 16001)
# The version comes from "## Version:" in WhosHiring.toc.
#   pwsh scripts/package.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $PSScriptRoot
$name = "WhosHiring"
$toc = Join-Path $root "$name.toc"

$version = (Select-String -Path $toc -Pattern '^## Version:\s*(\S+)').Matches[0].Groups[1].Value
$interface = [int](Select-String -Path $toc -Pattern '^## Interface:\s*(\d+)').Matches[0].Groups[1].Value
if (-not $version) { throw "No '## Version:' in $toc" }

$dist = Join-Path $root "dist"
$stage = Join-Path $dist "stage\$name"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force $stage | Out-Null

# What the game loads, plus the README. Tests, docs and tooling stay out.
Copy-Item $toc $stage
foreach ($dir in "Core", "Game", "Locales") { Copy-Item (Join-Path $root $dir) $stage -Recurse }
foreach ($file in "README.md", "LICENSE") {
  $path = Join-Path $root $file
  if (Test-Path $path) { Copy-Item $path $stage }
}

# Every file the .toc lists must be in the package.
Get-Content $toc | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
  $listed = Join-Path $stage $_.Trim()
  if (-not (Test-Path $listed)) { throw "The .toc lists $($_.Trim()), which is not in the package" }
}

$zipName = "$name-$version.zip"
$zip = Join-Path $dist $zipName
# includeBaseDirectory = true puts the WhosHiring folder at the zip's root.
[System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $true)

$release = @{
  releases = @(@{
    name     = $name
    version  = $version
    filename = $zipName
    nolib    = $false
    metadata = @(@{ flavor = "forever"; interface = $interface })
  })
}
$release | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $dist "release.json") -Encoding utf8NoBOM

Remove-Item (Join-Path $dist "stage") -Recurse -Force
Write-Output "dist\$zipName"
Write-Output "dist\release.json"
