# Sourced by bootstrap.sh -- uses its log/have/notice helpers.
# System-level packages for macOS. Language runtimes and CLI tools come from
# mise instead; see mise.toml.

if ! have brew; then
  log "installing Homebrew"
  # Homebrew documents this installer as the only supported install path. It is
  # fetched to a file first rather than piped into a shell, and it prompts before
  # making changes. It also installs the Xcode Command Line Tools if missing.
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
    -o "$TMPDIR_BOOTSTRAP/brew-install.sh"
  /bin/bash "$TMPDIR_BOOTSTRAP/brew-install.sh"
  # Put the just-installed brew on PATH for the rest of this run.
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then eval "$("$candidate" shellenv)"; break; fi
  done
  have brew || die "Homebrew installed but 'brew' is not on PATH"
fi

# macOS already ships usable curl, make, rsync and ssh-keygen, so they are not
# reinstalled. git comes from brew because the Xcode CLT version lags badly.
# Only install what is missing: `brew install` on an existing formula fetches
# the API index and prints an already-installed warning on every rerun.
for pkg in git wget; do
  brew list --formula "$pkg" >/dev/null 2>&1 && continue
  log "installing $pkg with brew"
  brew install "$pkg"
done

if have docker; then
  log "docker already installed, skipping"
else
  log "installing Docker Desktop"
  brew install --cask docker
  notice "Launch Docker Desktop once to finish setup (it bundles 'docker compose')."
fi
