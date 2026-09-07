# Sourced by ~/.profile (and ~/.bashrc / ~/.zshrc when they exist), and by
# bootstrap.sh itself. Plain POSIX sh with no shell detection, so bash, zsh and
# non-interactive shells all get the same PATH.
#
# mise shims rather than `mise activate`: Ubuntu's default ~/.bashrc returns
# early for non-interactive shells, so an activate hook there would leave
# `ssh host 'go version'` broken. Shims are just a directory on PATH.
#
# Safe to source repeatedly -- every entry is added only if missing.

# Homebrew first, so the mise shims below end up ahead of it. Otherwise a
# brew-installed go or node would shadow the version declared in mise.toml.
# /opt/homebrew on Apple Silicon, /usr/local on Intel; no-op on Linux.
for _dotfilesmd_brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$_dotfilesmd_brew" ]; then
        case ":${PATH}:" in
            *":$(dirname "$_dotfilesmd_brew"):"*) ;;
            *) eval "$("$_dotfilesmd_brew" shellenv)" ;;
        esac
        break
    fi
done
unset _dotfilesmd_brew

for _dotfilesmd_dir in "$HOME/.local/bin" "$HOME/.local/share/mise/shims"; do
    case ":${PATH}:" in
        *":${_dotfilesmd_dir}:"*) ;;
        *) PATH="${_dotfilesmd_dir}:${PATH}" ;;
    esac
done
unset _dotfilesmd_dir
export PATH
