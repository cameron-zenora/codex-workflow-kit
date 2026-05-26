[CmdletBinding()]
param(
  [string]$Repo = "",
  [string]$ProjectsDir = "$HOME\Code"
)

$ErrorActionPreference = "Stop"

function Invoke-NpmScriptIfPresent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptName
  )

  Write-Host "==> npm run $ScriptName" -ForegroundColor Cyan
  npm run $ScriptName --if-present
}

if ($Repo) {
  New-Item -ItemType Directory -Path $ProjectsDir -Force | Out-Null
  Set-Location $ProjectsDir
  gh repo clone $Repo
  $name = [IO.Path]::GetFileNameWithoutExtension((Split-Path $Repo -Leaf))
  Set-Location (Join-Path $ProjectsDir $name)
}

Write-Host "==> Project root" -ForegroundColor Cyan
$projectRoot = (git rev-parse --show-toplevel).Trim()
Write-Host $projectRoot
Set-Location $projectRoot

$packageJson = Join-Path $projectRoot "package.json"
if (Test-Path -LiteralPath $packageJson) {
  Write-Host "==> Installing npm dependencies" -ForegroundColor Cyan
  npm install
} else {
  Write-Host "==> No package.json found at project root; skipping npm install/checks" -ForegroundColor Yellow
}

Write-Host "==> Initializing workflow folders if missing" -ForegroundColor Cyan
if (Get-Command aiwf.ps1 -ErrorAction SilentlyContinue) {
  aiwf.ps1 init
  aiwf.ps1 status
} else {
  New-Item -ItemType Directory -Path "docs\prds", "issues", "reviews", "qa" -Force | Out-Null
}

if (Test-Path -LiteralPath $packageJson) {
  Write-Host "==> Running checks" -ForegroundColor Cyan
  Invoke-NpmScriptIfPresent -ScriptName "test"
  Invoke-NpmScriptIfPresent -ScriptName "check"
  Invoke-NpmScriptIfPresent -ScriptName "lint"
}

Write-Host "Project check complete." -ForegroundColor Green
