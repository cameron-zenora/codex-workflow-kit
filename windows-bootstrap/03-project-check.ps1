[CmdletBinding()]
param(
  [string]$Repo = "",
  [string]$ProjectsDir = "$HOME\Code"
)

$ErrorActionPreference = "Stop"

if ($Repo) {
  New-Item -ItemType Directory -Path $ProjectsDir -Force | Out-Null
  Set-Location $ProjectsDir
  gh repo clone $Repo
  $name = Split-Path $Repo -Leaf
  Set-Location (Join-Path $ProjectsDir $name)
}

Write-Host "==> Project root" -ForegroundColor Cyan
git rev-parse --show-toplevel

Write-Host "==> Installing npm dependencies" -ForegroundColor Cyan
npm install

Write-Host "==> Initializing workflow folders if missing" -ForegroundColor Cyan
if (Get-Command aiwf.ps1 -ErrorAction SilentlyContinue) {
  aiwf.ps1 init
  aiwf.ps1 status
} else {
  New-Item -ItemType Directory -Path "docs\prds", "issues", "reviews", "qa" -Force | Out-Null
}

Write-Host "==> Running checks" -ForegroundColor Cyan
npm test
npm run check
npm run lint

Write-Host "Project check complete." -ForegroundColor Green
