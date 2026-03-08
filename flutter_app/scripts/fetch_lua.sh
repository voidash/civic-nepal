#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
mkdir -p packages/lua_engine/src/lua54
echo "Downloading Lua 5.4.6..."
curl -L https://www.lua.org/ftp/lua-5.4.6.tar.gz | tar xz -C /tmp
cp /tmp/lua-5.4.6/src/*.c packages/lua_engine/src/lua54/
cp /tmp/lua-5.4.6/src/*.h packages/lua_engine/src/lua54/
# Remove files that have main() - they can't be compiled into a library
rm -f packages/lua_engine/src/lua54/lua.c packages/lua_engine/src/lua54/luac.c
echo "Lua 5.4.6 sources ready at packages/lua_engine/src/lua54/"
echo "Files: $(ls packages/lua_engine/src/lua54/*.c | wc -l | tr -d ' ') .c files"
