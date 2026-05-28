[CmdletBinding()]
param(
  [string]$GitName = "",
  [string]$GitEmail = "",
  [string]$ProjectsDir = "$HOME\Code",
  [switch]$SkipMeteor
)

$ErrorActionPreference = "Stop"

function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

function Ensure-Command {
  param([Parameter(Mandatory = $true)][string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name was not found on PATH. Reboot or re-run 01-admin-bootstrap.ps1."
  }
}

function Add-UserPath {
  param([Parameter(Mandatory = $true)][string]$PathToAdd)
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($current) { $parts = $current -split ";" }
  if ($parts -notcontains $PathToAdd) {
    $next = if ($current) { "$current;$PathToAdd" } else { $PathToAdd }
    [Environment]::SetEnvironmentVariable("Path", $next, "User")
    $env:Path = "$env:Path;$PathToAdd"
  }
}

function Configure-Git {
  if ($GitName) {
    git config --global user.name $GitName
  }
  if ($GitEmail) {
    git config --global user.email $GitEmail
  }

  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.autocrlf false
  git config --global core.longpaths true
  git config --global fetch.prune true
}

function Ensure-SSHKey {
  $sshDir = Join-Path $HOME ".ssh"
  $keyPath = Join-Path $sshDir "id_ed25519"

  if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
  }

  if (-not (Test-Path $keyPath)) {
    $comment = if ($GitEmail) { $GitEmail } else { "$env:USERNAME@$env:COMPUTERNAME" }
    ssh-keygen -t ed25519 -C $comment -f $keyPath -N ""
  }

  Write-Host ""
  Write-Host "SSH public key:" -ForegroundColor Cyan
  Get-Content "$keyPath.pub"
}

function Install-NpmGlobal {
  param(
    [Parameter(Mandatory = $true)][string]$Package,
    [string]$Name = $Package,
    [string[]]$ExtraArgs = @()
  )

  Write-Host ""
  Write-Host "==> Installing $Name ($Package)" -ForegroundColor Cyan
  npm install -g $Package @ExtraArgs
}

function Install-VSCodeExtensions {
  if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Warning "VS Code CLI 'code' was not found. Open VS Code once, then run: Shell Command: Install 'code' command in PATH."
    return
  }

  $extensions = @(
    "dbaeumer.vscode-eslint",
    "svelte.svelte-vscode",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "github.vscode-github-actions",
    "github.vscode-pull-request-github",
    "eamodio.gitlens",
    "ms-azuretools.vscode-docker",
    "ms-vscode.powershell"
  )

  foreach ($extension in $extensions) {
    Write-Host "==> Installing VS Code extension $extension" -ForegroundColor Cyan
    code --install-extension $extension --force
  }
}

function Install-AIWorkflowHelper {
  $binDir = Join-Path $HOME ".local\bin"
  New-Item -ItemType Directory -Path $binDir -Force | Out-Null
  Add-UserPath $binDir

  $scriptPath = Join-Path $binDir "aiwf.ps1"
  Set-Content -Path $scriptPath -Encoding UTF8 -Value @'
param(
  [Parameter(Position = 0)][string]$Command = "help",
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = "Stop"

function Get-Root {
  if ($env:CODEX_FLOW_ROOT) { return (Resolve-Path $env:CODEX_FLOW_ROOT).Path }
  try {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
  } catch {}
  return (Get-Location).Path
}

function Get-IssueField($Path, $Field) {
  $line = Get-Content $Path | Where-Object { $_ -match "^$([Regex]::Escape($Field)): " } | Select-Object -First 1
  if (-not $line) { return "" }
  return $line.Substring($Field.Length + 2)
}

function Set-IssueField($Path, $Field, $Value) {
  $lines = [System.Collections.Generic.List[string]](Get-Content -Path $Path)
  $pattern = "^$([Regex]::Escape($Field)): "
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $pattern) {
      $nextLine = "${Field}: $Value"
      if ($lines[$i] -ne $nextLine) {
        $lines[$i] = $nextLine
        Set-Content -Path $Path -Value $lines -Encoding utf8
      }
      return
    }
    if ($i -gt 0 -and $lines[$i] -eq "---") { break }
  }
  throw "Could not find issue field '$Field' in $Path"
}

