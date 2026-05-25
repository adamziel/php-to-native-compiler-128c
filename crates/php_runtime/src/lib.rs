use std::collections::HashMap;
use std::ffi::c_char;
use std::io::{self, Write};
use std::slice;
use std::sync::{Mutex, OnceLock};

pub type PhpcValueHandle = u64;

pub const PHPC_VALUE_KIND_INVALID: i32 = -1;
pub const PHPC_VALUE_KIND_NULL: i32 = 0;
pub const PHPC_VALUE_KIND_BINARY_STRING: i32 = 1;

pub const PHPC_STATUS_OK: i32 = 0;
pub const PHPC_STATUS_INVALID_HANDLE: i32 = -1;
pub const PHPC_STATUS_INVALID_ARGUMENT: i32 = -2;

const INVALID_HANDLE: PhpcValueHandle = 0;

#[derive(Debug, Clone, PartialEq, Eq)]
enum PhpValue {
    Null,
    BinaryString(Vec<u8>),
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
}

fn runtime() -> &'static Mutex<RuntimeState> {
    static RUNTIME: OnceLock<Mutex<RuntimeState>> = OnceLock::new();
    RUNTIME.get_or_init(|| Mutex::new(RuntimeState::new()))
}

#[no_mangle]
pub unsafe extern "C" fn phpc_echo(ptr: *const c_char, len: usize) {
    if ptr.is_null() {
        return;
    }
    let bytes = slice::from_raw_parts(ptr.cast::<u8>(), len);
    let _ = io::stdout().write_all(bytes);
}

#[no_mangle]
pub extern "C" fn phpc_value_null() -> PhpcValueHandle {
    runtime().lock().unwrap().insert(PhpValue::Null)
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
        None => PHPC_VALUE_KIND_INVALID,
    }
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
pub extern "C" fn phpc_value_free(handle: PhpcValueHandle) -> i32 {
    let mut runtime = runtime().lock().unwrap();
    if runtime.values.remove(&handle).is_some() {
        PHPC_STATUS_OK
    } else {
        PHPC_STATUS_INVALID_HANDLE
    }
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
}
