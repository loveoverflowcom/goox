#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn log(ptr: *const u8, len: usize);
    fn register_command(ptr: *const u8, len: usize);
}

fn emit(import_fn: unsafe extern "C" fn(*const u8, usize), message: &str) {
    unsafe {
        import_fn(message.as_ptr(), message.len());
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn activate() {
    emit(log, "pdf plugin loaded");
    emit(register_command, "doc.openPdf");
}
