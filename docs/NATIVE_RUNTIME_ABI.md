# Native Runtime ABI

Current ABI status: first runtime-owned value handle slice plus request header storage.

Existing exported helpers:

- `phpc_echo(ptr, len)`
- `phpc_value_null() -> handle`
- `phpc_integer_new(value) -> handle`
- `phpc_boolean_new(value) -> handle`
- `phpc_array_new() -> handle`
- `phpc_binary_string_new(ptr, len) -> handle`
- `phpc_value_kind(handle) -> kind`
- `phpc_value_clone(handle) -> handle`
- `phpc_binary_string_len(handle) -> len`
- `phpc_binary_string_data(handle, out_len) -> ptr`
- `phpc_integer_value(handle, out_value) -> status`
- `phpc_boolean_value(handle, out_value) -> status`
- `phpc_array_count(handle) -> len`
- `phpc_array_append_value(array_handle, value_handle) -> status`
- `phpc_array_value_at(array_handle, index) -> handle`
- `phpc_value_free(handle) -> status`
- `phpc_request_new() -> request`
- `phpc_request_free(request)`
- `phpc_request_add_header(request, ptr, len, replace) -> header_result`
- `phpc_request_header_count(request) -> count`
- `phpc_request_header_len(request, index) -> len`
- `phpc_request_header_ptr(request, index) -> ptr`
- `phpc_request_headers_sent(request) -> bool`
- `phpc_request_mark_headers_sent(request)`

## Runtime Constants

Value kinds:

- `PHPC_VALUE_KIND_INVALID = -1`
- `PHPC_VALUE_KIND_NULL = 0`
- `PHPC_VALUE_KIND_BINARY_STRING = 1`
- `PHPC_VALUE_KIND_INTEGER = 2`
- `PHPC_VALUE_KIND_BOOLEAN = 3`
- `PHPC_VALUE_KIND_ARRAY = 4`

Status codes:

- `PHPC_STATUS_OK = 0`
- `PHPC_STATUS_INVALID_HANDLE = -1`
- `PHPC_STATUS_INVALID_ARGUMENT = -2`

Header result codes:

- `PhpcHeaderResult::Ok = 0`
- `PhpcHeaderResult::NullRequest = 1`
- `PhpcHeaderResult::NullHeader = 2`
- `PhpcHeaderResult::Empty = 3`
- `PhpcHeaderResult::ContainsLineBreak = 4`
- `PhpcHeaderResult::HeadersAlreadySent = 5`

## Value Handle Ownership

- `0` is an invalid handle and is never returned for a successful allocation. Test: `invalid_and_double_free_are_reported`.
- Successful constructors return runtime-owned opaque handles. Test: `null_handle_is_runtime_owned_until_free`.
- Callers must release owned handles with `phpc_value_free`. Test: `null_handle_is_runtime_owned_until_free`.
- `phpc_value_free` returns `0` for a live handle and `-1` for invalid, unknown, or already-freed handles. Test: `invalid_and_double_free_are_reported`.
- `phpc_value_kind` returns `-1` for invalid handles, `0` for null, `1` for binary strings, `2` for integers, and `3` for booleans. Tests: `invalid_and_double_free_are_reported`, `null_handle_is_runtime_owned_until_free`, `binary_string_handle_owns_a_byte_copy`, `integer_handle_is_runtime_owned_until_free`, `boolean_handle_is_runtime_owned_until_free`.
- `phpc_value_clone` returns a new owned handle for a live value and invalid handle `0` for invalid, unknown, or already-freed handles. Tests: `clone_rejects_invalid_handles`, `cloned_null_handle_has_independent_ownership`, `cloned_integer_handle_has_independent_ownership`, `cloned_boolean_handle_has_independent_ownership`.
- Cloned binary-string handles own independent runtime storage and remain valid after the source handle is freed. Test: `cloned_binary_string_owns_independent_bytes`.
- Binary string construction copies bytes into runtime storage. Embedded NUL bytes are preserved. Test: `binary_string_handle_owns_a_byte_copy`.
- `phpc_binary_string_new(NULL, nonzero_len)` fails and returns invalid handle `0`. Test: `binary_string_rejects_null_pointer_with_nonzero_len`.
- `phpc_binary_string_data` returns a borrowed pointer valid until the handle is freed or runtime mutation invalidates the storage. Test: `binary_string_data_reports_invalid_handles`.
- Integer construction stores the exact signed 64-bit value in runtime-owned storage. Test: `integer_handle_is_runtime_owned_until_free`.
- `phpc_integer_value` writes the stored integer to `out_value`, returns `0` for integer handles, returns `-1` and writes `0` for invalid or non-integer handles, and returns `-2` for a null output pointer. Tests: `integer_handle_is_runtime_owned_until_free`, `integer_value_reports_invalid_handles`, `integer_value_rejects_null_out_pointer`.
- Cloned integer handles have independent ownership and remain valid after the source handle is freed. Test: `cloned_integer_handle_has_independent_ownership`.
- Boolean construction stores C-style truthiness in runtime-owned storage: `0` becomes false and any nonzero value becomes true. Test: `boolean_handle_is_runtime_owned_until_free`.
- `phpc_boolean_value` writes normalized `0` or `1` to `out_value`, returns `0` for boolean handles, returns `-1` and writes `0` for invalid or non-boolean handles, and returns `-2` for a null output pointer. Tests: `boolean_handle_is_runtime_owned_until_free`, `boolean_value_reports_invalid_handles`, `boolean_value_rejects_null_out_pointer`.
- Cloned boolean handles have independent ownership and remain valid after the source handle is freed. Test: `cloned_boolean_handle_has_independent_ownership`.
- `phpc_array_new` creates an empty ordered array handle. Test: `array_handle_is_runtime_owned_until_free`.
- `phpc_array_count` returns the number of appended values for an array handle and `0` for invalid or non-array handles. Tests: `array_handle_is_runtime_owned_until_free`, `array_helpers_report_invalid_handles`.
- `phpc_array_append_value` clones a live value into array-owned storage and returns `0`; it returns `-1` for invalid, non-array, or invalid value handles. Test: `array_append_clones_value_into_array_storage`, `array_helpers_report_invalid_handles`.
- `phpc_array_value_at` returns a new owned handle cloned from the array slot; it returns invalid handle `0` for invalid arrays, non-array handles, or out-of-range indexes. Test: `array_value_at_returns_new_owned_handle`, `array_helpers_report_invalid_handles`.
- Freeing an array handle releases its array-owned values without invalidating handles that were independently returned by `phpc_array_value_at`. Test: `array_value_at_returns_new_owned_handle`.

