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
echo "add /usr/local/go/bin to your PATH if it is not already there"
