# Sourced by bootstrap.sh.
# Ensures a machine-specific Ed25519 key exists. This repository never uploads
# it, never touches authorized_keys, and never contacts a server. Granting the
# key access is a separate, manual step.

SSH_KEY="$HOME/.ssh/id_ed25519_dev"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$SSH_KEY" ]; then
  log "ssh key already exists at $SSH_KEY, leaving it untouched"
else
  log "generating $SSH_KEY"
  # No passphrase: bootstrap has to complete unattended on a remote machine.
  # $USER and `hostname` are not guaranteed on minimal images; id/uname always are.
  ssh_host="$(uname -n)"
  ssh-keygen -t ed25519 -N "" \
    -C "$(id -un)@${ssh_host%%.*}" \
    -f "$SSH_KEY"
fi

# Best-effort address for the "log in from elsewhere" hint printed at the end,
# most stable first. Every assignment ends in `|| true`: under `set -o pipefail`
# a missing command (no `ip` on macOS, no `tailscale` before it is installed)
# fails the pipeline and would abort the whole run.
SSH_TARGET=""

# 1. Tailnet address: stable, and reachable from outside this LAN. The MagicDNS
#    name is preferred over the 100.x IP because it is readable and survives an
#    address change; `.Self.DNSName` comes back with a trailing dot to strip.
#    Empty until `tailscale up` has run, so a first bootstrap falls through.
if have tailscale; then
  SSH_TARGET="$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null | sed 's/\.$//')" || true
  if [ -z "$SSH_TARGET" ]; then
    SSH_TARGET="$(tailscale ip -4 2>/dev/null | head -1)" || true
  fi
fi

# 2. Source address of the default route: what a LAN peer would use. On a cloud
#    host behind NAT it is private, hence the "substitute" note in the hint.
if [ -z "$SSH_TARGET" ]; then
  SSH_TARGET="$(ip -4 -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')" || true
  SSH_ADDR_IS_LAN=1
fi

# 3. Hostname, when there is nothing better.
[ -n "$SSH_TARGET" ] || SSH_TARGET="$(uname -n)"
SSH_TARGET="$(id -un)@$SSH_TARGET"

# Short host alias for the ~/.ssh/config block printed at the end.
SSH_HOST_ALIAS="$(uname -n)"; SSH_HOST_ALIAS="${SSH_HOST_ALIAS%%.*}"

# Set when we fell back to a LAN address, so the banner can say the tailnet
# address will replace it after `tailscale up`.
SSH_ADDR_IS_LAN="${SSH_ADDR_IS_LAN:-}"