## Request/Header State

`phpc_request_new` allocates runtime-owned request state for linked native execution. The first request family stores response header bytes:

- Header bytes are copied into the request.
- Insertion order is preserved.
- `replace=true` removes previous headers with the same case-insensitive name.
- `replace=false` preserves duplicate names such as repeated `Set-Cookie`.
- Empty headers and headers containing CR or LF are rejected.
- Headers cannot be mutated after `phpc_request_mark_headers_sent`.

`phpc_request_header_ptr` returns a pointer owned by the request. Callers must copy from it before freeing the request and must not mutate or free it.

## Runtime ABI Test Classification

- `null_handle_is_runtime_owned_until_free`: value-handle ownership lifecycle.
- `invalid_and_double_free_are_reported`: invalid-handle and double-free status behavior.
- `binary_string_handle_owns_a_byte_copy`: binary-string ownership and byte preservation.
- `binary_string_rejects_null_pointer_with_nonzero_len`: invalid binary-string constructor arguments.
- `binary_string_data_reports_invalid_handles`: invalid binary-string data access.
- `integer_handle_is_runtime_owned_until_free`: integer value-handle ownership lifecycle and exact signed value storage.
- `integer_value_reports_invalid_handles`: invalid and non-integer handles cannot be read as integers.
- `integer_value_rejects_null_out_pointer`: integer reads reject null output pointers without freeing the handle.
- `boolean_handle_is_runtime_owned_until_free`: boolean value-handle ownership lifecycle and normalized truthiness reads.
- `boolean_value_reports_invalid_handles`: invalid and non-boolean handles cannot be read as booleans.
- `boolean_value_rejects_null_out_pointer`: boolean reads reject null output pointers without freeing the handle.
- `clone_rejects_invalid_handles`: invalid and freed handles cannot be cloned.
- `cloned_null_handle_has_independent_ownership`: cloned null handles have separate ownership lifetimes.
- `cloned_binary_string_owns_independent_bytes`: cloned binary strings remain valid after freeing the source handle.
- `cloned_integer_handle_has_independent_ownership`: cloned integer handles retain their value after freeing the source handle.
- `cloned_boolean_handle_has_independent_ownership`: cloned boolean handles retain normalized truthiness after freeing the source handle.
- `array_handle_is_runtime_owned_until_free`: array value-handle ownership lifecycle.
- `array_append_clones_value_into_array_storage`: array append clones values into array-owned storage.
- `array_value_at_returns_new_owned_handle`: array reads return independent owned handles.
- `array_helpers_report_invalid_handles`: invalid, non-array, and out-of-range array operations are reported explicitly.
- `request_headers_append_in_order`: request header storage preserves insertion order.
- `request_headers_replace_by_case_insensitive_name`: replacement removes existing headers by case-insensitive name.
- `request_headers_can_keep_duplicate_names`: duplicate header names are preserved when replacement is disabled.
- `request_headers_reject_empty_and_line_breaks`: empty headers and CR/LF injection attempts are rejected.
- `request_headers_reject_mutation_after_sent`: headers cannot be mutated after they are marked sent.
- `c_abi_exposes_request_header_storage`: request header storage is reachable through the C ABI.
- `c_abi_reports_request_header_errors`: request header C ABI reports null and state errors explicitly.

Required next ABI families:

- Additional PHP scalar types and conversions.
- Ordered arrays with int/string keys, keyed writes, append-key behavior, isset/empty, COW, and reference slots.
- References and COW cells.
- Function call frames.
- Object/class metadata.
- Request/SAPI state.
- Streams, filesystem, headers, sessions.
- Diagnostics and termination.
