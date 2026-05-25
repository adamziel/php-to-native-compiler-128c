# Native Runtime ABI

Current ABI status: bootstrap only.

Existing exported helpers:

- `phpc_echo(ptr, len)`

Required next ABI families:

- PHP binary strings.
- Ordered arrays with int/string keys.
- References and COW cells.
- Function call frames.
- Object/class metadata.
- Request/SAPI state.
- Streams, filesystem, headers, sessions.
- Diagnostics and termination.

