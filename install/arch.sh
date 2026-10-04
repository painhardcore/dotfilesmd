# Sourced by bootstrap.sh -- uses its log/have/notice/$SUDO helpers.
# System-level packages for Arch Linux and derivatives such as Omarchy.
# Language runtimes and CLI tools come from mise instead; see mise.toml.

packages="ca-certificates curl wget git make base-devel gnupg rsync openssh docker docker-compose tailscale"
missing=""
for package in $packages; do
  if ! pacman -Qq "$package" >/dev/null 2>&1; then
    missing="$missing $package"
  fi
done

if [ -n "$missing" ]; then
  log "installing system packages with pacman"
  # Intentional word splitting: missing contains package names collected above.
  # shellcheck disable=SC2086
  $SUDO pacman -S --needed --noconfirm $missing
fi

if ! systemctl is-enabled --quiet docker.service || ! systemctl is-active --quiet docker.service; then
  log "enabling Docker"
  $SUDO systemctl enable --now docker.service
fi

me="$(id -un)"
if [ -n "$SUDO" ] && ! id -nG "$me" | tr ' ' '\n' | grep -qx docker; then
  log "adding $me to the 'docker' group"
  $SUDO usermod -aG docker "$me"
  notice "Log out and back in for 'docker' group membership to take effect."
fi

# Joining the tailnet requires a separate interactive login.
if ! systemctl is-enabled --quiet tailscaled.service || ! systemctl is-active --quiet tailscaled.service; then
  log "enabling tailscaled"
  $SUDO systemctl enable --now tailscaled.service
fi

if ! tailscale ip -4 >/dev/null 2>&1; then
  notice "Join your tailnet with 'sudo tailscale up', then rerun 'make update'."
fi
