# macOS Fresh Machine Bootstrap

This folder sets up a fresh macOS machine for the Codex workflow kit.

It installs:

- Xcode Command Line Tools
- Homebrew
- Git
- GitHub CLI
- Node.js LTS
- OpenAI Codex CLI
- Python
- uv
- Docker Desktop
- VS Code
- GitHub Desktop
- Google Chrome
- PowerShell
- Meteor
- Codex workflow skills
- `aiwf` helper command

## First Run

Open Terminal and run:

```bash
xcode-select --install
```

After that finishes, clone the workflow kit:

```bash
mkdir -p ~/Code
cd ~/Code
git clone https://github.com/cameron-zenora/codex-workflow-kit.git
cd codex-workflow-kit
```

Then run:

```bash
./mac-bootstrap/01-mac-bootstrap.sh --git-name "Your Name" --git-email "you@example.com"
```

Sign in:

```bash
gh auth login
gh auth setup-git
codex login
```

## How To Use The Workflow

After setup, read:

```bash
open docs/HOW_TO_USE.md
```

Daily rhythm:

```text
Use Codex GUI for grill-me, PRD, issues, implementation, review, and QA.
Use aiwf status / aiwf next in Terminal for quick board state.
```

## Clone A Project

```bash
cd ~/Code
gh repo clone OWNER/REPO
cd REPO
aiwf init
npm install
npm test
npm run check
npm run lint
```

## Project Check Helper

From inside a project:

```bash
~/Code/codex-workflow-kit/mac-bootstrap/02-project-check.sh
```

Or clone and check in one command:

```bash
~/Code/codex-workflow-kit/mac-bootstrap/02-project-check.sh --repo OWNER/REPO
```
