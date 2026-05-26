#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/skills"
TARGET="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"

if [ ! -d "$SOURCE" ]; then
  echo "No skills directory found at $SOURCE" >&2
  exit 1
fi

mkdir -p "$TARGET"

find "$SOURCE" -mindepth 1 -maxdepth 1 -type d | sort | while read -r skill; do
  name="$(basename "$skill")"
  if [ ! -f "$skill/SKILL.md" ]; then
    echo "Skipping $name: no SKILL.md" >&2
    continue
  fi

  rm -rf "$TARGET/$name"
  cp -R "$skill" "$TARGET/$name"
  echo "Installed $name -> $TARGET/$name"
done

echo "Done. Restart Codex if it was already open."
