# Native Runtime ABI

Current ABI status: first runtime-owned value handle slice.

Existing exported helpers:

- `phpc_echo(ptr, len)`
- `phpc_value_null() -> handle`
- `phpc_binary_string_new(ptr, len) -> handle`
- `phpc_value_kind(handle) -> kind`
- `phpc_binary_string_len(handle) -> len`
- `phpc_binary_string_data(handle, out_len) -> ptr`
- `phpc_value_free(handle) -> status`

## Runtime Constants

Value kinds:

- `PHPC_VALUE_KIND_INVALID = -1`
- `PHPC_VALUE_KIND_NULL = 0`
- `PHPC_VALUE_KIND_BINARY_STRING = 1`

Status codes:

- `PHPC_STATUS_OK = 0`
- `PHPC_STATUS_INVALID_HANDLE = -1`
- `PHPC_STATUS_INVALID_ARGUMENT = -2`

## Value Handle Ownership

- `0` is an invalid handle and is never returned for a successful allocation. Test: `invalid_and_double_free_are_reported`.
- Successful constructors return runtime-owned opaque handles. Test: `null_handle_is_runtime_owned_until_free`.
- Callers must release owned handles with `phpc_value_free`. Test: `null_handle_is_runtime_owned_until_free`.
- `phpc_value_free` returns `0` for a live handle and `-1` for invalid, unknown, or already-freed handles. Test: `invalid_and_double_free_are_reported`.
- `phpc_value_kind` returns `-1` for invalid handles, `0` for null, and `1` for binary strings. Tests: `invalid_and_double_free_are_reported`, `null_handle_is_runtime_owned_until_free`, `binary_string_handle_owns_a_byte_copy`.
- Binary string construction copies bytes into runtime storage. Embedded NUL bytes are preserved. Test: `binary_string_handle_owns_a_byte_copy`.
- `phpc_binary_string_new(NULL, nonzero_len)` fails and returns invalid handle `0`. Test: `binary_string_rejects_null_pointer_with_nonzero_len`.
- `phpc_binary_string_data` returns a borrowed pointer valid until the handle is freed or runtime mutation invalidates the storage. Test: `binary_string_data_reports_invalid_handles`.

Required next ABI families:

- Additional PHP scalar types and conversions.
- Ordered arrays with int/string keys.
- References and COW cells.
- Function call frames.
- Object/class metadata.
- Request/SAPI state.
- Streams, filesystem, headers, sessions.
- Diagnostics and termination.
