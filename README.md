# dotfilesmd

Bootstrap for my development machines. One command on a fresh macOS or Ubuntu
box installs the tools I use, wires up my shared coding-agent instructions, and
generates a machine-specific SSH key.

[AGENTS.md](AGENTS.md) is the heart of it — my preferences for how agents
investigate problems, write code, and work with me — shared across Claude Code,
Codex, and OpenCode.

## Supported systems

- macOS 13+, Apple Silicon or Intel
- Ubuntu 22.04 / 24.04 LTS and Debian-based derivatives, x86_64 or arm64

Architecture is handled automatically: the Docker apt source is templated with
`dpkg --print-architecture`, and mise resolves the right build per platform.

## Fresh machine

A brand new box has no `git`, so install that first.

**Ubuntu:**

```sh
sudo apt-get update && sudo apt-get install -y git
```

**macOS:** running `git` for the first time prompts you to install the Xcode
Command Line Tools. Accept it and wait for it to finish before continuing.
(`xcode-select --install` starts the same prompt.)

Then, on either:

```sh
git clone https://github.com/painhardcore/dotfilesmd.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

Then open a new shell, or `. ~/.profile`, to pick up the new `PATH`.

The script needs `sudo` only for apt packages on Ubuntu. Everything else
installs into your home directory. Keep the checkout in place — the agent
instruction files are symlinks back to it.

## What to expect at the end

Bootstrap finishes by printing this machine's public key and, on Ubuntu, the
exact commands to run on your MacBook to get key-based login into it:

```text
==> bootstrap complete

SSH public key for this machine:

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMp5EHDy... painhardcore@build01

  /home/painhardcore/.ssh/id_ed25519_dev.pub

Add this key to the infrastructure/access repository when appropriate.
This repository does not grant access to anything by itself.

To log into this machine, run these on your MacBook:

    ssh-copy-id -i ~/.ssh/id_ed25519_dev.pub painhardcore@192.168.1.42

    cat >> ~/.ssh/config <<'SSHCONF'
    Host build01
      HostName 192.168.1.42
      User painhardcore
      IdentityFile ~/.ssh/id_ed25519_dev
    SSHCONF

Then connect with:  ssh build01

Next steps:
  - Reload your PATH:  . ~/.profile
  - Log out and back in for 'docker' group membership to take effect.
  - Run 'claude' once to sign in.
  - Run 'codex' once to sign in.
```

The sign-in and docker-group reminders only appear when that step actually ran,
so a rerun on a settled machine shows just the key and the PATH line.

## What gets installed

| | Source | Why |
|---|---|---|
| git, curl, wget, make, build tools | apt / Homebrew | System-level software with no version to pin |
| Docker + Compose v2 | Docker's own apt repo / Docker Desktop | Ubuntu's `docker.io` lags and has no `docker compose` plugin |
| Go, Node.js, Python | mise | Versions declared in [`mise.toml`](mise.toml) |
| jq, yq, ripgrep, fd, gh | mise | See below |
| Claude Code, Codex | Official installers | Vendor-recommended, self-updating |

The CLI tools come from mise on both operating systems rather than from apt or
Homebrew. Ubuntu's `fd-find` package installs the binary as `fdfind`, and
Ubuntu's `yq` is a Python wrapper around jq rather than mikefarah's `yq`.
`AGENTS.md` tells agents to call `rg`, `fd`, and `yq` by name, so the names and
versions need to be identical everywhere.

macOS keeps its built-in `curl`, `make`, and `rsync`; only `git` and `wget` come
from Homebrew. If Homebrew is missing it is installed first, using its official
installer.

The two agent CLIs are installed with their vendors' shell installers, which is
the documented path for both and gives binaries that update themselves. The
installer is downloaded to a temporary file and then run, rather than piped
straight into a shell. Claude Code also publishes a signed apt repository if a
package-manager install is ever preferred over the auto-updating native one.

## Shared agent instructions

`AGENTS.md` is the canonical file. Bootstrap symlinks it to:

| Tool | Path |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |

Because they are symlinks, editing `AGENTS.md` here takes effect immediately —
no resync step.

If one of those paths already holds a real file or a link somewhere else, it is
moved to `<path>.backup-<timestamp>` and the move is printed. Nothing is
silently overwritten.

## Skills

[`skills/`](skills/) is the source of truth for my personal agent skills. One
directory per skill, each holding a `SKILL.md`:

```
skills/
└── my-skill/
    └── SKILL.md
