#!/usr/bin/env bash
# Bootstrap a development machine from this repository.
#
#   git clone https://github.com/painhardcore/dotfilesmd.git ~/.dotfiles
#   cd ~/.dotfiles && ./bootstrap.sh
#
# Safe to rerun: every step checks before it acts. Rerunning after `git pull`
# is also the update path, so there is no separate updater to keep in sync.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Empty when already root (containers, cloud images) so the same scripts work
# with or without sudo installed.
SUDO=""
# shellcheck disable=SC2034  # used by install/ubuntu.sh, which is sourced below
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

# Things the user must do by hand, printed once at the end.
# A newline-delimited string rather than an array: macOS still ships bash 3.2,
# where empty arrays trip `set -u`.
NOTICES=""
notice() { NOTICES="${NOTICES}${1}
"; }

# Scratch space for downloaded installers.
TMPDIR_BOOTSTRAP="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BOOTSTRAP"' EXIT

# Symlink src -> dst without destroying whatever was already there.
link() {
  src="$1"; dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup="${dst}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    warn "moved existing $dst to $backup"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  log "linked $dst -> $src"
}

# Mirror each skill directory on its own, so skills that other tools installed
# into the destination (e.g. ~/.agents/skills managed by a skill manager) are
# never touched. A whole-directory --delete would wipe them.
mirror_skills() {
  src="$1"; dest="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dest"
  for skill in "$src"/*/; do
    [ -d "$skill" ] || continue          # no skills yet: glob stayed literal
    name="$(basename "$skill")"
    # --itemize-changes so a rerun that changes nothing stays silent.
    changes="$(rsync -a --delete --itemize-changes "$skill" "$dest/$name/")"
    if [ -n "$changes" ]; then
      log "updated skill '$name' in $dest"
    fi
  done
}

# Add the init line to a shell rc file, once.
rc_line() {
  file="$1"
  line=". \"$REPO/shell/init.sh\""
  if grep -qF "$line" "$file" 2>/dev/null; then
    return 0
  fi
  printf '\n# dotfilesmd\n%s\n' "$line" >> "$file"
  log "added init line to $file"
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      [ -r /etc/os-release ] || die "no /etc/os-release; cannot identify this Linux"
      # shellcheck disable=SC1091
      . /etc/os-release
      case ":${ID:-}:${ID_LIKE:-}:" in
        *:ubuntu:*|*:debian:*) echo ubuntu ;;
        *) die "unsupported Linux distribution '${ID:-unknown}'; this repo targets Ubuntu/Debian" ;;
      esac
      ;;
    *) die "unsupported OS '$(uname -s)'; this repo targets macOS and Ubuntu" ;;
  esac
}

install_mise() {
  have mise && return 0
  log "installing mise"
  if [ "$OS" = macos ]; then
    brew install mise
  else
    # mise ships a static binary and installs into ~/.local/bin with no root.
    # Downloaded to a file first rather than piped straight into a shell.
    curl -fsSL https://mise.run -o "$TMPDIR_BOOTSTRAP/mise-install.sh"
    bash "$TMPDIR_BOOTSTRAP/mise-install.sh"
  fi
}

# Claude Code and Codex are distributed as self-updating standalone binaries.
# Their vendors document a shell installer as the recommended path and publish
# no plain binary URL that stays stable, so we use it -- fetched to a file so it
# can be inspected, rather than `curl | sh`.
install_agent_cli() {
  name="$1"; url="$2"
  have "$name" && return 0
  log "installing $name"
  script="$TMPDIR_BOOTSTRAP/$name-install.sh"
  curl -fsSL "$url" -o "$script" || die "could not download the $name installer from $url"
  # bash, not sh: these installers use bash syntax and Ubuntu's /bin/sh is dash.
  bash "$script"
  notice "Run '$name' once to sign in."
}

OS="$(detect_os)"
log "bootstrapping for $OS from $REPO"

# 1. System packages, per OS.
# shellcheck source=/dev/null
. "$REPO/install/$OS.sh"

# 2. Language runtimes and CLI tools, declared in mise.toml.
install_mise
link "$REPO/mise.toml" "$HOME/.config/mise/config.toml"
# shellcheck source=/dev/null
. "$REPO/shell/init.sh"     # puts ~/.local/bin and the mise shims on PATH for the rest of this run
have mise || die "mise is installed but not on PATH; check $HOME/.local/bin"
log "installing tools from mise.toml"
mise install
# Move installed tools to the newest version still inside their declared range.
# Cheap when already converged, and it will not cross a range boundary (that
# needs `mise upgrade --bump`), so python stays on the pinned 3.x series.
mise upgrade

# 3. Coding agent CLIs.
install_agent_cli claude https://claude.ai/install.sh
install_agent_cli codex  https://chatgpt.com/codex/install.sh

# 4. Shell wiring. ~/.profile is written unconditionally because a login shell
#    of any flavour reads it; bashrc/zshrc only if the user already has them.
#    No shell is installed and no existing lines are rewritten.
touch "$HOME/.profile"
rc_line "$HOME/.profile"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ]; then rc_line "$rc"; fi
done

# 5. Shared agent instructions and skills.
# shellcheck source=/dev/null
. "$REPO/install/agents.sh"

# 6. Machine-specific SSH key.
# shellcheck source=/dev/null
. "$REPO/install/ssh.sh"

echo
log "bootstrap complete"
echo
echo "SSH public key for this machine:"
echo
cat "$SSH_KEY.pub"
echo
echo "  $SSH_KEY.pub"
echo
echo "Add this key to the infrastructure/access repository when appropriate."
echo "This repository does not grant access to anything by itself."

# Key-based login *into* this machine is what you want on a remote box. macOS
# ships with Remote Login off, so the same block there would be wrong.
if [ "$OS" = ubuntu ]; then
  echo
  echo "To log into this machine, run these on your MacBook:"
  echo
  # -i explicitly, matching the IdentityFile below: without it ssh-copy-id
  # pushes whichever default identity it finds first, which need not be the key
  # the config block then tells ssh to use.
  echo "    ssh-copy-id -i ~/.ssh/id_ed25519_dev.pub $SSH_TARGET"
  echo
  # Quoted heredoc: everything inside is printed literally, so the EOF and the
  # indentation land in the user's terminal exactly as they must be pasted.
  cat <<EOF
    cat >> ~/.ssh/config <<'SSHCONF'
    Host $SSH_HOST_ALIAS
      HostName ${SSH_TARGET#*@}
      User ${SSH_TARGET%@*}
      IdentityFile ~/.ssh/id_ed25519_dev
    SSHCONF
EOF
  echo
  echo "Then connect with:  ssh $SSH_HOST_ALIAS"
  echo
  echo "(That assumes your MacBook has also been bootstrapped from this repo,"
  echo "so it has its own ~/.ssh/id_ed25519_dev. If not, drop the -i flag and"
  echo "the IdentityFile line to use its default key.)"
  echo
  echo "If password login is disabled here, ssh-copy-id cannot work. Append"
  echo "your MacBook's public key on this machine instead:"
  echo
  echo "    echo 'ssh-ed25519 ...your MacBook key...' >> ~/.ssh/authorized_keys"
fi

echo
echo "Next steps:"
echo "  - Reload your PATH:  . ~/.profile"
if [ -n "$NOTICES" ]; then
  printf '%s' "$NOTICES" | sed 's/^/  - /'
fi
