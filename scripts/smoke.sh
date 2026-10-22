#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
server=${CARP_SESSION_CBOR_BIN:-"$repo_root/out/carp-session-cbor"}
core=${CARP_CORE_DIR:-"$repo_root/../Carp/core"}

if [ ! -x "$server" ]; then
  echo "missing host: $server (run scripts/build.sh)" >&2
  exit 1
fi

# Framed canonical CBOR request: [2, "smoke", "ping", []]. The host first
# sends its ready frame and then the response. EOF ends the host cleanly.
actual=$(
  printf '\000\000\000\016\204\002\145smoke\144ping\200' |
    env CARP_DIR="$core" "$server" |
    od -An -tx1 |
    tr -d ' \n'
)
expected='0000000a8402657265616479f5020000000a840265736d6f6b65f5f6'

if [ "$actual" != "$expected" ]; then
  echo "smoke mismatch" >&2
  echo "expected: $expected" >&2
  echo "actual:   $actual" >&2
  exit 1
fi

echo "carp-session-cbor smoke: OK"
