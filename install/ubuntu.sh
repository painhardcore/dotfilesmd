# Sourced by bootstrap.sh -- uses its log/have/notice/$SUDO helpers.
# System-level packages for Ubuntu/Debian. Language runtimes and CLI tools come
# from mise instead; see mise.toml. Notably jq, yq, ripgrep, fd and gh are NOT
# installed from apt: apt's fd-find provides the binary as `fdfind`, and apt's
# `yq` is the Python jq wrapper rather than mikefarah's yq.

# Read here rather than relying on bootstrap's detect_os, which runs in a command
# substitution where a sourced /etc/os-release would be lost. UBUNTU_CODENAME is
# preferred: derivatives (Mint, Pop!_OS) set VERSION_CODENAME to their own release
# name, which neither the Docker nor the Tailscale repository publishes.
# shellcheck disable=SC1091
. /etc/os-release
codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
[ -n "$codename" ] || die "cannot determine the distribution codename for apt repositories"

log "installing system packages with apt"
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get install -y --no-install-recommends \
  ca-certificates curl wget git make build-essential gnupg rsync openssh-client

# Docker from the official docker.com repository. Ubuntu's own docker.io package
# lags and ships no `docker compose` v2 plugin.
if have docker; then
  log "docker already installed, skipping"
else
  log "adding the Docker apt repository"
  $SUDO install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc
  fi
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "installing Docker Engine and the compose plugin"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Running docker without sudo needs group membership, which only takes effect on
# the next login. Skipped when already a member, and when running as root.
me="$(id -un)"
if [ -n "$SUDO" ] && ! id -nG "$me" | tr ' ' '\n' | grep -qx docker; then
  log "adding $me to the 'docker' group"
  $SUDO usermod -aG docker "$me"
  notice "Log out and back in for 'docker' group membership to take effect."
fi

# Tailscale gives this machine a stable address reachable from anywhere, which
# is what the SSH block at the end of bootstrap prefers over the LAN IP.
# Install only: joining a tailnet needs an interactive login, so that stays manual.
if have tailscale; then
  log "tailscale already installed, skipping"
else
  log "adding the Tailscale apt repository"
  # Tailscale publishes the sources.list file itself (no arch to template, the
  # repo is multi-arch) and it references this keyring path absolutely, so the
  # key must land in /usr/share/keyrings rather than /etc/apt/keyrings.
  if [ ! -f /usr/share/keyrings/tailscale-archive-keyring.gpg ]; then
    $SUDO curl -fsSL "https://pkgs.tailscale.com/stable/$ID/$codename.noarmor.gpg" \
      -o /usr/share/keyrings/tailscale-archive-keyring.gpg
  fi
  $SUDO curl -fsSL "https://pkgs.tailscale.com/stable/$ID/$codename.tailscale-keyring.list" \
    -o /etc/apt/sources.list.d/tailscale.list

  log "installing tailscale"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y tailscale
  notice "Join your tailnet with 'sudo tailscale up', then rerun 'make update'."
fi
