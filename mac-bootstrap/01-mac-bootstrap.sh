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

case "$subcommand" in
  help|-h|--help)
    cat <<HELP
aiwf commands:
  aiwf init
  aiwf root
  aiwf status
  aiwf next
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
    printf "%-10s %-8s %-5s %-18s %s\n" "ID" "STATUS" "TYPE" "BLOCKED_BY" "TITLE"
    for file in "$ISSUES_DIR"/*.md; do
      [ -e "$file" ] || continue
      id="$(awk -F': ' '/^id: / { print $2; exit }' "$file")"
      status="$(awk -F': ' '/^status: / { print $2; exit }' "$file")"
      type="$(awk -F': ' '/^type: / { print $2; exit }' "$file")"
      blocked_by="$(awk -F': ' '/^blocked_by: / { print $2; exit }' "$file")"
      title="$(awk -F': ' '/^title: / { print $2; exit }' "$file")"
      printf "%-10s %-8s %-5s %-18s %s\n" "$id" "$status" "$type" "$blocked_by" "$title"
    done
    ;;
  next)
    [ -d "$ISSUES_DIR" ] || { echo "NO_MORE_AFK_TASKS"; exit 0; }
    for file in "$ISSUES_DIR"/*.md; do
      [ -e "$file" ] || continue
      status="$(awk -F': ' '/^status: / { print $2; exit }' "$file")"
      type="$(awk -F': ' '/^type: / { print $2; exit }' "$file")"
      blocked_by="$(awk -F': ' '/^blocked_by: / { print $2; exit }' "$file")"
      if [ "$status" = "todo" ] && [ "$type" = "AFK" ] && { [ -z "$blocked_by" ] || [ "$blocked_by" = "[]" ]; }; then
        echo "$file"
        exit 0
      fi
    done
    echo "NO_MORE_AFK_TASKS"
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
