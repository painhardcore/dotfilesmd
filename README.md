# dotfilesmd

My personal instructions for coding agents. I'm Andrei Iurchenkov, and [AGENTS.md](AGENTS.md) holds my preferences for how agents investigate problems, write code, and work with me.

I share the same file across Claude Code, Codex, and OpenCode through symlinks.

## Install

From this checkout, run:

```sh
bash install.sh
```

The script creates the configuration directories and links `AGENTS.md` to these paths:

| Tool | Path |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |

Existing files or symlinks at these paths are replaced without a backup. Save anything you want to keep before running the script.

Edit `AGENTS.md` here to update the shared instructions. Keep the checkout in place so the links keep working. If you move it, run the installer again from its new location.