function Get-IssueById($IssuesDir, $Id) {
  Get-ChildItem $IssuesDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { (Get-IssueField $_.FullName "id") -eq $Id } |
    Select-Object -First 1
}

function Resolve-Issue($Root, $IssuesDir, $Input) {
  if (-not $Input) { throw "Missing issue. Use aiwf.ps1 help." }
  if (Test-Path $Input) { return (Resolve-Path $Input).Path }
  $rooted = Join-Path $Root $Input
  if (Test-Path $rooted) { return (Resolve-Path $rooted).Path }
  if ($Input -match '^\d+$') {
    $match = Get-ChildItem $IssuesDir -Filter "$Input-*.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { return $match.FullName }
  }
  if ($Input -match '^ISSUE-\d+$') {
    $match = Get-IssueById $IssuesDir $Input
    if ($match) { return $match.FullName }
  }
  throw "Could not find issue: $Input"
}

function Get-Blockers($Path) {
  $raw = Get-IssueField $Path "blocked_by"
  if (-not $raw -or $raw -eq "[]") { return @() }
  return ($raw -replace '[\[\],]', ' ' -split '\s+') | Where-Object { $_ -match '^ISSUE-\d+$' }
}

function Test-IssueDone($IssuesDir, $Id) {
  $issue = Get-IssueById $IssuesDir $Id
  return $issue -and (Get-IssueField $issue.FullName "status") -eq "done"
}

function Get-ReviewPath($Root, $Id) {
  return (Join-Path (Join-Path $Root "reviews") "$Id-review.md")
}

function Test-ReviewPassed($Root, $Id) {
  $reviewPath = Get-ReviewPath $Root $Id
  if (-not (Test-Path $reviewPath)) { return $false }
  $blocking = Get-IssueField $reviewPath "blocking_findings"
  return $blocking -eq "0"
}

function Mark-IssueDoneAfterPassingReview($Root, $IssuePath) {
  $id = Get-IssueField $IssuePath "id"
  if (-not (Test-ReviewPassed $Root $id)) { return $false }
  $status = Get-IssueField $IssuePath "status"
  if ($status -eq "review") {
    Set-IssueField $IssuePath "status" "done"
    Write-Host "Marked $id done after passing review." -ForegroundColor Green
  }
  return $true
}

function Mark-PassedReviewIssuesDone($Root, $IssuesDir) {
  Get-ChildItem $IssuesDir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $id = Get-IssueField $_.FullName "id"
    if ((Get-IssueField $_.FullName "status") -eq "review" -and (Test-ReviewPassed $Root $id)) {
      $null = Mark-IssueDoneAfterPassingReview $Root $_.FullName
    }
  }
}

function Test-IssueCompleteForBlocker($IssuesDir, $Id, [bool]$AllowReviewBlockers = $false) {
  $issue = Get-IssueById $IssuesDir $Id
  if (-not $issue) { return $false }
  $status = Get-IssueField $issue.FullName "status"
  return $status -eq "done" -or ($AllowReviewBlockers -and $status -eq "review" -and (Test-ReviewPassed $root $Id))
}

function Test-Unblocked($IssuesDir, $Path, [bool]$AllowReviewBlockers = $false) {
  foreach ($blocker in Get-Blockers $Path) {
    if (-not (Test-IssueCompleteForBlocker $IssuesDir $blocker $AllowReviewBlockers)) { return $false }
  }
  return $true
}

function Get-NextAfkIssue($IssuesDir, [bool]$AllowReviewBlockers = $false) {
  Get-ChildItem $IssuesDir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object Name | Where-Object {
    (Get-IssueField $_.FullName "status") -eq "todo" -and
    (Get-IssueField $_.FullName "type") -eq "AFK" -and
    (Test-Unblocked $IssuesDir $_.FullName $AllowReviewBlockers)
  } | Select-Object -First 1
}

