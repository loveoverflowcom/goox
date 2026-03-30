use crate::extensions::ExtensionInfo;
use std::{
    collections::HashMap,
    fs,
    path::{Path, PathBuf},
    sync::{LazyLock, Mutex},
};
use wasmtime::{Caller, Instance, Linker, Memory, Module, Store};
use wasmtime_wasi::p1::{add_to_linker_sync, WasiP1Ctx};
use wasmtime_wasi::WasiCtxBuilder;

const WASM_PAGE_SIZE: usize = 65_536;

struct ErpSessionState {
    wasi: WasiP1Ctx,
    output_buffer_ptr: Option<usize>,
    output_buffer_len: Option<usize>,
    last_error: Option<String>,
}

struct ErpSession {
    _module_path: PathBuf,
    store: Store<ErpSessionState>,
    instance: Instance,
}

struct ErpRuntime {
    next_session_id: u32,
    sessions: HashMap<u32, ErpSession>,
}

impl Default for ErpRuntime {
    fn default() -> Self {
        Self {
            next_session_id: 1,
            sessions: HashMap::new(),
        }
    }
}

static ERP_RUNTIME: LazyLock<Mutex<ErpRuntime>> =
    LazyLock::new(|| Mutex::new(ErpRuntime::default()));

pub fn open_session(workspace_root: String, file_path: String) -> Result<u32, String> {
    let extension = crate::extensions::extension_for_file(workspace_root, file_path.clone())
        .ok_or_else(|| format!("No compatible extension found to open {}.", file_path))?;

    if !extension.rendering {
        return Err(format!(
            "The {} extension does not support ERP rendering.",
            extension.name
        ));
    }

    let session = create_session(&extension, &file_path)?;
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session_id = runtime.next_session_id;
    runtime.next_session_id = runtime.next_session_id.saturating_add(1).max(1);
    runtime.sessions.insert(session_id, session);
    Ok(session_id)
}

pub fn get_page_count(session_id: u32) -> Result<i32, String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session = runtime
        .sessions
        .get_mut(&session_id)
        .ok_or_else(|| "session not found".to_string())?;

    let page_count = call_zero_arg_i32(&mut session.store, &session.instance, "erp_page_count")?;
    if page_count < 0 {
        return Err(
            last_error(session.store.data()).unwrap_or_else(|| "erp_page_count failed".into()),
        );
    }

    Ok(page_count)
}

pub fn render_page(
    session_id: u32,
    page_index: i32,
    width: i32,
    height: i32,
) -> Result<Vec<u8>, String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session = runtime
        .sessions
        .get_mut(&session_id)
        .ok_or_else(|| "session not found".to_string())?;

    let rendered = call_three_arg_i32(
        &mut session.store,
        &session.instance,
        "erp_render_page",
        page_index,
        width,
        height,
    )?;

    if rendered < 0 {
        return Err(
            last_error(session.store.data()).unwrap_or_else(|| "erp_render_page failed".into()),
        );
    }

    let (ptr, len) = output_buffer(session.store.data())?;
    let memory = exported_memory(&mut session.store, &session.instance)?;
    let mut pixels = vec![0u8; len];
    memory
        .read(&mut session.store, ptr, &mut pixels)
        .map_err(|error| format!("failed to read ERP output buffer: {error}"))?;

    if rendered as usize != len {
        pixels.truncate(rendered as usize);
    }

    Ok(pixels)
}

pub fn close_session(session_id: u32) -> Result<(), String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let Some(mut session) = runtime.sessions.remove(&session_id) else {
        return Err("session not found".to_string());
    };

    let _ = call_void(&mut session.store, &session.instance, "erp_close");
    Ok(())
}

