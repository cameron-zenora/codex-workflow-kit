[CmdletBinding()]
param(
  [string]$Target = "$HOME\.codex\skills"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Source = Join-Path $Root "skills"

if (-not (Test-Path $Source)) {
  throw "No skills directory found at $Source"
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null

Get-ChildItem -Path $Source -Directory | Sort-Object Name | ForEach-Object {
  $skillFile = Join-Path $_.FullName "SKILL.md"
  if (-not (Test-Path $skillFile)) {
    Write-Warning "Skipping $($_.Name): no SKILL.md"
    return
  }

  $destination = Join-Path $Target $_.Name
  if (Test-Path $destination) {
    Remove-Item -Recurse -Force $destination
  }

  Copy-Item -Recurse -Path $_.FullName -Destination $destination
  Write-Host "Installed $($_.Name) -> $destination" -ForegroundColor Cyan
}

Write-Host "Done. Restart Codex if it was already open." -ForegroundColor Green
