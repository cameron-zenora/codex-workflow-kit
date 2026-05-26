#!/usr/bin/env bash
set -euo pipefail

GIT_NAME=""
GIT_EMAIL=""
PROJECTS_DIR="$HOME/Code"
SKIP_METEOR=0
SKIP_DOCKER=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --git-name)
      GIT_NAME="${2:-}"
      shift 2
      ;;
    --git-email)
      GIT_EMAIL="${2:-}"
      shift 2
      ;;
    --projects-dir)
      PROJECTS_DIR="${2:-}"
      shift 2
      ;;
    --skip-meteor)
      SKIP_METEOR=1
      shift
      ;;
    --skip-docker)
      SKIP_DOCKER=1
      shift
      ;;
    -h|--help)
      cat <<'HELP'
Usage:
  ./mac-bootstrap/01-mac-bootstrap.sh --git-name "Your Name" --git-email "you@example.com"

Options:
  --projects-dir DIR
  --skip-meteor
  --skip-docker
HELP
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_xcode_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi

  echo "Xcode Command Line Tools are required."
  echo "Run: xcode-select --install"
  exit 1
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_shell_profile() {
  local brew_path=""
  local profile="$HOME/.zprofile"

  if [ -x /opt/homebrew/bin/brew ]; then
    brew_path='eval "$(/opt/homebrew/bin/brew shellenv)"'
  elif [ -x /usr/local/bin/brew ]; then
    brew_path='eval "$(/usr/local/bin/brew shellenv)"'
  fi

  if [ -n "$brew_path" ]; then
    touch "$profile"
    if ! grep -Fq "$brew_path" "$profile"; then
      printf '\n%s\n' "$brew_path" >> "$profile"
    fi
  fi

  mkdir -p "$HOME/.local/bin"
  touch "$profile"
  if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$profile"; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$profile"
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

brew_install() {
  local package="$1"
  if brew list "$package" >/dev/null 2>&1; then
    echo "Already installed: $package"
  else
    brew install "$package"
  fi
}

brew_install_cask() {
  local package="$1"
  if brew list --cask "$package" >/dev/null 2>&1; then
    echo "Already installed cask: $package"
  else
    brew install --cask "$package"
  fi
}

configure_git() {
  if [ -n "$GIT_NAME" ]; then
    git config --global user.name "$GIT_NAME"
  fi
  if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
  fi

  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global fetch.prune true
  git config --global core.autocrlf false
}

ensure_ssh_key() {
  local ssh_dir="$HOME/.ssh"
  local key_path="$ssh_dir/id_ed25519"
  local comment="${GIT_EMAIL:-$(whoami)@$(hostname)}"

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [ ! -f "$key_path" ]; then
    ssh-keygen -t ed25519 -C "$comment" -f "$key_path" -N ""
  fi

  echo ""
  echo "SSH public key:"
  cat "$key_path.pub"
}

install_codex_cli() {
  npm install -g @openai/codex
}

install_meteor() {
  if [ "$SKIP_METEOR" -eq 1 ]; then
    return 0
  fi
  npm install -g meteor --ignore-meteor-setup-exec-path --foreground-script
}

install_vscode_extensions() {
  if ! command -v code >/dev/null 2>&1; then
    echo "VS Code CLI 'code' not found yet. Open VS Code and install the shell command if needed."
    return 0
  fi

  local extensions=(
    dbaeumer.vscode-eslint
    svelte.svelte-vscode
    bradlc.vscode-tailwindcss
    esbenp.prettier-vscode
    github.vscode-github-actions
    github.vscode-pull-request-github
    eamodio.gitlens
    ms-azuretools.vscode-docker
    ms-vscode.powershell
  )

  for extension in "${extensions[@]}"; do
    code --install-extension "$extension" --force
  done
}

install_aiwf() {
  local target="$HOME/.local/bin/aiwf"
  cat > "$target" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

command_name="$(basename "$0")"
subcommand="${1:-help}"
if [ "$#" -gt 0 ]; then
  shift
fi

find_root() {
  if [ -n "${CODEX_FLOW_ROOT:-}" ]; then
    cd "$CODEX_FLOW_ROOT"
    pwd
    return 0
  fi
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
    return 0
  fi
  pwd
}

ROOT="$(find_root)"
ISSUES_DIR="${CODEX_FLOW_ISSUES_DIR:-$ROOT/issues}"
SANDBOX="${CODEX_FLOW_SANDBOX:-workspace-write}"
ALLOW_REVIEW_BLOCKERS=0

issue_field() {
  local file="$1"
  local field="$2"
  awk -F': ' -v field="$field" '$0 ~ "^" field ": " { print $2; exit }' "$file"
}

issue_by_id() {
  local id="$1"
  local file
  for file in "$ISSUES_DIR"/*.md; do
    [ -e "$file" ] || continue
    if [ "$(issue_field "$file" id)" = "$id" ]; then
      echo "$file"
      return 0
    fi
  done
  return 1
}

issue_done() {
  local id="$1"
  local file
  file="$(issue_by_id "$id" || true)"
  [ -n "$file" ] && [ "$(issue_field "$file" status)" = "done" ]
}

review_path() {
  local id="$1"
  echo "$ROOT/reviews/$id-review.md"
}

review_passed() {
  local id="$1"
  local file blocking
  file="$(review_path "$id")"
  [ -f "$file" ] || return 1
  blocking="$(issue_field "$file" blocking_findings)"
  [ "$blocking" = "0" ]
}

issue_complete_for_blocker() {
  local id="$1"
  local file status
  file="$(issue_by_id "$id" || true)"
  [ -n "$file" ] || return 1
  status="$(issue_field "$file" status)"
  [ "$status" = "done" ] || { [ "$ALLOW_REVIEW_BLOCKERS" -eq 1 ] && [ "$status" = "review" ] && review_passed "$id"; }
}

issue_unblocked() {
  local file="$1"
  local raw blocker
  raw="$(issue_field "$file" blocked_by)"
  if [ -z "$raw" ] || [ "$raw" = "[]" ]; then
    return 0
  fi

  for blocker in $(printf "%s" "$raw" | sed -E 's/[][]//g; s/,/ /g'); do
    case "$blocker" in
      ISSUE-*)
        if ! issue_complete_for_blocker "$blocker"; then
          return 1
        fi
        ;;
    esac
  done
  return 0
}

next_afk_issue() {
  local file
  [ -d "$ISSUES_DIR" ] || return 1
  for file in "$ISSUES_DIR"/*.md; do
    [ -e "$file" ] || continue
    if [ "$(issue_field "$file" status)" = "todo" ] && \
       [ "$(issue_field "$file" type)" = "AFK" ] && \
       issue_unblocked "$file"; then
      echo "$file"
      return 0
    fi
  done
  return 1
}

next_review_issue() {
  local file id
  [ -d "$ISSUES_DIR" ] || return 1
  for file in "$ISSUES_DIR"/*.md; do
    [ -e "$file" ] || continue
    id="$(issue_field "$file" id)"
    if [ "$(issue_field "$file" status)" = "review" ] && \
       [ "$(issue_field "$file" type)" = "AFK" ] && \
       ! review_passed "$id" && \
       issue_unblocked "$file"; then
      echo "$file"
      return 0
    fi
  done
  return 1
}

codex_review_issue() {
  local file="$1"
  local id review
  mkdir -p "$ROOT/reviews"
  id="$(issue_field "$file" id)"
  review="$(review_path "$id")"
  echo "Reviewing $file -> $review"
  if ! codex --ask-for-approval never exec -C "$ROOT" --sandbox "$SANDBOX" "Use review-work. Review the current uncommitted changes against $file in a fresh context. Do not modify implementation files or issue files. You may only create or replace the review note at $review. Write the review note with YAML-style metadata at the top containing issue: $id, result: pass or needs-fix, and blocking_findings: the count of P0/P1/P2 findings. Use blocking_findings: 0 only when there are no P0/P1/P2 findings. Findings first, ordered by severity. Include tests run or not run. Do not paste the full diff."; then
    echo "Codex review failed while reviewing $file" >&2
    exit 1
  fi
}

codex_fix_findings() {
  local file="$1"
  local id review
  id="$(issue_field "$file" id)"
  review="$(review_path "$id")"
  echo "Fixing review findings for $file from $review"
  if ! codex --ask-for-approval never exec -C "$ROOT" --sandbox "$SANDBOX" "Use implement-issue-tdd. Fix only the blocking findings in $review for $file. Read the issue, review note, linked PRD, and relevant code first. Do not expand scope beyond the review findings. Run the issue test plan and relevant checks. Keep the issue in review, update issue notes with checks run, and stop after this issue."; then
    echo "Codex fix failed while fixing $file" >&2
    exit 1
  fi
}

case "$subcommand" in
  help|-h|--help)
    cat <<HELP
aiwf commands:
  aiwf init
  aiwf root
  aiwf status
  aiwf next
  aiwf next --through-review
  aiwf afk
  aiwf afk --through-review
  aiwf afk --review-between --through-review
  aiwf afk --review-between --fix-findings --through-review
HELP
    ;;
  init)
    mkdir -p "$ROOT/docs/prds" "$ROOT/issues" "$ROOT/reviews" "$ROOT/qa"
    echo "Initialized Codex Flow folders in $ROOT"
    ;;
  root)
    echo "$ROOT"
    ;;
  status)
    [ -d "$ISSUES_DIR" ] || { echo "No issues directory found at $ISSUES_DIR" >&2; exit 1; }
    printf "%-10s %-8s %-5s %-9s %-18s %s\n" "ID" "STATUS" "TYPE" "READY" "BLOCKED_BY" "TITLE"
    for file in "$ISSUES_DIR"/*.md; do
      [ -e "$file" ] || continue
      id="$(issue_field "$file" id)"
      status="$(issue_field "$file" status)"
      type="$(issue_field "$file" type)"
      blocked_by="$(issue_field "$file" blocked_by)"
      title="$(issue_field "$file" title)"
      if [ "$status" = "done" ]; then
        ready="done"
      elif issue_unblocked "$file"; then
        ready="ready"
      else
        ready="blocked"
      fi
      printf "%-10s %-8s %-5s %-9s %-18s %s\n" "$id" "$status" "$type" "$ready" "$blocked_by" "$title"
    done
    ;;
  next)
    for arg in "$@"; do
      if [ "$arg" = "--through-review" ]; then
        ALLOW_REVIEW_BLOCKERS=1
      fi
    done
    next="$(next_afk_issue || true)"
    if [ -n "$next" ]; then echo "$next"; else echo "NO_MORE_AFK_TASKS"; fi
    ;;
  afk)
    completed=0
    review_between=0
    fix_findings=0
    for arg in "$@"; do
      if [ "$arg" = "--through-review" ]; then
        ALLOW_REVIEW_BLOCKERS=1
      elif [ "$arg" = "--review-between" ]; then
        review_between=1
      elif [ "$arg" = "--fix-findings" ]; then
        fix_findings=1
      fi
    done
    echo "Using Codex sandbox: $SANDBOX"
    if [ "$ALLOW_REVIEW_BLOCKERS" -eq 1 ]; then
      echo "Treating review blockers with passing review notes as complete for AFK implementation chaining."
    fi
    if [ "$review_between" -eq 1 ]; then
      echo "Running fresh review-work between AFK implementation steps."
    fi
    if [ "$fix_findings" -eq 1 ]; then
      echo "Fixing blocking review findings automatically until review passes or Codex fails."
    fi
    while true; do
      if [ "$review_between" -eq 1 ]; then
        review_issue="$(next_review_issue || true)"
        if [ -n "$review_issue" ]; then
          review_id="$(issue_field "$review_issue" id)"
          codex_review_issue "$review_issue"
          if ! review_passed "$review_id"; then
            if [ "$fix_findings" -eq 1 ]; then
              codex_fix_findings "$review_issue"
              continue
            fi
            echo "Review for $review_id found blocking findings or did not write blocking_findings: 0; stopping for fixes." >&2
            exit 1
          fi
          continue
        fi
      fi

      next="$(next_afk_issue || true)"
      if [ -z "$next" ]; then
        echo "NO_MORE_AFK_TASKS"
        echo "AFK loop stopped after $completed issue(s)."
        break
      fi

      echo "AFK selecting $next"
      if ! codex --ask-for-approval never exec -C "$ROOT" --sandbox "$SANDBOX" "Use run-afk-loop. Implement exactly this selected unblocked AFK issue: $next. Within this issue, use implement-issue-tdd. Read the linked PRD, blockers, acceptance criteria, affected modules, and test plan. Use TDD where practical. Run the issue test plan and relevant checks. Update the issue status and notes when complete. Do not implement review, done, blocked, or HITL issues. Do not ask for confirmation between AFK issues. Stop this invocation after this issue so aiwf afk can refresh the board."; then
        echo "Codex failed while working on $next" >&2
        exit 1
      fi

      status_after="$(issue_field "$next" status)"
      if [ "$status_after" = "todo" ] && issue_unblocked "$next"; then
        echo "Issue $next is still todo and unblocked after Codex returned; stopping to avoid repeating it." >&2
        exit 1
      fi

      if [ "$review_between" -eq 1 ] && [ "$status_after" = "review" ]; then
        issue_id="$(issue_field "$next" id)"
        codex_review_issue "$next"
        if ! review_passed "$issue_id"; then
          if [ "$fix_findings" -eq 1 ]; then
            codex_fix_findings "$next"
            continue
          fi
          echo "Review for $issue_id found blocking findings or did not write blocking_findings: 0; stopping for fixes." >&2
          exit 1
        fi
      fi

      completed=$((completed + 1))
    done
    ;;
  *)
    echo "Unknown command: $subcommand" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$target"
}

ensure_xcode_tools
ensure_homebrew
ensure_shell_profile

brew update
brew_install git
brew_install gh
brew_install node
brew_install python
brew_install uv
brew_install jq
brew_install ripgrep
brew_install fd
brew_install wget
brew_install mas
brew_install powershell/tap/powershell

brew_install_cask visual-studio-code
brew_install_cask github
brew_install_cask google-chrome
brew_install_cask iterm2
brew_install_cask font-jetbrains-mono

if [ "$SKIP_DOCKER" -eq 0 ]; then
  brew_install_cask docker
fi

mkdir -p "$PROJECTS_DIR"

configure_git
ensure_ssh_key
install_codex_cli
install_meteor
"$ROOT/scripts/install-skills.sh"
install_vscode_extensions
install_aiwf

echo ""
echo "Versions:"
git --version
gh --version | head -n 1
node --version
npm --version
codex --version
if command -v meteor >/dev/null 2>&1; then
  meteor --version
fi

echo ""
echo "Next manual sign-ins:"
echo "  gh auth login"
echo "  gh auth setup-git"
echo "  gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)\""
echo "  codex login"
echo ""
echo "Open Docker once if installed, and sign in to Codex GUI when ready."
