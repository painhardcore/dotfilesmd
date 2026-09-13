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

# ssh only auto-offers its default identity filenames (id_rsa, id_ed25519, ...)
# and this key deliberately is not one of them, so without an explicit
# IdentityFile neither `git clone git@github.com:...` nor `ssh` to hosts that
# trust infra/keys works, even once the key is registered.
# IdentitiesOnly is scoped to github.com: it keeps ssh from offering every other
# key first, which GitHub counts against its authentication attempt limit, but
# elsewhere it would also block keys from a forwarded agent.
write_managed_block "$HOME/.ssh/config" "Host *
  IdentityFile $SSH_KEY

Host github.com
  IdentitiesOnly yes"
