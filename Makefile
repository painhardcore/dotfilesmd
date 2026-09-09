.PHONY: update pull private check

# Apply the working tree to this machine. Works with local edits, and is the
# same idempotent script a fresh machine runs.
update:
	./bootstrap.sh

# Sync a change made on another machine, then apply it.
pull:
	git pull --ff-only
	./bootstrap.sh

# Clone the private infra repo, join the tailnet, commit this machine's public
# key, and install chosen keys into authorized_keys. Needs `gh auth login` first.
#   make private KEYS=macbookm1
private:
	KEYS="$(KEYS)" ./bootstrap.sh --private

# Syntax-check every script. shellcheck is used when installed.
check:
	bash -n bootstrap.sh
	@for f in install/*.sh; do bash -n "$$f" && echo "ok $$f"; done
	sh -n shell/init.sh && echo "ok shell/init.sh"
	@command -v shellcheck >/dev/null && shellcheck bootstrap.sh install/*.sh shell/init.sh \
		|| echo "shellcheck not installed, skipped"
