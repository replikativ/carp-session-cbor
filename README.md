# carp-session-cbor

A deterministic-CBOR transport for Meta-Carp's warm compiler sessions
(`carp-session`). A host process talks to one resident session over
stdin/stdout. Carpaccio uses it to compile Carp from a Clojure REPL, but it
has no JVM dependency.

## Protocol 2

Each message is a four-byte big-endian length followed by one item in the
strict CBOR subset of [carp-cbor](https://github.com/replikativ/carp-cbor).
Requests are `[2, id, operation, payload]`, responses
`[2, id, success?, payload]`. A failed response carries `[phase, message]`.
On start the host loads Core from `CARP_DIR` and sends
`[2, "ready", true, 2]`, so a client can reject a host speaking another
protocol before it sends anything.

| operation | payload | success payload |
| --- | --- | --- |
| `ping` | `[]` | `null` |
| `quit` | `[]` | `null`, then the host exits |
| `reset` | `[]` | `null` |
| `upsert` | `[source]` or `[source, source-id]` | number of invalidated definitions |
| `upsert-input` | `[source, source-id]` | the input's definitions: `{name, kind, scheme, span}` |
| `remove` | `[name]` | number of invalidated definitions |
| `remove-input` | `[source-id]` | `null` |
| `ownership` | `[name]` | `{name, scheme, actions}`, the ownership plan with caller spans |
| `emit-library` | `[source, [root ...]]` | `{format: 3, c}`, a C unit without `main` exporting only the roots |

Spans are `{source, start, end}`, half-open byte ranges in the submitted
source. `emit-library` compiles a transient cell and commits nothing; its
roots may be defined by the cell or committed earlier.

The protocol number is independent of `Session.api-version` and changes only
when a request or response shape does.

## Build

```sh
CARP_COMPILER=../metacarp/out/carp-compiler CARP_CORE_DIR=../Carp/core \
  scripts/build.sh
scripts/smoke.sh
```

`main.carp` loads `carp-session-cbor.carp`, which pins `carp-session` and
`carp-cbor` by commit and fetches them into the Carp library cache.
`CARP_SESSION_CBOR_ENTRY=dev.carp` builds against adjacent `../metacarp` and
`../carp-cbor` checkouts instead.

To embed the transport in another program, load the dependencies, then
`src/SessionCbor.carp`, and call `SessionCbor.main` or `SessionCbor.serve`.
