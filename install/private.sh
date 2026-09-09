# Sourced by bootstrap.sh with --private. Uses its log/have/die/notice/$SUDO
# helpers and write_managed_block.
#
# This is the only phase that needs an identity. The chicken-and-egg -- reaching
# a private repo needs a credential, and the tailnet credential lives in that
# repo -- is broken by `gh auth login`, whose OAuth device flow needs no SSH key
# and stores its token in the system keyring. That one interactive step is
# unavoidable on a fresh machine; everything after it is automated.

INFRA_REPO="${INFRA_REPO:-painhardcore/infra}"
INFRA_DIR="${INFRA_DIR:-$HOME/infra}"

have gh || die "gh is not installed; run ./bootstrap.sh first"
if ! gh auth status >/dev/null 2>&1; then
  die "not authenticated to GitHub. Run 'gh auth login' (approve the code on
  your phone), then rerun 'make private'."
fi

# Make plain `git push` over HTTPS use the gh token. Idempotent.
gh auth setup-git

if [ -d "$INFRA_DIR/.git" ]; then
  log "updating $INFRA_DIR"
  # --ff-only: a divergence here is a human decision, not something to merge
  # automatically on a machine you may not be sitting at.
  git -C "$INFRA_DIR" pull --ff-only \
    || die "$INFRA_DIR has diverged from origin; resolve it there by hand"
else
  log "cloning $INFRA_REPO to $INFRA_DIR"
  gh repo clone "$INFRA_REPO" "$INFRA_DIR"
fi

# Join the tailnet with the tag-scoped key the repo tracks for exactly this.
# `file:` rather than "$(cat ...)": a command-line argument is visible in `ps`
# to every user on the box, a file read by tailscale is not.
# --accept-dns=false keeps tailscaled out of /etc/resolv.conf, which Docker and
# Caddy depend on; see infra's tailscale/README.md.
TS_TAG="${TS_TAG:-tag:build}"
# The filename is the tag: tag:build -> tag-build.key
TS_AUTHKEY="$INFRA_DIR/tailscale/authkeys/tag-${TS_TAG#tag:}.key"
if ! have tailscale; then
  warn "tailscale is not installed; skipping the tailnet join"
elif tailscale status >/dev/null 2>&1; then
  log "already on the tailnet, skipping"
elif [ ! -f "$TS_AUTHKEY" ]; then
  warn "no auth key at $TS_AUTHKEY; join manually with 'sudo tailscale up'"
else
  log "joining the tailnet as $TS_TAG"
  $SUDO tailscale up --auth-key "file:$TS_AUTHKEY" \
    --advertise-tags="$TS_TAG" --accept-dns=false
fi

# Commit this machine's public key. Committing stages access; it grants nothing
# until `make keys HOST=...` is run deliberately from another machine.
MACHINE_NAME="${MACHINE_NAME:-$(uname -n)}"; MACHINE_NAME="${MACHINE_NAME%%.*}"
key_dest="$INFRA_DIR/keys/$MACHINE_NAME.pub"

# Cheap validity check that needs no venv, unlike infra's own `make check`.
ssh-keygen -l -f "$SSH_KEY.pub" >/dev/null 2>&1 \
  || die "$SSH_KEY.pub is not a valid public key"

mkdir -p "$INFRA_DIR/keys"
cp "$SSH_KEY.pub" "$key_dest"
if [ -n "$(git -C "$INFRA_DIR" status --porcelain -- "keys/$MACHINE_NAME.pub")" ]; then
  log "committing keys/$MACHINE_NAME.pub"
  git -C "$INFRA_DIR" add "keys/$MACHINE_NAME.pub"
  git -C "$INFRA_DIR" commit -q -m "Add SSH public key for $MACHINE_NAME"
  git -C "$INFRA_DIR" push -q
  notice "keys/$MACHINE_NAME.pub is committed but grants nothing yet."
  notice "Run 'make keys HOST=...' in $INFRA_REPO when you mean to grant access."
else
  log "keys/$MACHINE_NAME.pub already up to date"
fi

# Register the key on the GitHub account so this machine can push.
#
# Reading and writing account keys needs the admin:public_key scope, which a
# default `gh auth login` does not request; without it both list and add fail.
# Exit status tells us, so ask for the scope rather than failing at the add.
if ! key_list="$(gh ssh-key list 2>/dev/null)"; then
  die "gh cannot manage account SSH keys: the admin:public_key scope is missing.
  Run: gh auth refresh -h github.com -s admin:public_key
  Then rerun 'make private'."
fi

# Compare the base64 key body, not a fingerprint: `gh ssh-key list` prints the
# key body in its KEY column and no fingerprint at all, so matching on
# `ssh-keygen -l` output would never hit and would re-add the key every run --
# which GitHub rejects as a duplicate, aborting under `set -e`.
key_body="$(awk '{print $2}' "$SSH_KEY.pub")"
if printf '%s\n' "$key_list" | grep -qF "$key_body"; then
  log "key already registered with GitHub"
else
  log "registering the key with GitHub"
  gh ssh-key add "$SSH_KEY.pub" --title "$MACHINE_NAME"
fi

# Install the chosen public keys into authorized_keys. KEYS is a comma-separated
# list of names in the repo's keys/ directory, without the .pub suffix.
available=""
for pub in "$INFRA_DIR"/keys/*.pub; do
  [ -f "$pub" ] || continue          # no matches: the glob stayed literal
  name="$(basename "$pub" .pub)"
  available="$available$name "
done
if [ -z "${KEYS:-}" ]; then
  notice "No KEYS= given, so authorized_keys was not touched."
  notice "Available keys: ${available:-none}. Rerun as: make private KEYS=name1,name2"
else
  body=""
  # A comma-separated list, split without touching IFS globally.
  for name in $(printf '%s' "$KEYS" | tr ',' ' '); do
    pub="$INFRA_DIR/keys/$name.pub"
    [ -f "$pub" ] || die "no key named '$name' in $INFRA_DIR/keys. Available: ${available:-none}"
    body="$body$(cat "$pub")
"
  done
  mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  write_managed_block "$HOME/.ssh/authorized_keys" "$(printf '%s' "$body")"
  log "installed authorized_keys for: $KEYS"
fi
