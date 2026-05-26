use std::collections::HashMap;
use std::ffi::c_char;
use std::io::{self, Write};
use std::slice;
use std::sync::{Mutex, OnceLock};

pub type PhpcValueHandle = u64;

pub const PHPC_VALUE_KIND_INVALID: i32 = -1;
pub const PHPC_VALUE_KIND_NULL: i32 = 0;
pub const PHPC_VALUE_KIND_BINARY_STRING: i32 = 1;
pub const PHPC_VALUE_KIND_INTEGER: i32 = 2;
pub const PHPC_VALUE_KIND_BOOLEAN: i32 = 3;
pub const PHPC_VALUE_KIND_ARRAY: i32 = 4;

pub const PHPC_STATUS_OK: i32 = 0;
pub const PHPC_STATUS_INVALID_HANDLE: i32 = -1;
pub const PHPC_STATUS_INVALID_ARGUMENT: i32 = -2;

const INVALID_HANDLE: PhpcValueHandle = 0;

#[derive(Debug, Clone, PartialEq, Eq)]
enum PhpValue {
    Null,
    BinaryString(Vec<u8>),
    Integer(i64),
    Boolean(bool),
    Array(Vec<PhpValue>),
}

#[derive(Debug)]
struct RuntimeState {
    next_handle: PhpcValueHandle,
    values: HashMap<PhpcValueHandle, PhpValue>,
}

impl RuntimeState {
    fn new() -> Self {
        Self {
            next_handle: 1,
            values: HashMap::new(),
        }
    }

    fn insert(&mut self, value: PhpValue) -> PhpcValueHandle {
        let handle = self.next_handle;
        self.next_handle = self
            .next_handle
            .checked_add(1)
            .expect("runtime value handle space exhausted");
        self.values.insert(handle, value);
        handle
    }

    fn clone_value(&mut self, handle: PhpcValueHandle) -> PhpcValueHandle {
        let Some(value) = self.values.get(&handle).cloned() else {
            return INVALID_HANDLE;
        };
        self.insert(value)
    }
}

fn runtime() -> &'static Mutex<RuntimeState> {
    static RUNTIME: OnceLock<Mutex<RuntimeState>> = OnceLock::new();
    RUNTIME.get_or_init(|| Mutex::new(RuntimeState::new()))
}

#[derive(Debug, Default)]
pub struct RequestState {
    headers: Vec<HeaderLine>,
    headers_sent: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HeaderLine {
    raw: Vec<u8>,
    name_end: Option<usize>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HeaderError {
    Empty,
    ContainsLineBreak,
    HeadersAlreadySent,
}

impl RequestState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_header(&mut self, header: &[u8], replace: bool) -> Result<(), HeaderError> {
        if self.headers_sent {
            return Err(HeaderError::HeadersAlreadySent);
        }
        if header.is_empty() {
            return Err(HeaderError::Empty);
        }
        if header.iter().any(|byte| matches!(byte, b'\r' | b'\n')) {
            return Err(HeaderError::ContainsLineBreak);
        }

        let header = HeaderLine::new(header.to_vec());
        if replace {
            if let Some(name) = header.name() {
                self.headers
                    .retain(|existing| !existing.name().is_some_and(|existing_name| {
                        ascii_eq_ignore_case(existing_name, name)
                    }));
            }
        }
        self.headers.push(header);
        Ok(())
    }

    pub fn header_count(&self) -> usize {
        self.headers.len()
    }

    pub fn header(&self, index: usize) -> Option<&[u8]> {
        self.headers.get(index).map(HeaderLine::raw)
    }

    pub fn headers_sent(&self) -> bool {
        self.headers_sent
    }

    pub fn mark_headers_sent(&mut self) {
        self.headers_sent = true;
    }
}

impl HeaderLine {
    fn new(raw: Vec<u8>) -> Self {
        let name_end = raw
            .iter()
            .position(|byte| *byte == b':')
            .map(|colon| trim_ascii_space_end(&raw[..colon]).len())
            .filter(|end| *end > 0);
        Self { raw, name_end }
    }

    fn raw(&self) -> &[u8] {
        &self.raw
    }