```

Add a new skill by creating its directory here and rerunning `./bootstrap.sh`.

Bootstrap mirrors each skill directory into `~/.claude/skills/<name>/` and
`~/.agents/skills/<name>/`. These are copies, not symlinks, because not every
agent follows a directory symlink reliably.

Each skill is synced individually with `rsync -a --delete`. A file you delete
from a skill here disappears from the installed copy, but skills that other
tools installed into those directories are never touched. Nothing is ever
copied back into this repository, so generated, machine-specific, or
third-party skills stay out of git.

## Versions

All tool versions live in [`mise.toml`](mise.toml), which bootstrap symlinks to
`~/.config/mise/config.toml`.

- `go = "latest"` and `node = "lts"` track a moving target so machines converge
  without a maintenance commit every release.
- `python = "3.13"` pins the series, because 3.x minor bumps invalidate existing
  virtualenvs.
- The CLI tools track `latest`; none of them has an API worth pinning.

To upgrade everything to current versions: `mise upgrade`.

`shell/init.sh` puts mise's shims on `PATH` instead of using `mise activate`.
Ubuntu's default `~/.bashrc` returns early for non-interactive shells, so an
activate hook there would leave `ssh host 'go version'` broken. Shims are just a
directory on `PATH`, so bash, zsh, and non-interactive shells all behave the
same. The trade-off is no automatic per-project environment switching; use
`mise exec` or a project-local `mise.toml` for that.

Bootstrap writes a single `source` line to `~/.profile`, and to `~/.bashrc` and
`~/.zshrc` if those already exist. It never installs a shell and never rewrites
existing lines.

## Updating

There is one implementation. `make update` is just `./bootstrap.sh`, and every
step checks before acting, so rerunning is always safe.

```sh
cd ~/.dotfiles
make update    # apply the working tree: ./bootstrap.sh
make pull      # git pull --ff-only, then apply
make check     # syntax-check every script
```

Use `make update` after editing anything here — a skill, `AGENTS.md`,
`mise.toml`. It works whether or not the tree is clean, which `git pull` does
not. Use `make pull` to take a change you made on another machine.

Every run also upgrades mise-managed tools to the newest version **inside** the
range `mise.toml` declares, so `go = "latest"` moves forward on its own while
`python = "3.13"` stays on the 3.13 series. Crossing a range boundary is a
deliberate edit to `mise.toml` (or `mise upgrade --bump`); mise prints a note
when a newer out-of-range version exists. System packages are never upgraded —
that is your OS's job, not this repo's.

A rerun that changes nothing is quiet: already-installed packages are skipped,
and a skill is only reported when its contents actually changed.

## SSH key

Bootstrap ensures `~/.ssh/id_ed25519_dev` exists, generating it if absent with a
comment of `username@hostname`. An existing key is left completely untouched.
The key has no passphrase, so bootstrap can complete unattended on a remote
machine.

The public key is printed at the end of every run. To print it again later:

```sh
cat ~/.ssh/id_ed25519_dev.pub
```

The private key is never printed, never committed, and never leaves the machine.

### Logging into an Ubuntu machine by key

On Ubuntu, bootstrap ends by printing the commands to run **on your MacBook** to
get key-based login into that machine, with the real address and username
already filled in:

```sh
ssh-copy-id -i ~/.ssh/id_ed25519_dev.pub painhardcore@192.168.1.42

cat >> ~/.ssh/config <<'SSHCONF'
Host build01
  HostName 192.168.1.42
  User painhardcore
  IdentityFile ~/.ssh/id_ed25519_dev
SSHCONF
```

After that, `ssh build01` works with no address, username, or `-i` flag.

The `-i` is explicit on purpose: without it `ssh-copy-id` pushes whichever
default identity it finds first, which need not be the key the config block then
tells `ssh` to use. It assumes your MacBook was also bootstrapped from this repo
and so has its own `~/.ssh/id_ed25519_dev`; if not, drop the `-i` flag and the
`IdentityFile` line to use its default key.

If password login is disabled on the Ubuntu box, `ssh-copy-id` cannot connect at
all. Bootstrap prints the fallback too: append your MacBook's public key to
`~/.ssh/authorized_keys` on that machine by hand.

The address comes from the source address of the machine's default route, so on
a cloud host behind NAT it will be a private IP — substitute the reachable
hostname or address.

Note the two keys point in opposite directions. `id_ed25519_dev` is generated so
the machine can authenticate *outward*; `ssh-copy-id` authorizes your laptop to
get *in*. Neither is managed by this repository — it only prints the command.

### This repository does not grant access to any infrastructure

It generates a keypair and shows you the public half. That is all. It does not
modify `authorized_keys` anywhere, does not connect to any server, does not keep
an inventory of hosts, and does not upload the key to GitHub or anywhere else.
Granting the key access is a separate, deliberate, manual step.

## Layout

```
dotfilesmd/
├── AGENTS.md          canonical agent instructions
├── bootstrap.sh       entry point: helpers, OS detection, the driver
├── mise.toml          tool versions
├── Makefile           bootstrap / update / check
├── shell/init.sh      PATH setup, sourced by your shell and by bootstrap
├── skills/            personal agent skills
└── install/
    ├── macos.sh       Homebrew and macOS packages
    ├── ubuntu.sh      apt packages and Docker
    ├── agents.sh      AGENTS.md symlinks and skills sync
    └── ssh.sh         machine-specific SSH key
```

The files under `install/` are sourced by `bootstrap.sh` and share its helpers,
so they are not run directly.
