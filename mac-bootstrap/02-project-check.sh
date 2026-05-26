#!/usr/bin/env bash
set -euo pipefail

REPO=""
PROJECTS_DIR="$HOME/Code"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --projects-dir)
      PROJECTS_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'HELP'
Usage:
  ./mac-bootstrap/02-project-check.sh
  ./mac-bootstrap/02-project-check.sh --repo OWNER/REPO
HELP
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [ -n "$REPO" ]; then
  mkdir -p "$PROJECTS_DIR"
  cd "$PROJECTS_DIR"
  gh repo clone "$REPO"
  cd "$(basename "$REPO" .git)"
fi

echo "Project root:"
git rev-parse --show-toplevel

if command -v aiwf >/dev/null 2>&1; then
  aiwf init
fi

npm install
npm test
npm run check
npm run lint

echo "Project check complete."
