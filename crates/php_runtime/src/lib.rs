use std::ffi::c_char;
use std::io::{self, Write};
use std::slice;

#[no_mangle]
pub unsafe extern "C" fn phpc_echo(ptr: *const c_char, len: usize) {
    if ptr.is_null() {
        return;
    }
    let bytes = slice::from_raw_parts(ptr.cast::<u8>(), len);
    let _ = io::stdout().write_all(bytes);
}

#[cfg(test)]
mod tests {
    #[test]
    fn runtime_crate_links() {
        assert_eq!(2 + 2, 4);
    }
}

