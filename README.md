# dotfilesmd

Bootstrap for my development machines. One command on a fresh macOS or Ubuntu
box installs the tools I use, wires up my shared coding-agent instructions, and
generates a machine-specific SSH key.

[AGENTS.md](AGENTS.md) is the heart of it: my preferences for how agents
investigate problems, write code, and work with me, shared across Claude Code,
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

That is the whole story for a laptop. For an Ubuntu box that also joins the
tailnet and gets login keys, follow [Adding a new build
machine](#adding-a-new-build-machine) instead.

The script needs `sudo` only for apt packages on Ubuntu. Everything else
installs into your home directory. Keep the checkout in place, because the
agent instruction files are symlinks back to it.

## Adding a new build machine

Start to finish this takes about ten minutes, and most of that is waiting for
Go, Node, Python, and Rust to download.

### Before you start

You need a shell on the new box already, through a cloud provider's console, a
keyboard, or password SSH. Bootstrap cannot hand you your first login. You also
need your phone for one GitHub device code.

### 1. Name the machine

```sh
sudo hostnamectl set-hostname build01
```

Do this before anything else. The hostname becomes the filename of the key
committed to `infra/keys/`, and the `Host` alias in the SSH config block printed
at the end. A cloud image's default `ubuntu-2gb-nbg1-1` works, but you will be
reading it for years. If you skip this step, pass `MACHINE_NAME=build01` to
`make private` in step 5.

### 2. Install git and clone

```sh
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/painhardcore/dotfilesmd.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. Run bootstrap

```sh
./bootstrap.sh
. ~/.profile
```

This installs the apt packages, Docker, Tailscale, mise and its toolchain,
Claude Code, and Codex, then generates `~/.ssh/id_ed25519_dev`. It uses no
credentials and is safe to rerun at any point.

Sourcing `~/.profile` puts the mise shims on `PATH` for the current shell. A new
login shell picks them up on its own.

### 4. Authenticate to GitHub

```sh
gh auth login -s admin:public_key
```

Choose GitHub.com, HTTPS, then "Login with a web browser". `gh` prints an
eight-character code. Open the URL on your phone, enter the code, approve.

Do not drop the `-s admin:public_key`. Without that scope, step 5 stops when it
tries to register the machine's key. If you already logged in without it:

```sh
gh auth refresh -h github.com -s admin:public_key
```

### 5. Join everything up

```sh
make private KEYS=macbookm1
```

Five things happen. It clones `infra` to `~/infra`, joins the tailnet as
`tag:build`, commits and pushes `keys/build01.pub`, registers that key with your
GitHub account, and writes `macbookm1.pub` into `~/.ssh/authorized_keys`.

`KEYS=` names the files in `infra/keys/` that may log into this machine, without
the `.pub` suffix. Run `make private` with no `KEYS=` first if you want to see
what is available; it installs nothing and prints the list.

### 6. Log in from your Mac

The run ends by printing the machine's tailnet address and a config block to
paste on your Mac:

```sh
cat >> ~/.ssh/config <<'SSHCONF'
Host build01
  HostName build01.taile1400.ts.net
  User painhardcore
  IdentityFile ~/.ssh/id_ed25519_dev
SSHCONF
```

Then `ssh build01` from anywhere on the tailnet.

The banner also prints an `ssh-copy-id` line. Skip it if your Mac's key was in
`KEYS=` at step 5, because `make private` already installed it. Use it only to
add a key that is not tracked in `infra/keys/`.

### 7. Sign in to the agents

```sh
claude
codex
```

Each opens a browser login the first time. On a headless box they print a URL to
open elsewhere.

### 8. Grant server access, if this machine needs it

Nothing so far lets `build01` reach srv1 or srv2. Its key is on record in
`infra/keys/` and that is all. Granting is a separate decision you make from
your Mac:

```sh
cd ~/infra
make keys-diff HOST=srv1    # preview
make keys HOST=srv1         # apply
```

The machine can already push to your repositories as you, because step 5
registered its key with your GitHub account.

### Checking it worked

```sh
tailscale status          # this machine, tagged tag:build
docker compose version    # v2, from docker.com's repo
go version && node --version && python --version && rustc --version
gh auth status            # scopes include admin:public_key
```

`docker ps` failing with a permission error means the `docker` group has not
applied yet. Log out and back in.

### Later

```sh
cd ~/.dotfiles
make pull                     # git pull, then reapply
make private KEYS=macbookm1   # re-sync keys and tailnet
```

Both are idempotent. `make private` makes no commit when the key has not
changed, and skips the tailnet join when the machine is already up.

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
| Go, Node.js, Python, Rust | mise | Versions declared in [`mise.toml`](mise.toml) |
| jq, yq, ripgrep, fd, gh | mise | See below |
| Claude Code, Codex | Official installers | Vendor-recommended, self-updating |
| Tailscale (Ubuntu only) | Tailscale's own apt repo | Gives the machine a stable address reachable from anywhere |

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

### Tailscale

On Ubuntu, bootstrap installs Tailscale from Tailscale's own apt repository. It
is not installed on macOS. Install it there yourself.

Bootstrap only installs the package. It never joins a tailnet: that needs an
interactive login, and this repository holds no credentials. Joining is a manual
step, and it appears in the "Next steps" footer after a fresh install:

```sh
sudo tailscale up
```

Once the machine is on your tailnet, rerun `make update`. The SSH block will
then print the machine's tailnet address instead of its LAN IP, which is
stable and reachable from outside the network. See [SSH key](#ssh-key) below.

## Shared agent instructions

`AGENTS.md` is the canonical file. Bootstrap symlinks it to:

| Tool | Path |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |

Because they are symlinks, editing `AGENTS.md` here takes effect immediately.
There is no resync step.

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

## Private repository

`./bootstrap.sh` never touches a credential. Everything that needs your identity
(the private `infra` repo, the tailnet, and login keys) lives behind
`make private`.

```sh
./bootstrap.sh                       # tools, key, configs. No credentials.
gh auth login -s admin:public_key    # once per machine, ~30 seconds
make private KEYS=macbookm1
```

### Why the extra step

Reaching a private repo needs a credential, and the tailnet auth key lives in
that repo. Something has to be injected by hand the first time. There is no way
around it on a genuinely fresh machine.

`gh auth login` makes that step as small as possible. It uses OAuth device flow:
it prints a code, you approve it on your phone, and the token goes to the system
keyring. No SSH key is involved, so the chicken-and-egg never forms. `gh` is
already installed by `bootstrap.sh`, and the clone happens over HTTPS.

The `-s admin:public_key` scope is required to register this machine's key with
your GitHub account. A plain `gh auth login` does not request it, and
`make private` will stop and tell you to run
`gh auth refresh -h github.com -s admin:public_key` if it is missing.

`make private` also runs `gh auth setup-git`, which adds `gh` as a git
credential helper in your global git config so `git push` works over HTTPS.

### What `make private` does

1. Clones `painhardcore/infra` to `~/infra`, or fast-forwards it. A diverged
   checkout stops the run rather than being merged automatically.
2. Joins the tailnet as `tag:build` using the auth key tracked in the repo,
   skipping if already up. The key is passed as `--auth-key file:...` rather
   than on the command line, where it would be visible in `ps`.
3. Copies this machine's public key to `infra/keys/<hostname>.pub`, then commits
   and pushes, but only when it actually changed.
4. Registers the key with your GitHub account, skipping if already present.
5. Writes the keys named in `KEYS=` into `~/.ssh/authorized_keys`.

Override the key filename with `MACHINE_NAME=`, the clone path with
`INFRA_DIR=`, and the tailnet tag with `TS_TAG=`.

### Committing a key stages access, it does not grant it

`infra/keys/*.pub` grants root on every enabled host, but only when you run
`make keys HOST=...` in that repo. `make private` never does. It puts the key on
record and leaves the decision to you:

```sh
cd ~/infra
make keys-diff HOST=srv1    # preview
make keys HOST=srv1         # apply
```

Because the machine's key is also registered with your GitHub account, that
machine can push to your repositories as you. A compromised build box therefore
reaches your GitHub, not just itself.

### KEYS=

`KEYS` is a comma-separated list of filenames in `infra/keys/`, without the
`.pub`:

```sh
make private KEYS=macbookm1,phone
```

Run it with no `KEYS=` and nothing is installed; the available names are printed
so the next run can name them. A name with no matching file stops the run and
lists what exists.

The keys land between `# BEGIN MANAGED BY dotfilesmd` and `# END MANAGED BY
dotfilesmd`. Only that block is rewritten, so keys you added by hand stay put,
and so does the separate block `infra`'s own `make keys` manages. Dropping a
name from `KEYS=` removes it on the next run.

## Updating

There is one implementation. `make update` is just `./bootstrap.sh`, and every
step checks before acting, so rerunning is always safe.

```sh
cd ~/.dotfiles
make update    # apply the working tree: ./bootstrap.sh
make pull      # git pull --ff-only, then apply
make check     # syntax-check every script
```

Use `make update` after editing anything here: a skill, `AGENTS.md`,
`mise.toml`. It works whether or not the tree is clean, which `git pull` does
not. Use `make pull` to take a change you made on another machine.

Every run also upgrades mise-managed tools to the newest version **inside** the
range `mise.toml` declares, so `go = "latest"` moves forward on its own while
`python = "3.13"` stays on the 3.13 series. Crossing a range boundary is a
deliberate edit to `mise.toml` (or `mise upgrade --bump`); mise prints a note
when a newer out-of-range version exists. System packages are never upgraded.
That is your OS's job, not this repo's.

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

`id_ed25519_dev` is not one of the default filenames `ssh` offers on its own
(`id_rsa`, `id_ed25519`, and so on), so bootstrap also writes a managed block to
`~/.ssh/config` pointing every host at it:

```
# BEGIN MANAGED BY dotfilesmd
Host *
  IdentityFile ~/.ssh/id_ed25519_dev

Host github.com
  IdentitiesOnly yes
# END MANAGED BY dotfilesmd
```

Without it, `git clone git@github.com:...` and `ssh` to hosts that trust
`infra/keys/` fail with `Permission denied (publickey)` even once the key is
registered, because `ssh` never offers the key. An explicit `IdentityFile` also
means `ssh` stops offering the default filenames, so any other key must be named
in your own `Host` block. `IdentitiesOnly` stops `ssh` from trying every other
key first, which GitHub counts against its authentication attempt limit. It is
limited to `github.com` because elsewhere it would also block keys from a
forwarded agent. Lines outside the managed block are left untouched.

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

The address is the best one available, most stable first:

1. The machine's tailnet address: its MagicDNS name, or its `100.x` address
   if MagicDNS is off. Stable and reachable from anywhere.
2. The source address of its default route, a LAN IP. On a cloud host behind
   NAT this is private, so substitute the reachable address.
3. Its hostname, when there is nothing better.

A first bootstrap always falls back to the LAN IP, because Tailscale has only
just been installed and is not up yet. The banner says so. Run
`sudo tailscale up`, then `make update`, and it prints the tailnet address.

Note the two keys point in opposite directions. `id_ed25519_dev` is generated so
the machine can authenticate *outward*; `ssh-copy-id` authorizes your laptop to
get *in*. Neither is managed by this repository, which only prints the command.

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
