#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
compiler=${CARP_COMPILER:-"$repo_root/../metacarp/out/carp-compiler"}
core=${CARP_CORE_DIR:-"$repo_root/../Carp/core"}
output=${CARP_SESSION_CBOR_BIN:-"$repo_root/out/carp-session-cbor"}
entry=${CARP_SESSION_CBOR_ENTRY:-"$repo_root/main.carp"}

if [ ! -x "$compiler" ]; then
  echo "missing Meta-Carp compiler: $compiler (set CARP_COMPILER)" >&2
  exit 1
fi
if [ ! -f "$core/Core.carp" ]; then
  echo "missing Carp Core: $core (set CARP_CORE_DIR)" >&2
  exit 1
fi

mkdir -p "$(dirname -- "$output")"
next="$output.next"
cd "$(dirname -- "$entry")"
"$compiler" -b --optimize -c "$core" -o "$next" "$(basename -- "$entry")"
# Rename rather than overwrite: a running host may still have the old
# executable mapped.
mv "$next" "$output"
echo "installed $output"
