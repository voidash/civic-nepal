#!/usr/bin/env bash
#
# Fetch the Lua 5.4 C sources that the bundled `lua_engine` plugin compiles
# against.
#
# The Android, macOS and Windows builds all reference
# `flutter_app/packages/lua_engine/src/lua54`, but the sources are not vendored,
# so a fresh clone cannot build for any native platform — the Android build
# stops at `fatal error: 'lua.h' file not found`. Web is unaffected, which is
# why this went unnoticed.
#
# Usage:
#   scripts/fetch_lua.sh          # no-op if already present
#   scripts/fetch_lua.sh --force  # re-download
#
set -euo pipefail

LUA_VERSION="5.4.7"
LUA_SHA256="9fbf5e28ef86c69858f6d3d34eccc32e911c1a28b4120ff3e84aaa70cfbf1e30"
LUA_URL="https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${repo_root}/flutter_app/packages/lua_engine/src/lua54"

if [[ "${1:-}" == "--force" ]]; then
  rm -rf "${dest}"
fi

if [[ -f "${dest}/lua.h" ]]; then
  echo "Lua sources already present at ${dest}"
  exit 0
fi

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

echo "Downloading Lua ${LUA_VERSION}..."
curl -fsSL "${LUA_URL}" -o "${workdir}/lua.tar.gz"

echo "Verifying checksum..."
echo "${LUA_SHA256}  ${workdir}/lua.tar.gz" | sha256sum --check --status || {
  echo "ERROR: checksum mismatch for ${LUA_URL}" >&2
  echo "Expected ${LUA_SHA256}" >&2
  echo "Got      $(sha256sum "${workdir}/lua.tar.gz" | cut -d' ' -f1)" >&2
  exit 1
}

tar -xzf "${workdir}/lua.tar.gz" -C "${workdir}"

mkdir -p "${dest}"
# Only the library sources are wanted. lua.c and luac.c define main() and are
# filtered back out by every platform's build file, so they are not copied at
# all.
find "${workdir}/lua-${LUA_VERSION}/src" -maxdepth 1 \
  \( -name '*.c' -o -name '*.h' \) \
  ! -name 'lua.c' ! -name 'luac.c' \
  -exec cp {} "${dest}/" \;

echo "Installed $(find "${dest}" -name '*.c' | wc -l) C files and $(find "${dest}" -name '*.h' | wc -l) headers into ${dest}"
