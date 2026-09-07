# Sourced by bootstrap.sh -- uses its link/mirror_skills helpers.
# AGENTS.md in this repository is the canonical instruction file; the three
# agent config paths are symlinks to it, so editing the repo takes effect
# immediately with no resync.

log "linking AGENTS.md"
link "$REPO/AGENTS.md" "$HOME/.claude/CLAUDE.md"              # Claude Code
link "$REPO/AGENTS.md" "$HOME/.codex/AGENTS.md"               # Codex
link "$REPO/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"     # OpenCode

# Skills are copied rather than symlinked: not every agent follows a directory
# symlink reliably. The repo is the source of truth and nothing syncs back.
log "syncing skills"
mirror_skills "$REPO/skills" "$HOME/.claude/skills"    # Claude Code
mirror_skills "$REPO/skills" "$HOME/.agents/skills"    # Codex / OpenCode