function Get-NextReviewIssue($Root, $IssuesDir, [bool]$AllowReviewBlockers = $false) {
  Get-ChildItem $IssuesDir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object Name | Where-Object {
    $id = Get-IssueField $_.FullName "id"
    (Get-IssueField $_.FullName "status") -eq "review" -and
    (Get-IssueField $_.FullName "type") -eq "AFK" -and
    -not (Test-ReviewPassed $Root $id) -and
    (Test-Unblocked $IssuesDir $_.FullName $AllowReviewBlockers)
  } | Select-Object -First 1
}

function ConvertTo-PowerShellLiteral($Value) {
  return "'" + ([string]$Value -replace "'", "''") + "'"
}

function Get-CodexExecTimeoutSeconds {
  if ($env:CODEX_FLOW_EXEC_TIMEOUT_SECONDS) {
    $value = [int]$env:CODEX_FLOW_EXEC_TIMEOUT_SECONDS
    if ($value -lt 0) { throw "CODEX_FLOW_EXEC_TIMEOUT_SECONDS must be 0 or greater." }
    return $value
  }
  return 5400
}

function Stop-ProcessTree($ProcessId) {
  Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ProcessId } | ForEach-Object {
    Stop-ProcessTree $_.ProcessId
  }
  Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

function Invoke-CodexExec {
  param(
    [string]$Root,
    [string[]]$Arguments,
    [string]$Label
  )

  $timeoutSeconds = Get-CodexExecTimeoutSeconds
  $rootLiteral = ConvertTo-PowerShellLiteral $Root
  $argumentLiteralList = ($Arguments | ForEach-Object { ConvertTo-PowerShellLiteral $_ }) -join ", "
  $script = @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $rootLiteral
`$codexArgs = @($argumentLiteralList)
& codex @codexArgs
exit `$LASTEXITCODE
"@
  $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
  $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
  $process = Start-Process -FilePath $pwsh -ArgumentList @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded) -NoNewWindow -PassThru

  if ($timeoutSeconds -gt 0) {
    $finished = $process.WaitForExit([int]($timeoutSeconds * 1000))
  } else {
    $process.WaitForExit()
    $finished = $true
  }

  if (-not $finished) {
    Write-Warning "Codex timed out after $timeoutSeconds second(s) while $Label. Stopping that process tree and refreshing the board."
    Stop-ProcessTree $process.Id
    return $false
  }

  $process.Refresh()
  if ($process.ExitCode -ne 0) {
    throw "Codex exited with code $($process.ExitCode) while $Label"
  }

  return $true
}

function Invoke-CodexReview($Root, $IssuePath, $Sandbox) {
  New-Item -ItemType Directory -Path (Join-Path $Root "reviews") -Force | Out-Null
  $id = Get-IssueField $IssuePath "id"
  $rel = Resolve-Path -Relative $IssuePath
  $reviewPath = Get-ReviewPath $Root $id
  $reviewRel = Resolve-Path -Relative (Split-Path -Parent $reviewPath)
  $reviewRel = Join-Path $reviewRel (Split-Path -Leaf $reviewPath)

  Write-Host "Reviewing $rel -> $reviewRel" -ForegroundColor Cyan
  $prompt = "Use review-work. Review the current uncommitted changes against $rel in a fresh context. $shellGuidance Do not modify implementation files or issue files. You may only create or replace the review note at $reviewRel. Write the review note with YAML-style metadata at the top containing issue: $id, result: pass or needs-fix, and blocking_findings: the count of P0/P1/P2 findings. Use blocking_findings: 0 only when there are no P0/P1/P2 findings. Findings first, ordered by severity. Include tests run or not run. Do not paste the full diff."
  return (Invoke-CodexExec -Root $Root -Arguments @("--ask-for-approval", "never", "exec", "-C", $Root, "--sandbox", $Sandbox, $prompt) -Label "reviewing $rel")
}

