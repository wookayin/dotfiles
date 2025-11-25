#!/usr/bin/env bash
# vim: set expandtab ts=2 sts=2 sw=2:
set -euo pipefail

# Install the latest pman binary from GitHub releases, picking the right
# archive for the current OS/architecture.

BASE_URL="https://github.com/kojunseo/pman/releases/latest/download"
OS="$(uname -s)"
ARCH="$(uname -m)"
TMPDIR="$(mktemp -d /tmp/pman.XXXXXX)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Installing pman for ${OS}/${ARCH} ..."

case "$OS" in
  Darwin)
    case "$ARCH" in
      arm64|aarch64) DOWNLOAD="${BASE_URL}/pman_Darwin_arm64.tar.gz" ;;
      x86_64|amd64) DOWNLOAD="${BASE_URL}/pman_Darwin_x86_64.tar.gz" ;;
      *) echo "pman: unsupported macOS architecture ($ARCH), skipping."; exit 0 ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64|amd64) DOWNLOAD="${BASE_URL}/pman_Linux_x86_64.tar.gz" ;;
      *) echo "pman: no prebuilt binary for Linux ${ARCH}, skipping."; exit 0 ;;
    esac
    ;;
  *)
    echo "pman: unsupported OS (${OS}), skipping."
    exit 0
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "pman: curl is required to download binaries." >&2
  exit 1
fi

echo "Downloading from: ${DOWNLOAD}"
curl -fL "${DOWNLOAD}" -o "${TMPDIR}/pman.tar.gz"

tar -xvzf "${TMPDIR}/pman.tar.gz" -C "${TMPDIR}"
if [[ ! -f "${TMPDIR}/pman" ]]; then
  echo "pman: extracted archive did not contain the binary." >&2
  exit 1
fi

DEST_SYSTEM="/usr/local/bin/pman"
DEST_USER="${HOME}/.local/bin/pman"
mkdir -p "$(dirname "$DEST_USER")"

installed_path=""
if [[ -w "$(dirname "$DEST_SYSTEM")" ]]; then
  install -m 755 "${TMPDIR}/pman" "${DEST_SYSTEM}"
  installed_path="${DEST_SYSTEM}"
elif command -v sudo >/dev/null 2>&1; then
  if sudo install -m 755 "${TMPDIR}/pman" "${DEST_SYSTEM}"; then
    installed_path="${DEST_SYSTEM}"
  else
    echo "pman: sudo install to /usr/local/bin failed; falling back to user install."
  fi
else
  echo "pman: no permission to write to /usr/local/bin; installing to ${DEST_USER}"
fi

if [[ -z "${installed_path}" ]]; then
  install -m 755 "${TMPDIR}/pman" "${DEST_USER}"
  installed_path="${DEST_USER}"
  echo "pman installed to user bin; ensure ${HOME}/.local/bin is in PATH."
fi

echo "pman installed to: ${installed_path}"
