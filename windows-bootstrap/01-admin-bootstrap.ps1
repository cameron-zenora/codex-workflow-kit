#Requires -Version 5.1

[CmdletBinding()]
param(
  [switch]$SkipWSL,
  [switch]$SkipDocker,
  [switch]$SkipBuildTools
)

$ErrorActionPreference = "Stop"

function Assert-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from Windows PowerShell as Administrator."
  }
}

function Require-Winget {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget was not found. Open Microsoft Store, update 'App Installer', then re-run this script."
  }
}

function Install-WingetPackage {
  param(
    [Parameter(Mandatory = $true)][string]$Id,
    [string]$Name = $Id,
    [string]$Override
  )

  Write-Host ""
  Write-Host "==> Installing $Name ($Id)" -ForegroundColor Cyan

  $args = @(
    "install",
    "--id", $Id,
    "--exact",
    "--source", "winget",
    "--accept-package-agreements",
    "--accept-source-agreements",
    "--disable-interactivity"
  )

  if ($Override) {
    $args += @("--override", $Override)
  } else {
    $args += "--silent"
  }

  & winget @args
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Install may have failed for $Id. Continuing so the rest of the setup can proceed."
  }
}

function Enable-DeveloperDefaults {
  Write-Host ""
  Write-Host "==> Enabling developer defaults" -ForegroundColor Cyan

  New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Force | Out-Null
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Type DWord -Value 1

  New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Force | Out-Null
  Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Type DWord -Value 1
}

Assert-Admin
Require-Winget

Write-Host "==> Updating winget sources" -ForegroundColor Cyan
winget source update

Enable-DeveloperDefaults

$packages = @(
  @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7" },
  @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
  @{ Id = "Git.Git"; Name = "Git" },
  @{ Id = "GitHub.cli"; Name = "GitHub CLI" },
  @{ Id = "GitHub.GitHubDesktop"; Name = "GitHub Desktop" },
  @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
  @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" },
  @{ Id = "Python.Python.3.12"; Name = "Python 3.12" },
  @{ Id = "astral-sh.uv"; Name = "uv" },
  @{ Id = "7zip.7zip"; Name = "7-Zip" },
  @{ Id = "Microsoft.PowerToys"; Name = "PowerToys" },
  @{ Id = "Google.Chrome"; Name = "Google Chrome" }
)

foreach ($package in $packages) {
  Install-WingetPackage @package
}

if (-not $SkipDocker) {
  Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"
}

if (-not $SkipBuildTools) {
  Install-WingetPackage `
    -Id "Microsoft.VisualStudio.2022.BuildTools" `
    -Name "Visual Studio 2022 Build Tools" `
    -Override "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
}

if (-not $SkipWSL) {
  Write-Host ""
  Write-Host "==> Enabling WSL with Ubuntu" -ForegroundColor Cyan
  wsl --install -d Ubuntu
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "WSL install returned a non-zero exit code. It may already be installed or may need a reboot."
  }
}

Write-Host ""
Write-Host "Admin bootstrap complete." -ForegroundColor Green
Write-Host "Reboot now, then run 02-user-bootstrap.ps1 from PowerShell 7 as your normal user." -ForegroundColor Yellow
