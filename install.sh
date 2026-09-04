#!/usr/bin/env bash

set -eu

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.codex"
mkdir -p "$HOME/.config/opencode"

ln -sfn "$repo_dir/AGENTS.md" \
  "$HOME/.claude/CLAUDE.md"

ln -sfn "$repo_dir/AGENTS.md" \
  "$HOME/.codex/AGENTS.md"

ln -sfn "$repo_dir/AGENTS.md" \
  "$HOME/.config/opencode/AGENTS.md"