function Invoke-CodexFixFindings($Root, $IssuePath, $Sandbox) {
  $id = Get-IssueField $IssuePath "id"
  $rel = Resolve-Path -Relative $IssuePath
  $reviewPath = Get-ReviewPath $Root $id
  $reviewRel = Resolve-Path -Relative $reviewPath

  Write-Host "Fixing review findings for $rel from $reviewRel" -ForegroundColor Cyan
  $prompt = "Use implement-issue-tdd. Fix only the blocking findings in $reviewRel for $rel. $shellGuidance Read the issue, review note, linked PRD, and relevant code first. Do not expand scope beyond the review findings. Run the issue test plan and relevant checks. Keep the issue in review, update issue notes with checks run, and stop after this issue."
  return (Invoke-CodexExec -Root $Root -Arguments @("--ask-for-approval", "never", "exec", "-C", $Root, "--sandbox", $Sandbox, $prompt) -Label "fixing review findings for $rel")
}

$root = Get-Root
$issuesDir = if ($env:CODEX_FLOW_ISSUES_DIR) { $env:CODEX_FLOW_ISSUES_DIR } else { Join-Path $root "issues" }
$sandbox = if ($env:CODEX_FLOW_SANDBOX) { $env:CODEX_FLOW_SANDBOX } else { "danger-full-access" }
$shellGuidance = "Use PowerShell-safe shell commands. When using rg on Windows, do not pass wildcard path arguments like imports\server\*.js; search directories and use --glob/-g instead, for example: rg -n -g '*.js' 'pattern' imports/server. Do not leave dev servers, watch commands, or long-running smoke servers in the foreground; if you start one, stop it before returning."