fn create_session(extension: &ExtensionInfo, file_path: &str) -> Result<ErpSession, String> {
    let entry = extension
        .entry
        .as_deref()
        .ok_or_else(|| format!("The {} extension does not provide a WASM entry.", extension.name))?;

    let module_path = Path::new(&extension.path).join(entry);
    let module_bytes = fs::read(&module_path)
        .map_err(|error| format!("failed to read wasm plugin {}: {error}", module_path.display()))?;

    let engine = crate::extensions::wasm_engine();
    let module = Module::new(engine, module_bytes)
        .map_err(|error| format!("failed to compile wasm plugin {}: {error}", module_path.display()))?;

    // Build WASI context — give plugin read access to the file's parent directory
    let file_abs = fs::canonicalize(file_path)
        .unwrap_or_else(|_| PathBuf::from(file_path));
    let parent_dir = file_abs.parent().unwrap_or(Path::new("/"));
    let wasi = WasiCtxBuilder::new()
        .inherit_stderr()
        .preopened_dir(
            parent_dir,
            "/data",
            wasmtime_wasi::DirPerms::READ,
            wasmtime_wasi::FilePerms::READ,
        )
        .map_err(|e| format!("failed to preopen dir: {e}"))?
        .build_p1();

    let state = ErpSessionState {
        wasi,
        output_buffer_ptr: None,
        output_buffer_len: None,
        last_error: None,
    };

    let mut linker: Linker<ErpSessionState> = Linker::new(engine);
    add_to_linker_sync(&mut linker, |s| &mut s.wasi)
        .map_err(|e| format!("failed to add WASI to linker: {e}"))?;
    register_erp_hosts(&mut linker)?;

    let mut store = Store::new(engine, state);
    let instance = linker
        .instantiate(&mut store, &module)
        .map_err(|error| format!("failed to instantiate wasm plugin {}: {error}", module_path.display()))?;

    if let Err(error) = call_void(&mut store, &instance, "_initialize") {
        // _initialize is optional (called by WASI runtime init), ignore if missing
        let _ = error;
    }

    // Pass file path as WASI-style string via erp_open
    // With WASI, the plugin can open the file itself via the preopened dir.
    // We pass the filename (not full path) so plugin can open /data/<filename>
    let filename = file_abs
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or(file_path);
    let filename_bytes = filename.as_bytes();

    // Write filename into WASM memory at safe offset
    let memory = exported_memory(&mut store, &instance)?;
    let file_ptr = WASM_PAGE_SIZE;
    write_guest_bytes(&mut store, &memory, file_ptr, filename_bytes)?;

    let file_ptr_i32 = i32::try_from(file_ptr).map_err(|_| "file pointer overflow".to_string())?;
    let file_len_i32 = i32::try_from(filename_bytes.len()).map_err(|_| "file length overflow".to_string())?;

    let open = instance
        .get_typed_func::<(i32, i32), i32>(&mut store, "erp_open")
        .map_err(|_| format!("the {} extension does not export erp_open", extension.name))?;
    let open_result = open
        .call(&mut store, (file_ptr_i32, file_len_i32))
        .map_err(|error| format!("erp_open failed for {}: {error}", file_path))?;
    if open_result < 0 {
        return Err(last_error(store.data()).unwrap_or_else(|| "erp_open failed".into()));
    }

    Ok(ErpSession {
        _module_path: module_path,
        store,
        instance,
    })
}

fn register_erp_hosts(linker: &mut Linker<ErpSessionState>) -> Result<(), String> {
    linker
        .func_wrap("env", "erp_set_output_buffer", host_set_output_buffer)
        .map_err(|error| format!("failed to register erp_set_output_buffer: {error}"))?;
    linker
        .func_wrap("env", "erp_report_error", host_report_error)
        .map_err(|error| format!("failed to register erp_report_error: {error}"))?;
    Ok(())
}

fn host_set_output_buffer(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let state = caller.data_mut();
    state.output_buffer_ptr = Some(
        usize::try_from(ptr).map_err(|_| wasmtime::Error::msg("invalid output buffer ptr"))?,
    );
    state.output_buffer_len = Some(
        usize::try_from(len).map_err(|_| wasmtime::Error::msg("invalid output buffer len"))?,
    );
    Ok(())
}

fn host_report_error(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    caller.data_mut().last_error = Some(message);
    Ok(())
}

