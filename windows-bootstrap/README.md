# Windows Fresh Machine Bootstrap

This folder takes a fresh Windows 11 PC from OOBE to a working AI development machine for the PRD -> Kanban -> implementation -> review workflow.

## What It Installs

- PowerShell 7
- Windows Terminal
- Git
- GitHub CLI
- GitHub Desktop
- VS Code
- Node.js LTS and npm
- OpenAI Codex CLI
- Python 3.12
- uv
- 7-Zip
- Docker Desktop
- PowerToys
- Google Chrome
- Meteor
- The local Codex workflow skills: `grill-me`, `write-prd`, `break-prd-to-issues`, `implement-issue-tdd`, `review-work`, `qa-to-issues`, `improve-architecture`, `run-afk-loop`, `run-parallel-agents`, and `frontend-prototype`
- Optional Visual Studio Build Tools for native Node packages
- Optional WSL Ubuntu

OpenAI currently documents Codex as available on Windows and across app, editor, and terminal surfaces. The CLI install command used here is the official npm path: `npm i -g @openai/codex`. Meteor's current Windows install command is also npm-based: `npm install -g meteor --ignore-meteor-setup-exec-path --foreground-script`.

Sources:

- [OpenAI Codex](https://openai.com/codex/)
- [Meteor install docs](https://docs.meteor.com/about/install)
- [Microsoft WinGet docs](https://learn.microsoft.com/en-us/windows/package-manager/winget/)

## From Fresh OOBE

1. Finish Windows OOBE and connect to Wi-Fi.
2. Open **Windows PowerShell as Administrator**.
3. Download or copy this folder onto the machine.
4. Run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
cd .\windows-bootstrap
.\01-admin-bootstrap.ps1
```

5. Reboot when prompted.
6. Open **PowerShell 7** as your normal user.
7. Run:

```powershell
cd .\windows-bootstrap
.\02-user-bootstrap.ps1 -GitName "Your Name" -GitEmail "you@example.com" -ProjectsDir "$HOME\Code"
```

8. Sign in when prompted:

```powershell
gh auth login
codex login
```

9. Install the Codex Windows app from the official page opened by the script, then sign in with the same ChatGPT account.

## Clone A Project

```powershell
cd $HOME\Code
gh repo clone OWNER/REPO
cd REPO
aiwf init
```

For `siterun-app`, after cloning:

```powershell
npm install
npm test
npm run check
npm run lint
```

## Daily Workflow

Use the Codex GUI for the real work:

```text
grill-me
-> write-prd
-> break-prd-to-issues
-> implement issue
-> review issue in fresh context
-> implement review fixes
-> review again
-> QA
-> done
```

Use the terminal helpers for quick state:

```powershell
aiwf status
aiwf next
aiwf init
```

The GUI is the cockpit. The shell is the dashboard and escape hatch.
