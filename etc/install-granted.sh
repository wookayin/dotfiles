#!/usr/bin/env bash
# vim: set expandtab ts=2 sts=2 sw=2:
set -euo pipefail

# Install the latest granted
# archive for the current OS/architecture.

OS="$(uname -s)"
ARCH="$(uname -m)"
TMPDIR="$(mktemp -d /tmp/granted.XXXXXX)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Installing granted for ${OS}/${ARCH} ..."

BASE_URL="${BASE_URL:-https://releases.commonfate.io/granted/v0.36.2}"

case "$OS" in
  Darwin)
    case "$ARCH" in
      arm64|aarch64) DOWNLOAD="${BASE_URL}/granted_0.36.2_darwin_arm64.tar.gz" ;;
      x86_64|amd64) DOWNLOAD="${BASE_URL}/granted_0.36.2_darwin_x86_64.tar.gz" ;;
      *) echo "granted: unsupported macOS architecture ($ARCH), skipping."; exit 0 ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64|amd64) DOWNLOAD="${BASE_URL}/granted_0.36.2_linux_x86_64.tar.gz" ;;
      arm64|aarch64) DOWNLOAD="${BASE_URL}/granted_0.36.2_linux_arm64.tar.gz" ;;
      *) echo "granted: no prebuilt binary for Linux ${ARCH}, skipping."; exit 0 ;;
    esac
    ;;
  *)
    echo "granted: unsupported OS (${OS}), skipping."
    exit 0
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "granted: curl is required to download binaries." >&2
  exit 1
fi

echo "Downloading from: ${DOWNLOAD}"
curl -fL "${DOWNLOAD}" -o "${TMPDIR}/granted.tar.gz"

tar -xvzf "${TMPDIR}/granted.tar.gz" -C "${TMPDIR}"
if [[ ! -f "${TMPDIR}/granted" ]]; then
  echo "granted: extracted archive did not contain the granted binary." >&2
  exit 1
fi

DEST_SYSTEM_DIR="/usr/local/bin"
DEST_USER_DIR="${HOME}/.local/bin"
mkdir -p "${DEST_USER_DIR}"

BINARIES=(granted)
if [[ -f "${TMPDIR}/assume" ]]; then
  BINARIES+=(assume)
fi
if [[ -f "${TMPDIR}/granted-credential-process" ]]; then
  BINARIES+=(granted-credential-process)
fi

install_binaries() {
  local dest_dir="$1"
  for bin in "${BINARIES[@]}"; do
    install -m 755 "${TMPDIR}/${bin}" "${dest_dir}/${bin}"
  done
}

installed_dir=""
if [[ -w "${DEST_SYSTEM_DIR}" ]]; then
  install_binaries "${DEST_SYSTEM_DIR}"
  installed_dir="${DEST_SYSTEM_DIR}"
elif command -v sudo >/dev/null 2>&1; then
  sudo_failed=""
  for bin in "${BINARIES[@]}"; do
    if ! sudo install -m 755 "${TMPDIR}/${bin}" "${DEST_SYSTEM_DIR}/${bin}"; then
      sudo_failed="true"
      break
    fi
  done
  if [[ -z "${sudo_failed}" ]]; then
    installed_dir="${DEST_SYSTEM_DIR}"
  else
    echo "granted: sudo install to /usr/local/bin failed; falling back to user install."
  fi
else
  echo "granted: no permission to write to /usr/local/bin; installing to ${DEST_USER_DIR}"
fi

if [[ -z "${installed_dir}" ]]; then
  install_binaries "${DEST_USER_DIR}"
  installed_dir="${DEST_USER_DIR}"
  echo "granted installed to user bin; ensure ${HOME}/.local/bin is in PATH."
fi

echo "granted installed to: ${installed_dir}"