    fn name(&self) -> Option<&[u8]> {
        self.name_end.map(|end| &self.raw[..end])
    }
}

#[repr(C)]
pub struct PhpcRequestState {
    inner: RequestState,
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PhpcHeaderResult {
    Ok = 0,
    NullRequest = 1,
    NullHeader = 2,
    Empty = 3,
    ContainsLineBreak = 4,
    HeadersAlreadySent = 5,
}

#[no_mangle]
pub unsafe extern "C" fn phpc_echo(ptr: *const c_char, len: usize) {
    if ptr.is_null() {
        return;
    }
    let bytes = slice::from_raw_parts(ptr.cast::<u8>(), len);
    let _ = io::stdout().write_all(bytes);
    let _ = io::stdout().flush();
}

#[no_mangle]
pub extern "C" fn phpc_value_null() -> PhpcValueHandle {
    runtime().lock().unwrap().insert(PhpValue::Null)
}

#[no_mangle]
pub extern "C" fn phpc_integer_new(value: i64) -> PhpcValueHandle {
    runtime().lock().unwrap().insert(PhpValue::Integer(value))
}

#[no_mangle]
pub extern "C" fn phpc_boolean_new(value: i32) -> PhpcValueHandle {
    runtime()
        .lock()
        .unwrap()
        .insert(PhpValue::Boolean(value != 0))
}

#[no_mangle]
pub extern "C" fn phpc_array_new() -> PhpcValueHandle {
    runtime().lock().unwrap().insert(PhpValue::Array(Vec::new()))
}

#[no_mangle]
pub unsafe extern "C" fn phpc_binary_string_new(
    ptr: *const c_char,
    len: usize,
) -> PhpcValueHandle {
    if ptr.is_null() && len != 0 {
        return INVALID_HANDLE;
    }
    let bytes = if len == 0 {
        Vec::new()
    } else {
        slice::from_raw_parts(ptr.cast::<u8>(), len).to_vec()
    };
    runtime()
        .lock()
        .unwrap()
        .insert(PhpValue::BinaryString(bytes))
}

#[no_mangle]
pub extern "C" fn phpc_value_kind(handle: PhpcValueHandle) -> i32 {
    let runtime = runtime().lock().unwrap();
    match runtime.values.get(&handle) {
        Some(PhpValue::Null) => PHPC_VALUE_KIND_NULL,
        Some(PhpValue::BinaryString(_)) => PHPC_VALUE_KIND_BINARY_STRING,
        Some(PhpValue::Integer(_)) => PHPC_VALUE_KIND_INTEGER,
        Some(PhpValue::Boolean(_)) => PHPC_VALUE_KIND_BOOLEAN,
        Some(PhpValue::Array(_)) => PHPC_VALUE_KIND_ARRAY,
        None => PHPC_VALUE_KIND_INVALID,
    }
}

#[no_mangle]
pub extern "C" fn phpc_value_clone(handle: PhpcValueHandle) -> PhpcValueHandle {
    runtime().lock().unwrap().clone_value(handle)
}

#[no_mangle]
pub extern "C" fn phpc_binary_string_len(handle: PhpcValueHandle) -> usize {
    let runtime = runtime().lock().unwrap();
    match runtime.values.get(&handle) {
        Some(PhpValue::BinaryString(bytes)) => bytes.len(),
        _ => 0,
    }
}

#[no_mangle]
pub unsafe extern "C" fn phpc_binary_string_data(
    handle: PhpcValueHandle,
    out_len: *mut usize,
) -> *const c_char {
    let runtime = runtime().lock().unwrap();
    let Some(PhpValue::BinaryString(bytes)) = runtime.values.get(&handle) else {
        if !out_len.is_null() {
            *out_len = 0;
        }
        return std::ptr::null();
    };
    if !out_len.is_null() {
        *out_len = bytes.len();
    }
    bytes.as_ptr().cast::<c_char>()
}

#[no_mangle]
pub unsafe extern "C" fn phpc_integer_value(handle: PhpcValueHandle, out_value: *mut i64) -> i32 {
    if out_value.is_null() {
        return PHPC_STATUS_INVALID_ARGUMENT;
    }

    let runtime = runtime().lock().unwrap();
    let Some(PhpValue::Integer(value)) = runtime.values.get(&handle) else {
        *out_value = 0;
        return PHPC_STATUS_INVALID_HANDLE;
    };

    *out_value = *value;
    PHPC_STATUS_OK
}

#[no_mangle]
pub unsafe extern "C" fn phpc_boolean_value(handle: PhpcValueHandle, out_value: *mut i32) -> i32 {
    if out_value.is_null() {
        return PHPC_STATUS_INVALID_ARGUMENT;
    }

    let runtime = runtime().lock().unwrap();
    let Some(PhpValue::Boolean(value)) = runtime.values.get(&handle) else {
        *out_value = 0;
        return PHPC_STATUS_INVALID_HANDLE;
    };

    *out_value = i32::from(*value);
    PHPC_STATUS_OK
}

#[no_mangle]
pub extern "C" fn phpc_array_count(handle: PhpcValueHandle) -> usize {
    let runtime = runtime().lock().unwrap();
    match runtime.values.get(&handle) {
        Some(PhpValue::Array(values)) => values.len(),
        _ => 0,
    }
}

#[no_mangle]
pub extern "C" fn phpc_array_append_value(
    array_handle: PhpcValueHandle,
    value_handle: PhpcValueHandle,
) -> i32 {
    let mut runtime = runtime().lock().unwrap();
    let Some(value) = runtime.values.get(&value_handle).cloned() else {
        return PHPC_STATUS_INVALID_HANDLE;
    };
    let Some(PhpValue::Array(values)) = runtime.values.get_mut(&array_handle) else {
        return PHPC_STATUS_INVALID_HANDLE;
    };

    values.push(value);
    PHPC_STATUS_OK
}

#[no_mangle]
pub extern "C" fn phpc_array_value_at(
    array_handle: PhpcValueHandle,
    index: usize,
) -> PhpcValueHandle {
    let mut runtime = runtime().lock().unwrap();
    let Some(PhpValue::Array(values)) = runtime.values.get(&array_handle) else {
        return INVALID_HANDLE;
    };
    let Some(value) = values.get(index).cloned() else {
        return INVALID_HANDLE;
    };

    runtime.insert(value)
}

#[no_mangle]
pub extern "C" fn phpc_value_free(handle: PhpcValueHandle) -> i32 {
    let mut runtime = runtime().lock().unwrap();
    if runtime.values.remove(&handle).is_some() {
        PHPC_STATUS_OK
    } else {
        PHPC_STATUS_INVALID_HANDLE
    }
}

#[no_mangle]
pub extern "C" fn phpc_request_new() -> *mut PhpcRequestState {
    Box::into_raw(Box::new(PhpcRequestState {
        inner: RequestState::new(),
    }))
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_free(request: *mut PhpcRequestState) {
    if !request.is_null() {
        drop(Box::from_raw(request));
    }
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_add_header(
    request: *mut PhpcRequestState,
    header: *const c_char,
    len: usize,
    replace: bool,
) -> PhpcHeaderResult {
    let Some(request) = request.as_mut() else {
        return PhpcHeaderResult::NullRequest;
    };
    if header.is_null() {
        return PhpcHeaderResult::NullHeader;
    }
    let header = slice::from_raw_parts(header.cast::<u8>(), len);
    match request.inner.add_header(header, replace) {
        Ok(()) => PhpcHeaderResult::Ok,
        Err(HeaderError::Empty) => PhpcHeaderResult::Empty,
        Err(HeaderError::ContainsLineBreak) => PhpcHeaderResult::ContainsLineBreak,
        Err(HeaderError::HeadersAlreadySent) => PhpcHeaderResult::HeadersAlreadySent,
    }
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_header_count(request: *const PhpcRequestState) -> usize {
    request
        .as_ref()
        .map(|request| request.inner.header_count())
        .unwrap_or(0)
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_header_len(
    request: *const PhpcRequestState,
    index: usize,
) -> usize {
    request
        .as_ref()
        .and_then(|request| request.inner.header(index))
        .map(|header| header.len())
        .unwrap_or(0)
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_header_ptr(
    request: *const PhpcRequestState,
    index: usize,
) -> *const c_char {
    request
        .as_ref()
        .and_then(|request| request.inner.header(index))
        .map(|header| header.as_ptr().cast::<c_char>())
        .unwrap_or(std::ptr::null())
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_headers_sent(request: *const PhpcRequestState) -> bool {
    request
        .as_ref()
        .map(|request| request.inner.headers_sent())
        .unwrap_or(false)
}

#[no_mangle]
pub unsafe extern "C" fn phpc_request_mark_headers_sent(request: *mut PhpcRequestState) {
    if let Some(request) = request.as_mut() {
        request.inner.mark_headers_sent();
    }
}

fn trim_ascii_space_end(bytes: &[u8]) -> &[u8] {
    let end = bytes
        .iter()
        .rposition(|byte| !matches!(byte, b' ' | b'\t'))
        .map(|index| index + 1)
        .unwrap_or(0);
    &bytes[..end]
}

fn ascii_eq_ignore_case(left: &[u8], right: &[u8]) -> bool {
    left.len() == right.len()
        && left
            .iter()
            .zip(right)
            .all(|(left, right)| left.eq_ignore_ascii_case(right))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::c_char;

    #[test]
    fn null_handle_is_runtime_owned_until_free() {
        let handle = phpc_value_null();

        assert_ne!(handle, INVALID_HANDLE);
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_NULL);
        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_INVALID);
    }

    #[test]
    fn invalid_and_double_free_are_reported() {
        assert_eq!(phpc_value_kind(INVALID_HANDLE), PHPC_VALUE_KIND_INVALID);
        assert_eq!(phpc_value_free(INVALID_HANDLE), PHPC_STATUS_INVALID_HANDLE);

        let handle = phpc_value_null();
        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
        assert_eq!(phpc_value_free(handle), PHPC_STATUS_INVALID_HANDLE);
    }

    #[test]
    fn binary_string_handle_owns_a_byte_copy() {
        let mut source = b"a\0b".to_vec();
        let handle =
            unsafe { phpc_binary_string_new(source.as_ptr().cast::<c_char>(), source.len()) };
        source.fill(b'x');

        assert_ne!(handle, INVALID_HANDLE);
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_BINARY_STRING);
        assert_eq!(phpc_binary_string_len(handle), 3);

        let mut len = usize::MAX;
        let ptr = unsafe { phpc_binary_string_data(handle, &mut len) };
        assert!(!ptr.is_null());
        assert_eq!(len, 3);
        let bytes = unsafe { slice::from_raw_parts(ptr.cast::<u8>(), len) };
        assert_eq!(bytes, b"a\0b");

        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
    }

    #[test]
    fn binary_string_rejects_null_pointer_with_nonzero_len() {
        let handle = unsafe { phpc_binary_string_new(std::ptr::null(), 1) };

        assert_eq!(handle, INVALID_HANDLE);
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_INVALID);
    }

    #[test]
    fn binary_string_data_reports_invalid_handles() {
        let mut len = usize::MAX;
        let ptr = unsafe { phpc_binary_string_data(INVALID_HANDLE, &mut len) };

        assert!(ptr.is_null());
        assert_eq!(len, 0);
    }

    #[test]
    fn integer_handle_is_runtime_owned_until_free() {
        let handle = phpc_integer_new(-42);

        assert_ne!(handle, INVALID_HANDLE);
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_INTEGER);

        let mut value = 0;
        assert_eq!(
            unsafe { phpc_integer_value(handle, &mut value) },
            PHPC_STATUS_OK
        );
        assert_eq!(value, -42);

        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_INVALID);
    }

    #[test]
    fn integer_value_reports_invalid_handles() {
        let mut value = i64::MAX;

        assert_eq!(
            unsafe { phpc_integer_value(INVALID_HANDLE, &mut value) },
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(value, 0);

        let string = unsafe { phpc_binary_string_new(b"not-int".as_ptr().cast::<c_char>(), 7) };
        value = i64::MAX;
        assert_eq!(
            unsafe { phpc_integer_value(string, &mut value) },
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(value, 0);
        assert_eq!(phpc_value_free(string), PHPC_STATUS_OK);
    }

    #[test]
    fn integer_value_rejects_null_out_pointer() {
        let handle = phpc_integer_new(123);

        assert_eq!(
            unsafe { phpc_integer_value(handle, std::ptr::null_mut()) },
            PHPC_STATUS_INVALID_ARGUMENT
        );
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_INTEGER);
        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
    }

    #[test]
    fn boolean_handle_is_runtime_owned_until_free() {
        let true_handle = phpc_boolean_new(7);
        let false_handle = phpc_boolean_new(0);

        assert_ne!(true_handle, INVALID_HANDLE);
        assert_ne!(false_handle, INVALID_HANDLE);
        assert_ne!(true_handle, false_handle);
        assert_eq!(phpc_value_kind(true_handle), PHPC_VALUE_KIND_BOOLEAN);
        assert_eq!(phpc_value_kind(false_handle), PHPC_VALUE_KIND_BOOLEAN);

        let mut value = -1;
        assert_eq!(
            unsafe { phpc_boolean_value(true_handle, &mut value) },
            PHPC_STATUS_OK
        );
        assert_eq!(value, 1);

        value = -1;
        assert_eq!(
            unsafe { phpc_boolean_value(false_handle, &mut value) },
            PHPC_STATUS_OK
        );
        assert_eq!(value, 0);

        assert_eq!(phpc_value_free(true_handle), PHPC_STATUS_OK);
        assert_eq!(phpc_value_free(false_handle), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(true_handle), PHPC_VALUE_KIND_INVALID);
        assert_eq!(phpc_value_kind(false_handle), PHPC_VALUE_KIND_INVALID);
    }

    #[test]
    fn boolean_value_reports_invalid_handles() {
        let mut value = i32::MAX;

        assert_eq!(
            unsafe { phpc_boolean_value(INVALID_HANDLE, &mut value) },
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(value, 0);

        let integer = phpc_integer_new(1);
        value = i32::MAX;
        assert_eq!(
            unsafe { phpc_boolean_value(integer, &mut value) },
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(value, 0);
        assert_eq!(phpc_value_free(integer), PHPC_STATUS_OK);
    }

    #[test]
    fn boolean_value_rejects_null_out_pointer() {
        let handle = phpc_boolean_new(1);

        assert_eq!(
            unsafe { phpc_boolean_value(handle, std::ptr::null_mut()) },
            PHPC_STATUS_INVALID_ARGUMENT
        );
        assert_eq!(phpc_value_kind(handle), PHPC_VALUE_KIND_BOOLEAN);
        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
    }

    #[test]
    fn clone_rejects_invalid_handles() {
        assert_eq!(phpc_value_clone(INVALID_HANDLE), INVALID_HANDLE);

        let handle = phpc_value_null();
        assert_eq!(phpc_value_free(handle), PHPC_STATUS_OK);
        assert_eq!(phpc_value_clone(handle), INVALID_HANDLE);
    }

    #[test]
    fn cloned_null_handle_has_independent_ownership() {
        let original = phpc_value_null();
        let clone = phpc_value_clone(original);

        assert_ne!(clone, INVALID_HANDLE);
        assert_ne!(clone, original);
        assert_eq!(phpc_value_kind(clone), PHPC_VALUE_KIND_NULL);

        assert_eq!(phpc_value_free(original), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(original), PHPC_VALUE_KIND_INVALID);
        assert_eq!(phpc_value_kind(clone), PHPC_VALUE_KIND_NULL);
        assert_eq!(phpc_value_free(clone), PHPC_STATUS_OK);
    }

    #[test]
    fn cloned_binary_string_owns_independent_bytes() {
        let original = unsafe { phpc_binary_string_new(b"owned".as_ptr().cast::<c_char>(), 5) };
        let clone = phpc_value_clone(original);

        assert_ne!(clone, INVALID_HANDLE);
        assert_ne!(clone, original);
        assert_eq!(phpc_value_kind(clone), PHPC_VALUE_KIND_BINARY_STRING);

        assert_eq!(phpc_value_free(original), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(original), PHPC_VALUE_KIND_INVALID);

        let mut len = 0;
        let ptr = unsafe { phpc_binary_string_data(clone, &mut len) };
        assert!(!ptr.is_null());
        assert_eq!(len, 5);
        let bytes = unsafe { slice::from_raw_parts(ptr.cast::<u8>(), len) };
        assert_eq!(bytes, b"owned");

        assert_eq!(phpc_value_free(clone), PHPC_STATUS_OK);
    }

    #[test]
    fn cloned_integer_handle_has_independent_ownership() {
        let original = phpc_integer_new(i64::MIN);
        let clone = phpc_value_clone(original);

        assert_ne!(clone, INVALID_HANDLE);
        assert_ne!(clone, original);
        assert_eq!(phpc_value_kind(clone), PHPC_VALUE_KIND_INTEGER);

        assert_eq!(phpc_value_free(original), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(original), PHPC_VALUE_KIND_INVALID);

        let mut value = 0;
        assert_eq!(
            unsafe { phpc_integer_value(clone, &mut value) },
            PHPC_STATUS_OK
        );
        assert_eq!(value, i64::MIN);
        assert_eq!(phpc_value_free(clone), PHPC_STATUS_OK);
    }

    #[test]
    fn cloned_boolean_handle_has_independent_ownership() {
        let original = phpc_boolean_new(1);
        let clone = phpc_value_clone(original);

        assert_ne!(clone, INVALID_HANDLE);
        assert_ne!(clone, original);
        assert_eq!(phpc_value_kind(clone), PHPC_VALUE_KIND_BOOLEAN);

        assert_eq!(phpc_value_free(original), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(original), PHPC_VALUE_KIND_INVALID);

        let mut value = 0;
        assert_eq!(
            unsafe { phpc_boolean_value(clone, &mut value) },
            PHPC_STATUS_OK
        );
        assert_eq!(value, 1);
        assert_eq!(phpc_value_free(clone), PHPC_STATUS_OK);
    }

    #[test]
    fn array_handle_is_runtime_owned_until_free() {
        let array = phpc_array_new();

        assert_ne!(array, INVALID_HANDLE);
        assert_eq!(phpc_value_kind(array), PHPC_VALUE_KIND_ARRAY);
        assert_eq!(phpc_array_count(array), 0);

        assert_eq!(phpc_value_free(array), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(array), PHPC_VALUE_KIND_INVALID);
    }

    #[test]
    fn array_append_clones_value_into_array_storage() {
        let array = phpc_array_new();
        let original =
            unsafe { phpc_binary_string_new(b"array-item".as_ptr().cast::<c_char>(), 10) };

        assert_eq!(phpc_array_append_value(array, original), PHPC_STATUS_OK);
        assert_eq!(phpc_array_count(array), 1);
        assert_eq!(phpc_value_free(original), PHPC_STATUS_OK);
        assert_eq!(phpc_value_kind(original), PHPC_VALUE_KIND_INVALID);

        let stored = phpc_array_value_at(array, 0);
        assert_ne!(stored, INVALID_HANDLE);
        assert_eq!(phpc_value_kind(stored), PHPC_VALUE_KIND_BINARY_STRING);

        let mut len = 0;
        let ptr = unsafe { phpc_binary_string_data(stored, &mut len) };
        assert!(!ptr.is_null());
        assert_eq!(len, 10);
        let bytes = unsafe { slice::from_raw_parts(ptr.cast::<u8>(), len) };
        assert_eq!(bytes, b"array-item");

        assert_eq!(phpc_value_free(stored), PHPC_STATUS_OK);
        assert_eq!(phpc_value_free(array), PHPC_STATUS_OK);
    }

    #[test]
    fn array_value_at_returns_new_owned_handle() {
        let array = phpc_array_new();
        let value = phpc_integer_new(9001);

        assert_eq!(phpc_array_append_value(array, value), PHPC_STATUS_OK);
        assert_eq!(phpc_value_free(value), PHPC_STATUS_OK);

        let first = phpc_array_value_at(array, 0);
        let second = phpc_array_value_at(array, 0);
        assert_ne!(first, INVALID_HANDLE);
        assert_ne!(second, INVALID_HANDLE);
        assert_ne!(first, second);

        assert_eq!(phpc_value_free(array), PHPC_STATUS_OK);

        let mut first_value = 0;
        let mut second_value = 0;
        assert_eq!(
            unsafe { phpc_integer_value(first, &mut first_value) },
            PHPC_STATUS_OK
        );
        assert_eq!(
            unsafe { phpc_integer_value(second, &mut second_value) },
            PHPC_STATUS_OK
        );
        assert_eq!(first_value, 9001);
        assert_eq!(second_value, 9001);

        assert_eq!(phpc_value_free(first), PHPC_STATUS_OK);
        assert_eq!(phpc_value_free(second), PHPC_STATUS_OK);
    }

    #[test]
    fn array_helpers_report_invalid_handles() {
        let array = phpc_array_new();
        let value = phpc_boolean_new(1);

        assert_eq!(phpc_array_count(INVALID_HANDLE), 0);
        assert_eq!(
            phpc_array_append_value(INVALID_HANDLE, value),
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(
            phpc_array_append_value(value, value),
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(
            phpc_array_append_value(array, INVALID_HANDLE),
            PHPC_STATUS_INVALID_HANDLE
        );
        assert_eq!(phpc_array_value_at(INVALID_HANDLE, 0), INVALID_HANDLE);
        assert_eq!(phpc_array_value_at(value, 0), INVALID_HANDLE);
        assert_eq!(phpc_array_value_at(array, 0), INVALID_HANDLE);
        assert_eq!(phpc_array_count(array), 0);

        assert_eq!(phpc_value_free(value), PHPC_STATUS_OK);
        assert_eq!(phpc_value_free(array), PHPC_STATUS_OK);
    }

    #[test]
    fn request_headers_append_in_order() {
        let mut request = RequestState::new();

        request.add_header(b"X-First: one", true).unwrap();
        request.add_header(b"X-Second: two", true).unwrap();

        assert_eq!(request.header_count(), 2);
        assert_eq!(request.header(0), Some(b"X-First: one".as_slice()));
        assert_eq!(request.header(1), Some(b"X-Second: two".as_slice()));
    }

    #[test]
    fn request_headers_replace_by_case_insensitive_name() {
        let mut request = RequestState::new();

        request.add_header(b"Content-Type: text/plain", true).unwrap();
        request.add_header(b"content-type: text/html", true).unwrap();

        assert_eq!(request.header_count(), 1);
        assert_eq!(request.header(0), Some(b"content-type: text/html".as_slice()));
    }

    #[test]
    fn request_headers_can_keep_duplicate_names() {
        let mut request = RequestState::new();

        request.add_header(b"Set-Cookie: a=1", true).unwrap();
        request.add_header(b"set-cookie: b=2", false).unwrap();

        assert_eq!(request.header_count(), 2);
        assert_eq!(request.header(0), Some(b"Set-Cookie: a=1".as_slice()));
        assert_eq!(request.header(1), Some(b"set-cookie: b=2".as_slice()));
    }

    #[test]
    fn request_headers_reject_empty_and_line_breaks() {
        let mut request = RequestState::new();

        assert_eq!(request.add_header(b"", true), Err(HeaderError::Empty));
        assert_eq!(
            request.add_header(b"X-Test: ok\r\nInjected: bad", true),
            Err(HeaderError::ContainsLineBreak)
        );
        assert_eq!(request.header_count(), 0);
    }

    #[test]
    fn request_headers_reject_mutation_after_sent() {
        let mut request = RequestState::new();

        request.add_header(b"X-Test: before", true).unwrap();
        request.mark_headers_sent();

        assert!(request.headers_sent());
        assert_eq!(
            request.add_header(b"X-Test: after", true),
            Err(HeaderError::HeadersAlreadySent)
        );
        assert_eq!(request.header(0), Some(b"X-Test: before".as_slice()));
    }

    #[test]
    fn c_abi_exposes_request_header_storage() {
        unsafe {
            let request = phpc_request_new();
            let header = b"X-Abi: value";

            assert_eq!(
                phpc_request_add_header(
                    request,
                    header.as_ptr().cast::<c_char>(),
                    header.len(),
                    true
                ),
                PhpcHeaderResult::Ok
            );
            assert_eq!(phpc_request_header_count(request), 1);
            assert_eq!(phpc_request_header_len(request, 0), header.len());
            assert!(!phpc_request_headers_sent(request));

            let ptr = phpc_request_header_ptr(request, 0);
            assert!(!ptr.is_null());
            let stored = slice::from_raw_parts(ptr.cast::<u8>(), header.len());
            assert_eq!(stored, header);

            phpc_request_mark_headers_sent(request);
            assert!(phpc_request_headers_sent(request));

            phpc_request_free(request);
        }
    }

    #[test]
    fn c_abi_reports_request_header_errors() {
        unsafe {
            let request = phpc_request_new();
            let header = b"X-Abi: value";

            assert_eq!(
                phpc_request_add_header(
                    std::ptr::null_mut(),
                    header.as_ptr().cast::<c_char>(),
                    header.len(),
                    true
                ),
                PhpcHeaderResult::NullRequest
            );
            assert_eq!(
                phpc_request_add_header(request, std::ptr::null(), 0, true),
                PhpcHeaderResult::NullHeader
            );
            assert_eq!(
                phpc_request_add_header(request, b"".as_ptr().cast::<c_char>(), 0, true),
                PhpcHeaderResult::Empty
            );

            phpc_request_mark_headers_sent(request);
            assert_eq!(
                phpc_request_add_header(
                    request,
                    header.as_ptr().cast::<c_char>(),
                    header.len(),
                    true
                ),
                PhpcHeaderResult::HeadersAlreadySent
            );

            phpc_request_free(request);
        }
    }
}
