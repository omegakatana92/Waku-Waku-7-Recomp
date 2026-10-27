# Prepare-ROMs.ps1 - build a runtime-ready Waku Waku 7 ROM folder from your
# own dumps. This script extracts the MAME wakuwak7 and neogeo sets; it does
# not download anything and contains no ROM data.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\Prepare-ROMs.ps1
#   powershell -ExecutionPolicy Bypass -File .\Prepare-ROMs.ps1 -WakuWaku7Zip C:\path\wakuwak7.zip -NeoGeoZip C:\path\neogeo.zip

param(
    [string]$WakuWaku7Zip = "",
    [string]$NeoGeoZip = "",
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $OutDir) { $OutDir = Join-Path $here "roms" }

function Ask-Zip($label, $current) {
    if ($current -and (Test-Path $current)) { return (Resolve-Path $current).Path }
    while ($true) {
        $p = Read-Host "Path to $label"
        $p = $p.Trim('"').Trim()
        if (Test-Path $p) { return (Resolve-Path $p).Path }
        Write-Host "Not found: $p" -ForegroundColor Yellow
    }
}

$WakuWaku7Zip = Ask-Zip "wakuwak7.zip" $WakuWaku7Zip
$NeoGeoZip = Ask-Zip "neogeo.zip" $NeoGeoZip

New-Item -ItemType Directory -Force $OutDir | Out-Null

Write-Host "Extracting $WakuWaku7Zip"
tar -xf $WakuWaku7Zip -C $OutDir
if ($LASTEXITCODE -ne 0) { throw "Could not extract wakuwak7.zip with tar" }
Write-Host "Extracting $NeoGeoZip"
tar -xf $NeoGeoZip -C $OutDir
if ($LASTEXITCODE -ne 0) { throw "Could not extract neogeo.zip with tar" }

Write-Host ""
Write-Host "Done. Run:" -ForegroundColor Green
Write-Host "  .\`"Waku Waku 7.exe\`" --rom-path `"$OutDir`""
