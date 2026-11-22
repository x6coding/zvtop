#!/bin/sh
# Install Go (the version required by go.mod) if it is missing or too old.
# Detects OS/arch and installs the official tarball to /usr/local/go.
set -eu

want=$(awk '/^go /{print $2; exit}' go.mod)

if command -v go >/dev/null 2>&1; then
	have=$(go env GOVERSION | sed 's/^go//; s/[^0-9.].*//')
	if [ "$(printf '%s\n%s\n' "$want" "$have" | sort -V | head -n1)" = "$want" ]; then
		echo "go $have already installed (need >= $want)"
		exit 0
	fi
	echo "go $have is older than required $want, upgrading"
fi

case "$(uname -s)" in
	Linux)  os=linux ;;
	Darwin) os=darwin ;;
	*) echo "unsupported OS $(uname -s); install Go $want from https://go.dev/dl/" >&2; exit 1 ;;
esac
case "$(uname -m)" in
	x86_64|amd64)  arch=amd64 ;;
	aarch64|arm64) arch=arm64 ;;
	armv6l|armv7l) arch=armv6l ;;
	*) echo "unsupported arch $(uname -m)" >&2; exit 1 ;;
esac

tarball="go${want}.${os}-${arch}.tar.gz"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "downloading $tarball"
curl -fsSL "https://go.dev/dl/$tarball" -o "$tmp/$tarball"

sudo=""
[ "$(id -u)" -ne 0 ] && sudo="sudo"
$sudo rm -rf /usr/local/go
$sudo tar -C /usr/local -xzf "$tmp/$tarball"

echo "installed $(/usr/local/go/bin/go version)"

case ":$PATH:" in
	*:/usr/local/go/bin:*) exit 0 ;;
esac

case "$(basename "${SHELL:-sh}")" in
	zsh)  rc="$HOME/.zshrc";    line='export PATH="$PATH:/usr/local/go/bin"' ;;
	bash) rc="$HOME/.bashrc";   line='export PATH="$PATH:/usr/local/go/bin"'
	      [ "$os" = darwin ] && rc="$HOME/.bash_profile" ;;
	fish) rc="$HOME/.config/fish/config.fish"; line='fish_add_path /usr/local/go/bin' ;;
	*)    rc="$HOME/.profile";  line='export PATH="$PATH:/usr/local/go/bin"' ;;
esac

echo "/usr/local/go/bin is not in your PATH."
if [ -t 0 ]; then
	printf 'Add it to %s? [y/N] ' "$rc"
	read -r answer || answer=n
	case "$answer" in
		y|Y|yes|YES)
			mkdir -p "$(dirname "$rc")"
			printf '\n# Go\n%s\n' "$line" >> "$rc"
			echo "added to $rc; restart your shell or run: source $rc"
			exit 0 ;;
	esac
fi
echo "to add it manually, put this in $rc:"
echo "  $line"
