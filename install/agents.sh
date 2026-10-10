# Sourced by bootstrap.sh -- uses its link/mirror_skills helpers.
# AGENTS.md in this repository is the canonical instruction file; the three
# agent config paths are symlinks to it, so editing the repo takes effect
# immediately with no resync.

log "linking AGENTS.md"
link "$REPO/AGENTS.md" "$HOME/.claude/CLAUDE.md"              # Claude Code
link "$REPO/AGENTS.md" "$HOME/.codex/AGENTS.md"               # Codex
link "$REPO/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"     # OpenCode

# scout is the cheap-model subagent that AGENTS.md delegates read-only legwork
# to. Each tool takes the model from its own definition file. Linked one file
# at a time so other agents in those directories are left alone.
log "linking subagents"
link "$REPO/agents/scout.md"   "$HOME/.claude/agents/scout.md"    # Claude Code
link "$REPO/agents/scout.toml" "$HOME/.codex/agents/scout.toml"   # Codex

# Skills are copied rather than symlinked: not every agent follows a directory
# symlink reliably. The repo is the source of truth and nothing syncs back.
log "syncing skills"
mirror_skills "$REPO/skills" "$HOME/.claude/skills"    # Claude Code
mirror_skills "$REPO/skills" "$HOME/.agents/skills"    # Codex / OpenCode
