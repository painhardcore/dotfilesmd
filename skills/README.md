# Skills

Personal, reusable agent skills. This directory is the source of truth.

One directory per skill, each containing a `SKILL.md`:

```
skills/
└── my-skill/
    └── SKILL.md
```

`./bootstrap.sh` mirrors each skill directory into:

- `~/.claude/skills/<name>/` — Claude Code
- `~/.agents/skills/<name>/` — Codex / OpenCode

Each directory is synced individually with `rsync -a --delete`, so a file
removed from a skill here disappears there too, while skills installed by other
tools alongside them are left alone. Nothing is ever copied back into this
repository, so generated, machine-specific, or third-party skills stay out.