switch ($Command) {
  "help" {
    @"
aiwf.ps1 commands:
  aiwf.ps1 init
  aiwf.ps1 status
  aiwf.ps1 next
  aiwf.ps1 next --through-review
  aiwf.ps1 afk
  aiwf.ps1 afk --through-review
  aiwf.ps1 afk --review-between --through-review
  aiwf.ps1 afk --review-between --fix-findings --through-review
  aiwf.ps1 implement ISSUE-001
  aiwf.ps1 review ISSUE-001
  aiwf.ps1 hitl ISSUE-003

Env:
  CODEX_FLOW_EXEC_TIMEOUT_SECONDS=5400 by default; set 0 to disable.
"@
  }
  "init" {
    New-Item -ItemType Directory -Path (Join-Path $root "docs\prds"), $issuesDir, (Join-Path $root "reviews"), (Join-Path $root "qa") -Force | Out-Null
    "Initialized Codex Flow folders in $root"
  }
  "status" {
    "{0,-10} {1,-8} {2,-5} {3,-9} {4,-18} {5}" -f "ID","STATUS","TYPE","READY","BLOCKED_BY","TITLE"
    Get-ChildItem $issuesDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
      $id = Get-IssueField $_.FullName "id"
      $status = Get-IssueField $_.FullName "status"
      $type = Get-IssueField $_.FullName "type"
      $blockedBy = Get-IssueField $_.FullName "blocked_by"
      $title = Get-IssueField $_.FullName "title"
      $ready = if ($status -eq "done") { "done" } elseif (Test-Unblocked $issuesDir $_.FullName) { "ready" } else { "blocked" }
      "{0,-10} {1,-8} {2,-5} {3,-9} {4,-18} {5}" -f $id,$status,$type,$ready,$blockedBy,$title
    }
  }
  "next" {
    $allowReviewBlockers = $Rest -contains "--through-review"
    $next = Get-NextAfkIssue $issuesDir $allowReviewBlockers
    if ($next) { $next.FullName } else { "NO_MORE_AFK_TASKS" }
  }
  "afk" {
    $completed = 0
    $allowReviewBlockers = $Rest -contains "--through-review"
    $reviewBetween = $Rest -contains "--review-between"
    $fixFindings = $Rest -contains "--fix-findings"
    Write-Host "Using Codex sandbox: $sandbox" -ForegroundColor Yellow
    if ($allowReviewBlockers) {
      Write-Host "Treating review blockers with passing review notes as complete for AFK implementation chaining." -ForegroundColor Yellow
    }
    if ($reviewBetween) {
      Write-Host "Running fresh review-work between AFK implementation steps." -ForegroundColor Yellow
    }
    if ($fixFindings) {
      Write-Host "Fixing blocking review findings automatically until review passes or Codex fails." -ForegroundColor Yellow
    }
    $execTimeoutSeconds = Get-CodexExecTimeoutSeconds
    if ($execTimeoutSeconds -gt 0) {
      Write-Host "Codex exec timeout: $execTimeoutSeconds second(s)." -ForegroundColor Yellow
    } else {
      Write-Host "Codex exec timeout disabled." -ForegroundColor Yellow
    }
    while ($true) {
      Mark-PassedReviewIssuesDone $root $issuesDir

      if ($reviewBetween) {
        $reviewIssue = Get-NextReviewIssue $root $issuesDir $allowReviewBlockers
        if ($reviewIssue) {
          $reviewId = Get-IssueField $reviewIssue.FullName "id"
          $reviewReturned = Invoke-CodexReview $root $reviewIssue.FullName $sandbox
          if (-not $reviewReturned) { continue }
          if (-not (Test-ReviewPassed $root $reviewId)) {
            if ($fixFindings) {
              $null = Invoke-CodexFixFindings $root $reviewIssue.FullName $sandbox
              continue
            }
            throw "Review for $reviewId found blocking findings or did not write blocking_findings: 0; stopping for fixes."
          }
          $null = Mark-IssueDoneAfterPassingReview $root $reviewIssue.FullName
          continue
        }
      }

      $next = Get-NextAfkIssue $issuesDir $allowReviewBlockers
      if (-not $next) {
        "NO_MORE_AFK_TASKS"
        "AFK loop stopped after $completed issue(s)."
        break
      }

      $rel = Resolve-Path -Relative $next.FullName
      Write-Host "AFK selecting $rel" -ForegroundColor Cyan
      $prompt = "Use run-afk-loop. Implement exactly this selected unblocked AFK issue: $rel. Within this issue, use implement-issue-tdd. $shellGuidance Read the linked PRD, blockers, acceptance criteria, affected modules, and test plan. Use TDD where practical. Run the issue test plan and relevant checks. Update the issue status and notes when complete. Do not implement review, done, blocked, or HITL issues. Do not ask for confirmation between AFK issues. Stop this invocation after this issue so aiwf afk can refresh the board."
      $implementationReturned = Invoke-CodexExec -Root $root -Arguments @("--ask-for-approval", "never", "exec", "-C", $root, "--sandbox", $sandbox, $prompt) -Label "working on $rel"

      $statusAfter = Get-IssueField $next.FullName "status"
      if (-not $implementationReturned -and $statusAfter -eq "todo" -and (Test-Unblocked $issuesDir $next.FullName $allowReviewBlockers)) {
        throw "Codex timed out while working on $rel, and the issue is still todo and unblocked; stopping to avoid repeating it."
      }
      if ($statusAfter -eq "todo" -and (Test-Unblocked $issuesDir $next.FullName $allowReviewBlockers)) {
        throw "Issue $rel is still todo and unblocked after Codex returned; stopping to avoid repeating it."
      }

      if ($reviewBetween -and $statusAfter -eq "review") {
        $issueId = Get-IssueField $next.FullName "id"
        $reviewReturned = Invoke-CodexReview $root $next.FullName $sandbox
        if (-not $reviewReturned) { continue }
        if (-not (Test-ReviewPassed $root $issueId)) {
          if ($fixFindings) {
            $null = Invoke-CodexFixFindings $root $next.FullName $sandbox
            continue
          }
          throw "Review for $issueId found blocking findings or did not write blocking_findings: 0; stopping for fixes."
        }
        $null = Mark-IssueDoneAfterPassingReview $root $next.FullName
      }

      $completed += 1
    }
  }
  "implement" {
    $issue = Resolve-Issue $root $issuesDir $Rest[0]
    $rel = Resolve-Path -Relative $issue
    $prompt = "Use implement-issue-tdd on $rel. Implement only this issue. $shellGuidance Read the linked PRD, blockers, and relevant code first. Use TDD where practical. Run the issue test plan and relevant checks. Do not expand into other issues."
    if (-not (Invoke-CodexExec -Root $root -Arguments @("--ask-for-approval", "never", "exec", "-C", $root, "--sandbox", $sandbox, $prompt) -Label "implementing $rel")) {
      throw "Codex timed out while implementing $rel"
    }
  }
  "review" {
    $issue = Resolve-Issue $root $issuesDir $Rest[0]
    if (-not (Invoke-CodexReview $root $issue $sandbox)) {
      throw "Codex timed out while reviewing $issue"
    }
    $null = Mark-IssueDoneAfterPassingReview $root $issue
  }
  "hitl" {
    $issue = Resolve-Issue $root $issuesDir $Rest[0]
    $rel = Resolve-Path -Relative $issue
    codex -C $root --sandbox $sandbox "Resolve this HITL issue: $rel. $shellGuidance Ask decisions one at a time with recommended defaults. Do not edit app code. Once I approve, update the issue decision table and set status to done."
  }
  default { throw "Unknown command: $Command" }
}
'@

  Write-Host "Installed aiwf.ps1 to $scriptPath" -ForegroundColor Green
}

