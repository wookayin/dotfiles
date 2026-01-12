#!/usr/bin/env bash
# vim: set expandtab ts=2 sts=2 sw=2:
set -euo pipefail

# Install the latest summon
# archive for the current OS/architecture.

OS="$(uname -s)"
ARCH="$(uname -m)"
TMPDIR="$(mktemp -d /tmp/summon.XXXXXX)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Installing summon for ${OS}/${ARCH} ..."

get_latest_version() {
  local LATEST_VERSION_URL="https://api.github.com/repos/cyberark/summon/releases/latest"
  local latest_payload

  if [[ $(command -v wget) ]]; then
    latest_payload=$(wget -q -O - "$LATEST_VERSION_URL")
  elif [[ $(command -v curl) ]]; then
    latest_payload=$(curl --fail -sSL "$LATEST_VERSION_URL")
  else
    error "Could not find wget or curl"
  fi

  echo "$latest_payload" | # Get latest release from GitHub api
    grep '"tag_name":' | # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' # Pluck JSON value
}

LATEST_VERSION=$(get_latest_version)
BASE_URL="${BASE_URL:-https://github.com/cyberark/summon/releases/download/${LATEST_VERSION}}"

case "$OS" in
  Darwin)
    case "$ARCH" in
      arm64|aarch64) DOWNLOAD="${BASE_URL}/summon-darwin-amd64.tar.gz" ;;
      x86_64|amd64) DOWNLOAD="${BASE_URL}/summon-darwin-amd64.tar.gz" ;;
      *) echo "summon: unsupported macOS architecture ($ARCH), skipping."; exit 0 ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64|amd64) DOWNLOAD="${BASE_URL}/summon-linux-amd64.tar.gz" ;;
      arm64|aarch64) DOWNLOAD="${BASE_URL}/summon-linux-arm64.tar.gz" ;;
      *) echo "summon: no prebuilt binary for Linux ${ARCH}, skipping."; exit 0 ;;
    esac
    ;;
  *)
    echo "summon: unsupported OS (${OS}), skipping."
    exit 0
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "summon: curl is required to download binaries." >&2
  exit 1
fi

echo "Downloading from: ${DOWNLOAD}"
curl -fL "${DOWNLOAD}" -o "${TMPDIR}/summon.tar.gz"

tar -xvzf "${TMPDIR}/summon.tar.gz" -C "${TMPDIR}"
if [[ ! -f "${TMPDIR}/summon" ]]; then
  echo "summon: extracted archive did not contain the summon binary." >&2
  exit 1
fi

DEST_SYSTEM_DIR="/usr/local/bin"
DEST_USER_DIR="${HOME}/.local/bin"
mkdir -p "${DEST_USER_DIR}"

BINARIES=(summon)
if [[ -f "${TMPDIR}/summon" ]]; then
  BINARIES+=(summon)
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
    echo "summon: sudo install to /usr/local/bin failed; falling back to user install."
  fi
else
  echo "summon: no permission to write to /usr/local/bin; installing to ${DEST_USER_DIR}"
fi

if [[ -z "${installed_dir}" ]]; then
  install_binaries "${DEST_USER_DIR}"
  installed_dir="${DEST_USER_DIR}"
  echo "summon installed to user bin; ensure ${HOME}/.local/bin is in PATH."
fi

echo "summon installed to: ${installed_dir}"
