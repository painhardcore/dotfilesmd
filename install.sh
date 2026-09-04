#!/usr/bin/env bash

set -eu

mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.codex"
mkdir -p "$HOME/.config/opencode"

ln -sfn "$HOME/Data/40_CODE/active/dotfilesmd/AGENTS.md" \
  "$HOME/.claude/CLAUDE.md"

ln -sfn "$HOME/Data/40_CODE/active/dotfilesmd/AGENTS.md" \
  "$HOME/.codex/AGENTS.md"

ln -sfn "$HOME/Data/40_CODE/active/dotfilesmd/AGENTS.md" \
  "$HOME/.config/opencode/AGENTS.md"