function Install-CodexSkills {
  $repoSkills = Join-Path (Split-Path -Parent $PSScriptRoot) "skills"
  $bundledSkills = Join-Path $PSScriptRoot "codex-skills"
  $source = if (Test-Path $repoSkills) { $repoSkills } else { $bundledSkills }
  if (-not (Test-Path $source)) {
    Write-Warning "No skills folder found beside this script. Skipping skill install."
    return
  }

  $target = Join-Path $HOME ".codex\skills"
  New-Item -ItemType Directory -Path $target -Force | Out-Null

  Get-ChildItem -Path $source -Directory | ForEach-Object {
    $destination = Join-Path $target $_.Name
    if (Test-Path $destination) {
      Remove-Item -Recurse -Force $destination
    }
    Copy-Item -Recurse -Path $_.FullName -Destination $destination
    Write-Host "Installed Codex skill $($_.Name)" -ForegroundColor Cyan
  }
}

Refresh-Path

Ensure-Command git
Ensure-Command gh
Ensure-Command node
Ensure-Command npm

New-Item -ItemType Directory -Path $ProjectsDir -Force | Out-Null

Configure-Git
Ensure-SSHKey

Install-NpmGlobal -Package "@openai/codex" -Name "OpenAI Codex CLI"

if (-not $SkipMeteor) {
  Install-NpmGlobal `
    -Package "meteor" `
    -Name "Meteor" `
    -ExtraArgs @("--ignore-meteor-setup-exec-path", "--foreground-script")
}

Install-VSCodeExtensions
Install-AIWorkflowHelper
Install-CodexSkills

Write-Host ""
Write-Host "==> Versions" -ForegroundColor Cyan
git --version
gh --version | Select-Object -First 1
node --version
npm --version
codex --version
if (Get-Command meteor -ErrorAction SilentlyContinue) {
  meteor --version
}

Write-Host ""
Write-Host "Next manual sign-ins:" -ForegroundColor Yellow
Write-Host "  gh auth login"
Write-Host "  gh auth setup-git"
Write-Host "  gh ssh-key add $HOME\.ssh\id_ed25519.pub --title `"$env:COMPUTERNAME`""
Write-Host "  codex login"
Write-Host ""
Write-Host "Opening official Codex page for the Windows app..." -ForegroundColor Yellow
Start-Process "https://openai.com/codex/"

Write-Host ""
Write-Host "User bootstrap complete. Reopen your terminal so PATH changes are fully loaded." -ForegroundColor Green
