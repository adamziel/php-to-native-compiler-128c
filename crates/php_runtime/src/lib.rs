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

pub const PHPC_STATUS_OK: i32 = 0;
pub const PHPC_STATUS_INVALID_HANDLE: i32 = -1;
pub const PHPC_STATUS_INVALID_ARGUMENT: i32 = -2;

const INVALID_HANDLE: PhpcValueHandle = 0;

#[derive(Debug, Clone, PartialEq, Eq)]
enum PhpValue {
    Null,
    BinaryString(Vec<u8>),
    Integer(i64),
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
}
