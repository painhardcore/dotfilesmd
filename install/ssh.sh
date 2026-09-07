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

# Best-effort address for the "log in from elsewhere" hint printed at the end.
# The source address of the default route is the one a LAN peer would use; on a
# cloud host behind NAT it is private, hence the "substitute" note in the hint.
# `|| true`: under `set -o pipefail` a missing `ip` (macOS) fails the pipeline
# and would abort the whole run.
SSH_TARGET="$(ip -4 -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')" || true
[ -n "$SSH_TARGET" ] || SSH_TARGET="$(uname -n)"
SSH_TARGET="$(id -un)@$SSH_TARGET"

# Short host alias for the ~/.ssh/config block printed at the end.
SSH_HOST_ALIAS="$(uname -n)"; SSH_HOST_ALIAS="${SSH_HOST_ALIAS%%.*}"
