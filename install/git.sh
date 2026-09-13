# Sourced by bootstrap.sh -- uses its log helper.
# Sets the git identity used for every commit made from this machine. Recent
# git versions refuse to commit at all with no identity configured, so a fresh
# machine needs this before its first commit, not just before its first push.

GIT_NAME="${GIT_NAME:-Andrei Iurchenkov}"
GIT_EMAIL="${GIT_EMAIL:-andrei@iurchenkov.com}"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
log "git identity set to $GIT_NAME <$GIT_EMAIL>"
