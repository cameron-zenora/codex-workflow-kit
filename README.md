# Codex Workflow Kit

Portable skills and bootstrap scripts for the PRD -> Kanban -> implementation -> review workflow.

## Skills Included

- `grill-me`
- `write-prd`
- `break-prd-to-issues`
- `implement-issue-tdd`
- `review-work`
- `qa-to-issues`
- `improve-architecture`
- `run-afk-loop`
- `run-parallel-agents`
- `frontend-prototype`

## Install Skills

Windows PowerShell:

```powershell
.\scripts\install-skills.ps1
```

macOS/Linux:

```bash
./scripts/install-skills.sh
```

This copies `skills/*` into your Codex skills folder:

- Windows: `%USERPROFILE%\.codex\skills`
- macOS/Linux: `~/.codex/skills`

## How To Use It

Read [docs/HOW_TO_USE.md](docs/HOW_TO_USE.md).

Short version:

```text
grill-me
-> write-prd
-> break-prd-to-issues
-> implement one issue
-> review in fresh context
-> fix findings
-> review again
-> QA
-> done
```

## Update Skills Later

Pull the latest repo, then rerun the installer:

```bash
git pull
./scripts/install-skills.sh
```

or on Windows:

```powershell
git pull
.\scripts\install-skills.ps1
```

## Fresh Windows Machine

Use the scripts in `windows-bootstrap/`:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
cd .\windows-bootstrap
.\01-admin-bootstrap.ps1
```

Reboot, then:

```powershell
cd .\windows-bootstrap
.\02-user-bootstrap.ps1 -GitName "Your Name" -GitEmail "you@example.com" -ProjectsDir "$HOME\Code"
```

Then sign in:

```powershell
gh auth login
gh auth setup-git
codex login
```

## Workflow

```text
grill-me
-> write-prd
-> break-prd-to-issues
-> implement-issue-tdd
-> review-work
-> implement review fixes
-> review again
-> QA
-> done
```

Use Codex GUI for the real agent work. Use shell scripts for setup and quick state checks.