fn call_void(
    store: &mut Store<ErpSessionState>,
    instance: &Instance,
    name: &str,
) -> Result<(), String> {
    let function = match instance.get_func(&mut *store, name) {
        Some(function) => function,
        None => return Ok(()),
    };

    function
        .typed::<(), ()>(&mut *store)
        .map_err(|error| format!("failed to prepare {name}: {error}"))?
        .call(&mut *store, ())
        .map_err(|error| error.to_string())?;
    Ok(())
}

fn call_zero_arg_i32(
    store: &mut Store<ErpSessionState>,
    instance: &Instance,
    name: &str,
) -> Result<i32, String> {
    let function = instance
        .get_typed_func::<(), i32>(&mut *store, name)
        .map_err(|_| format!("the wasm plugin does not export {name}"))?;
    function
        .call(&mut *store, ())
        .map_err(|error| format!("{name} failed: {error}"))
}

fn call_three_arg_i32(
    store: &mut Store<ErpSessionState>,
    instance: &Instance,
    name: &str,
    arg0: i32,
    arg1: i32,
    arg2: i32,
) -> Result<i32, String> {
    let function = instance
        .get_typed_func::<(i32, i32, i32), i32>(&mut *store, name)
        .map_err(|_| format!("the wasm plugin does not export {name}"))?;
    function
        .call(&mut *store, (arg0, arg1, arg2))
        .map_err(|error| format!("{name} failed: {error}"))
}

fn exported_memory(
    store: &mut Store<ErpSessionState>,
    instance: &Instance,
) -> Result<Memory, String> {
    instance
        .get_memory(&mut *store, "memory")
        .ok_or_else(|| "wasm guest did not export memory".to_string())
}

fn output_buffer(store: &ErpSessionState) -> Result<(usize, usize), String> {
    let ptr = store
        .output_buffer_ptr
        .ok_or_else(|| "erp_set_output_buffer was not called".to_string())?;
    let len = store
        .output_buffer_len
        .ok_or_else(|| "erp_set_output_buffer was not called".to_string())?;
    Ok((ptr, len))
}

fn last_error(store: &ErpSessionState) -> Option<String> {
    store.last_error.clone()
}

fn write_guest_bytes(
    store: &mut Store<ErpSessionState>,
    memory: &Memory,
    ptr: usize,
    bytes: &[u8],
) -> Result<(), String> {
    let end = ptr
        .checked_add(bytes.len())
        .ok_or_else(|| "guest buffer overflow".to_string())?;
    ensure_capacity(store, memory, end)?;
    memory
        .write(&mut *store, ptr, bytes)
        .map_err(|error| format!("failed to write guest memory: {error}"))
}

fn ensure_capacity(
    store: &mut Store<ErpSessionState>,
    memory: &Memory,
    end: usize,
) -> Result<(), String> {
    let current = memory.data_size(&mut *store);
    if end <= current {
        return Ok(());
    }

    let required = end - current;
    let pages = required.div_ceil(WASM_PAGE_SIZE);
    memory
        .grow(&mut *store, u64::try_from(pages).map_err(|_| "memory grow overflow".to_string())?)
        .map_err(|error| format!("failed to grow wasm memory: {error}"))?;
    Ok(())
}

fn read_guest_string(
    caller: &mut Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<String> {
    let memory = caller
        .get_export("memory")
        .and_then(|export| export.into_memory())
        .ok_or_else(|| wasmtime::Error::msg("wasm guest did not export memory"))?;

    let start = usize::try_from(ptr).map_err(|_| wasmtime::Error::msg("invalid guest pointer"))?;
    let len = usize::try_from(len).map_err(|_| wasmtime::Error::msg("invalid guest length"))?;
    let mut buffer = vec![0u8; len];
    memory
        .read(caller, start, &mut buffer)
        .map_err(|error| wasmtime::Error::msg(format!("failed to read guest memory: {error}")))?;

    String::from_utf8(buffer).map_err(|error| wasmtime::Error::msg(error.to_string()))
}

fn align_up(value: usize, alignment: usize) -> usize {
    if alignment == 0 {
        return value;
    }
    let remainder = value % alignment;
    if remainder == 0 {
        value
    } else {
        value + (alignment - remainder)
    }
}
