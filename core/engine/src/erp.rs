use crate::extensions::ExtensionInfo;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashMap,
    fs,
    path::{Path, PathBuf},
    sync::{LazyLock, Mutex},
};
use wasmtime::{Caller, Instance, Linker, Memory, Module, Store};
use wasmtime_wasi::WasiCtxBuilder;
use wasmtime_wasi::p1::{WasiP1Ctx, add_to_linker_sync};

const WASM_PAGE_SIZE: usize = 65_536;

struct ErpSessionState {
    wasi: WasiP1Ctx,
    output_buffer_ptr: Option<usize>,
    output_buffer_len: Option<usize>,
    metadata: Option<String>,
    last_error: Option<String>,
    events: Vec<String>,
    artifacts: HashMap<u64, Vec<u8>>,
    registered_commands: Vec<String>,
    next_artifact_id: u64,
    /// Absolute path to the file opened in this session (for PDF host functions).
    file_abs_path: String,
}

struct NativeErpSessionState {
    metadata: Option<String>,
    events: Vec<String>,
    artifacts: HashMap<u64, Vec<u8>>,
    next_artifact_id: u64,
    file_abs_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ArtifactDescriptor {
    artifact_id: u64,
    kind: String,
    pixel_format: String,
    width: u32,
    height: u32,
    byte_len: usize,
}

struct ErpSession {
    backend: ErpSessionBackend,
}

enum ErpSessionBackend {
    Wasm {
        _module_path: PathBuf,
        store: Store<ErpSessionState>,
        instance: Instance,
    },
    Native(NativeErpSessionState),
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

    match &mut session.backend {
        ErpSessionBackend::Wasm {
            store, instance, ..
        } => {
            let page_count = call_zero_arg_i32(store, instance, "erp_page_count")?;
            if page_count < 0 {
                return Err(
                    last_error(store.data()).unwrap_or_else(|| "erp_page_count failed".into())
                );
            }

            Ok(page_count)
        }
        ErpSessionBackend::Native(state) => native_page_count(&state.file_abs_path),
    }
}

pub fn render_page_artifact(
    session_id: u32,
    page_index: i32,
    width: i32,
    height: i32,
) -> Result<String, String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session = runtime
        .sessions
        .get_mut(&session_id)
        .ok_or_else(|| "session not found".to_string())?;

    match &mut session.backend {
        ErpSessionBackend::Wasm {
            store, instance, ..
        } => {
            let artifact = render_page_bytes(store, instance, page_index, width, height)?;
            let state = store.data_mut();
            let descriptor = store_artifact(state, artifact, "raster", "rgba8888");
            state.events.push(rendered_event(page_index, &descriptor));
            serde_json::to_string(&descriptor)
                .map_err(|error| format!("failed to encode render descriptor: {error}"))
        }
        ErpSessionBackend::Native(state) => {
            let artifact = native_render_page(&state.file_abs_path, page_index, width, height)?;
            let descriptor = store_artifact_native(state, artifact, "raster", "rgba8888");
            state.events.push(rendered_event(page_index, &descriptor));
            serde_json::to_string(&descriptor)
                .map_err(|error| format!("failed to encode render descriptor: {error}"))
        }
    }
}

pub fn read_artifact(session_id: u32, artifact_id: u64) -> Result<Vec<u8>, String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session = runtime
        .sessions
        .get_mut(&session_id)
        .ok_or_else(|| "session not found".to_string())?;

    match &mut session.backend {
        ErpSessionBackend::Wasm { store, .. } => store
            .data()
            .artifacts
            .get(&artifact_id)
            .cloned()
            .ok_or_else(|| format!("artifact {artifact_id} not found")),
        ErpSessionBackend::Native(state) => state
            .artifacts
            .get(&artifact_id)
            .cloned()
            .ok_or_else(|| format!("artifact {artifact_id} not found")),
    }
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

    match &mut session.backend {
        ErpSessionBackend::Wasm {
            store, instance, ..
        } => {
            let artifact = render_page_bytes(store, instance, page_index, width, height)?;
            let state = store.data_mut();
            let descriptor = store_artifact(state, artifact, "raster", "rgba8888");
            state.events.push(rendered_event(page_index, &descriptor));
            store
                .data()
                .artifacts
                .get(&descriptor.artifact_id)
                .cloned()
                .ok_or_else(|| "render artifact missing after store".to_string())
        }
        ErpSessionBackend::Native(state) => {
            let artifact = native_render_page(&state.file_abs_path, page_index, width, height)?;
            let descriptor = store_artifact_native(state, artifact, "raster", "rgba8888");
            state.events.push(rendered_event(page_index, &descriptor));
            state
                .artifacts
                .get(&descriptor.artifact_id)
                .cloned()
                .ok_or_else(|| "render artifact missing after store".to_string())
        }
    }
}

pub fn close_session(session_id: u32) -> Result<(), String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let Some(mut session) = runtime.sessions.remove(&session_id) else {
        return Err("session not found".to_string());
    };

    if let ErpSessionBackend::Wasm {
        store, instance, ..
    } = &mut session.backend
    {
        let _ = call_void(store, instance, "erp_close");
    }
    Ok(())
}

pub fn get_metadata(session_id: u32) -> Result<Option<String>, String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session = runtime
        .sessions
        .get_mut(&session_id)
        .ok_or_else(|| "session not found".to_string())?;
    match &mut session.backend {
        ErpSessionBackend::Wasm { store, .. } => Ok(store.data().metadata.clone()),
        ErpSessionBackend::Native(state) => Ok(state.metadata.clone()),
    }
}

pub fn drain_events(session_id: u32) -> Result<Vec<String>, String> {
    let mut runtime = ERP_RUNTIME.lock().unwrap();
    let session = runtime
        .sessions
        .get_mut(&session_id)
        .ok_or_else(|| "session not found".to_string())?;
    match &mut session.backend {
        ErpSessionBackend::Wasm { store, .. } => {
            let state = store.data_mut();
            Ok(std::mem::take(&mut state.events))
        }
        ErpSessionBackend::Native(state) => Ok(std::mem::take(&mut state.events)),
    }
}

struct RenderedPage {
    bytes: Vec<u8>,
    width: u32,
    height: u32,
}

fn native_page_count(file_abs_path: &str) -> Result<i32, String> {
    let ext = Path::new(file_abs_path)
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_lowercase();

    if ext == "pdf" {
        let renderer = crate::pdf_renderer::PdfRenderer::new()
            .map_err(|error| format!("failed to initialize PDF renderer: {error}"))?;
        return renderer
            .get_page_count(file_abs_path)
            .map(|count| count as i32)
            .map_err(|error| error.to_string());
    }

    if matches!(
        ext.as_str(),
        "png" | "jpg" | "jpeg" | "gif" | "webp" | "bmp" | "ico" | "tif" | "tiff" | "avif" | "svg"
    ) {
        return Ok(1);
    }

    Err(format!(
        "native rendering does not support files with extension .{ext}"
    ))
}

fn native_render_page(
    file_abs_path: &str,
    page_index: i32,
    width: i32,
    height: i32,
) -> Result<RenderedPage, String> {
    if page_index < 0 {
        return Err("invalid page index".to_string());
    }
    if width <= 0 || height <= 0 {
        return Err("invalid render dimensions".to_string());
    }

    let ext = Path::new(file_abs_path)
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_lowercase();

    if ext == "pdf" {
        let renderer = crate::pdf_renderer::PdfRenderer::new()
            .map_err(|error| format!("failed to initialize PDF renderer: {error}"))?;
        let page = renderer
            .render_page_to_size(
                file_abs_path,
                page_index as u32,
                width as u32,
                height as u32,
            )
            .map_err(|error| error.to_string())?;
        return Ok(RenderedPage {
            bytes: page.data,
            width: page.width,
            height: page.height,
        });
    }

    let renderer = crate::image_renderer::ImageRenderer::new();
    let frame = renderer
        .render(file_abs_path, width as u32, height as u32)
        .map_err(|error| error.to_string())?;
    Ok(RenderedPage {
        bytes: frame.data,
        width: frame.width,
        height: frame.height,
    })
}

fn render_page_bytes(
    store: &mut Store<ErpSessionState>,
    instance: &Instance,
    page_index: i32,
    width: i32,
    height: i32,
) -> Result<RenderedPage, String> {
    let rendered = call_three_arg_i32(
        store,
        instance,
        "erp_render_page",
        page_index,
        width,
        height,
    )?;

    if rendered < 0 {
        return Err(last_error(store.data()).unwrap_or_else(|| "erp_render_page failed".into()));
    }

    let (ptr, len) = output_buffer(store.data())?;
    let memory = exported_memory(store, instance)?;
    let mut pixels = vec![0u8; len];
    memory
        .read(store, ptr, &mut pixels)
        .map_err(|error| format!("failed to read ERP output buffer: {error}"))?;

    if rendered as usize != len {
        pixels.truncate(rendered as usize);
    }

    let width = u32::try_from(width).map_err(|_| "invalid render width".to_string())?;
    let height = u32::try_from(height).map_err(|_| "invalid render height".to_string())?;

    Ok(RenderedPage {
        bytes: pixels,
        width,
        height,
    })
}

fn store_artifact(
    state: &mut ErpSessionState,
    page: RenderedPage,
    kind: &str,
    pixel_format: &str,
) -> ArtifactDescriptor {
    let artifact_id = {
        let id = state.next_artifact_id;
        state.next_artifact_id = state.next_artifact_id.saturating_add(1).max(1);
        state.artifacts.insert(id, page.bytes);
        id
    };

    ArtifactDescriptor {
        artifact_id,
        kind: kind.to_string(),
        pixel_format: pixel_format.to_string(),
        width: page.width,
        height: page.height,
        byte_len: state
            .artifacts
            .get(&artifact_id)
            .map(|bytes| bytes.len())
            .unwrap_or(0),
    }
}

fn store_artifact_native(
    state: &mut NativeErpSessionState,
    page: RenderedPage,
    kind: &str,
    pixel_format: &str,
) -> ArtifactDescriptor {
    let artifact_id = {
        let id = state.next_artifact_id;
        state.next_artifact_id = state.next_artifact_id.saturating_add(1).max(1);
        state.artifacts.insert(id, page.bytes);
        id
    };

    ArtifactDescriptor {
        artifact_id,
        kind: kind.to_string(),
        pixel_format: pixel_format.to_string(),
        width: page.width,
        height: page.height,
        byte_len: state
            .artifacts
            .get(&artifact_id)
            .map(|bytes| bytes.len())
            .unwrap_or(0),
    }
}

fn create_session(extension: &ExtensionInfo, file_path: &str) -> Result<ErpSession, String> {
    let file_abs = fs::canonicalize(file_path).unwrap_or_else(|_| PathBuf::from(file_path));
    let metadata = fallback_metadata(&file_abs);

    if extension.entry.is_none() {
        let mut state = NativeErpSessionState {
            metadata: Some(metadata.clone()),
            events: vec![ready_event(&extension.name), metadata.clone()],
            artifacts: HashMap::new(),
            next_artifact_id: 1,
            file_abs_path: file_abs.to_string_lossy().to_string(),
        };

        if state.metadata.is_none() {
            state.metadata = Some(metadata.clone());
        }

        return Ok(ErpSession {
            backend: ErpSessionBackend::Native(state),
        });
    }

    let entry = extension.entry.as_deref().ok_or_else(|| {
        format!(
            "The {} extension does not provide a WASM entry.",
            extension.name
        )
    })?;

    let module_path = Path::new(&extension.path).join(entry);
    let module_bytes = fs::read(&module_path).map_err(|error| {
        format!(
            "failed to read wasm plugin {}: {error}",
            module_path.display()
        )
    })?;

    let engine = crate::extensions::wasm_engine();
    let module = Module::new(engine, module_bytes).map_err(|error| {
        format!(
            "failed to compile wasm plugin {}: {error}",
            module_path.display()
        )
    })?;

    // Build WASI context — give plugin read access to the file's parent directory
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
        metadata: None,
        last_error: None,
        events: Vec::new(),
        artifacts: HashMap::new(),
        registered_commands: Vec::new(),
        next_artifact_id: 1,
        file_abs_path: file_abs.to_string_lossy().to_string(),
    };

    let mut linker: Linker<ErpSessionState> = Linker::new(engine);
    add_to_linker_sync(&mut linker, |s| &mut s.wasi)
        .map_err(|e| format!("failed to add WASI to linker: {e}"))?;
    register_erp_hosts(&mut linker)?;

    let mut store = Store::new(engine, state);
    let instance = linker.instantiate(&mut store, &module).map_err(|error| {
        format!(
            "failed to instantiate wasm plugin {}: {error}",
            module_path.display()
        )
    })?;

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
    let file_len_i32 =
        i32::try_from(filename_bytes.len()).map_err(|_| "file length overflow".to_string())?;

    let open = instance
        .get_typed_func::<(i32, i32), i32>(&mut store, "erp_open")
        .map_err(|_| format!("the {} extension does not export erp_open", extension.name))?;
    let open_result = open
        .call(&mut store, (file_ptr_i32, file_len_i32))
        .map_err(|error| format!("erp_open failed for {}: {error}", file_path))?;
    if open_result < 0 {
        return Err(last_error(store.data()).unwrap_or_else(|| "erp_open failed".into()));
    }

    if store.data().metadata.is_none() {
        let state = store.data_mut();
        state.metadata = Some(metadata.clone());
        state.events.push(metadata);
    }

    Ok(ErpSession {
        backend: ErpSessionBackend::Wasm {
            _module_path: module_path,
            store,
            instance,
        },
    })
}

fn register_erp_hosts(linker: &mut Linker<ErpSessionState>) -> Result<(), String> {
    linker
        .func_wrap("env", "erp_set_output_buffer", host_set_output_buffer)
        .map_err(|error| format!("failed to register erp_set_output_buffer: {error}"))?;
    linker
        .func_wrap("env", "register_command", host_register_command)
        .map_err(|error| format!("failed to register register_command: {error}"))?;
    linker
        .func_wrap("env", "erp_emit_event", host_emit_event)
        .map_err(|error| format!("failed to register erp_emit_event: {error}"))?;
    linker
        .func_wrap("env", "erp_set_metadata", host_set_metadata)
        .map_err(|error| format!("failed to register erp_set_metadata: {error}"))?;
    linker
        .func_wrap("env", "erp_report_error", host_report_error)
        .map_err(|error| format!("failed to register erp_report_error: {error}"))?;
    // PDF host functions (Requirement 1.1, 1.5)
    linker
        .func_wrap("env", "erp_get_pdf_page_count", host_get_pdf_page_count)
        .map_err(|error| format!("failed to register erp_get_pdf_page_count: {error}"))?;
    linker
        .func_wrap("env", "erp_render_pdf_page", host_render_pdf_page)
        .map_err(|error| format!("failed to register erp_render_pdf_page: {error}"))?;
    linker
        .func_wrap("env", "erp_get_image_info", host_get_image_info)
        .map_err(|error| format!("failed to register erp_get_image_info: {error}"))?;
    linker
        .func_wrap("env", "erp_render_image", host_render_image)
        .map_err(|error| format!("failed to register erp_render_image: {error}"))?;
    Ok(())
}

fn host_register_command(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let command = read_guest_string(&mut caller, ptr, len)?;
    caller.data_mut().registered_commands.push(command);
    Ok(())
}

fn host_emit_event(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    caller.data_mut().events.push(message);
    Ok(())
}

fn host_set_output_buffer(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let state = caller.data_mut();
    state.output_buffer_ptr =
        Some(usize::try_from(ptr).map_err(|_| wasmtime::Error::msg("invalid output buffer ptr"))?);
    state.output_buffer_len =
        Some(usize::try_from(len).map_err(|_| wasmtime::Error::msg("invalid output buffer len"))?);
    Ok(())
}

fn host_set_metadata(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    let state = caller.data_mut();
    state.metadata = Some(message.clone());
    state.events.push(message);
    Ok(())
}

fn host_report_error(
    mut caller: Caller<'_, ErpSessionState>,
    ptr: i32,
    len: i32,
) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    let state = caller.data_mut();
    state.last_error = Some(message.clone());
    state.events.push(message);
    Ok(())
}

/// Host function: erp_get_pdf_page_count(file_ptr, file_len) -> i32
///
/// Reads the filename from WASM memory, delegates to PdfRenderer::get_page_count.
/// Returns page count on success, -1 on failure (also calls erp_report_error).
///
/// Requirements: 1.5, 1.6
fn host_get_pdf_page_count(
    mut caller: Caller<'_, ErpSessionState>,
    file_ptr: i32,
    file_len: i32,
) -> wasmtime::Result<i32> {
    let filename = match read_guest_string(&mut caller, file_ptr, file_len) {
        Ok(s) => s,
        Err(e) => {
            let msg = format!("erp_get_pdf_page_count: failed to read filename: {e}");
            caller.data_mut().last_error = Some(msg.clone());
            return Ok(-1);
        }
    };

    // Resolve absolute path: use the session's file directory
    let file_abs = resolve_file_path(&caller, &filename);

    let renderer = match crate::pdf_renderer::PdfRenderer::new() {
        Ok(r) => r,
        Err(e) => {
            let msg = format!("erp_get_pdf_page_count: pdfium not available: {e}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    match renderer.get_page_count(&file_abs) {
        Ok(count) => Ok(count as i32),
        Err(e) => {
            let msg = format!("erp_get_pdf_page_count: {e}");
            caller.data_mut().last_error = Some(msg);
            Ok(-1)
        }
    }
}

/// Host function: erp_render_pdf_page(file_ptr, file_len, page_index, dpi,
///                                     out_width_ptr, out_height_ptr) -> i32
///
/// Renders a PDF page to RGBA, writes width/height to WASM memory via out pointers,
/// calls erp_set_output_buffer with the RGBA data.
/// Returns byte count on success, -1 on failure.
///
/// Requirements: 1.1, 1.2, 1.3, 1.4
fn host_render_pdf_page(
    mut caller: Caller<'_, ErpSessionState>,
    file_ptr: i32,
    file_len: i32,
    page_index: i32,
    dpi: i32,
    out_width_ptr: i32,
    out_height_ptr: i32,
) -> wasmtime::Result<i32> {
    let filename = match read_guest_string(&mut caller, file_ptr, file_len) {
        Ok(s) => s,
        Err(e) => {
            let msg = format!("erp_render_pdf_page: failed to read filename: {e}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    if page_index < 0 {
        let msg = format!("erp_render_pdf_page: invalid page_index {page_index}");
        caller.data_mut().last_error = Some(msg);
        return Ok(-1);
    }

    let file_abs = resolve_file_path(&caller, &filename);

    let renderer = match crate::pdf_renderer::PdfRenderer::new() {
        Ok(r) => r,
        Err(e) => {
            let msg = format!("erp_render_pdf_page: pdfium not available: {e}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    let rgba_page = match renderer.render_page(&file_abs, page_index as u32, dpi) {
        Ok(page) => page,
        Err(e) => {
            let msg = format!("erp_render_pdf_page: {e}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    let byte_count = rgba_page.data.len();

    // Write width and height into WASM memory via out pointers
    let memory = caller
        .get_export("memory")
        .and_then(|e| e.into_memory())
        .ok_or_else(|| wasmtime::Error::msg("wasm guest did not export memory"))?;

    let width_bytes = (rgba_page.width as i32).to_le_bytes();
    let height_bytes = (rgba_page.height as i32).to_le_bytes();

    let out_w = usize::try_from(out_width_ptr)
        .map_err(|_| wasmtime::Error::msg("invalid out_width_ptr"))?;
    let out_h = usize::try_from(out_height_ptr)
        .map_err(|_| wasmtime::Error::msg("invalid out_height_ptr"))?;

    memory
        .write(&mut caller, out_w, &width_bytes)
        .map_err(|e| wasmtime::Error::msg(format!("failed to write width: {e}")))?;
    memory
        .write(&mut caller, out_h, &height_bytes)
        .map_err(|e| wasmtime::Error::msg(format!("failed to write height: {e}")))?;

    // Store RGBA data in a stable location and call erp_set_output_buffer
    // We write the RGBA bytes into WASM memory at a safe offset (2 pages in)
    let rgba_offset = WASM_PAGE_SIZE * 2;
    let rgba_end = rgba_offset + byte_count;

    // Ensure memory is large enough
    let current_size = memory.data_size(&mut caller);
    if rgba_end > current_size {
        let pages_needed = (rgba_end - current_size).div_ceil(WASM_PAGE_SIZE);
        memory
            .grow(&mut caller, pages_needed as u64)
            .map_err(|e| wasmtime::Error::msg(format!("failed to grow memory: {e}")))?;
    }

    memory
        .write(&mut caller, rgba_offset, &rgba_page.data)
        .map_err(|e| wasmtime::Error::msg(format!("failed to write RGBA data: {e}")))?;

    // Record output buffer location in state
    caller.data_mut().output_buffer_ptr = Some(rgba_offset);
    caller.data_mut().output_buffer_len = Some(byte_count);

    Ok(byte_count as i32)
}

/// Host function: erp_get_image_info(file_ptr, file_len, out_width_ptr, out_height_ptr) -> i32
///
/// Reads the filename from WASM memory, inspects the image on the native side,
/// and writes width/height back to the guest.
fn host_get_image_info(
    mut caller: Caller<'_, ErpSessionState>,
    file_ptr: i32,
    file_len: i32,
    out_width_ptr: i32,
    out_height_ptr: i32,
) -> wasmtime::Result<i32> {
    let filename = match read_guest_string(&mut caller, file_ptr, file_len) {
        Ok(s) => s,
        Err(e) => {
            let msg = format!("erp_get_image_info: failed to read filename: {e}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    let file_abs = resolve_file_path(&caller, &filename);
    let renderer = crate::image_renderer::ImageRenderer::new();

    let info = match renderer.get_info(&file_abs) {
        Ok(info) => info,
        Err(error) => {
            let msg = format!("erp_get_image_info: {error}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    let memory = caller
        .get_export("memory")
        .and_then(|e| e.into_memory())
        .ok_or_else(|| wasmtime::Error::msg("wasm guest did not export memory"))?;

    let out_w = usize::try_from(out_width_ptr)
        .map_err(|_| wasmtime::Error::msg("invalid out_width_ptr"))?;
    let out_h = usize::try_from(out_height_ptr)
        .map_err(|_| wasmtime::Error::msg("invalid out_height_ptr"))?;
    memory
        .write(&mut caller, out_w, &(info.width as i32).to_le_bytes())
        .map_err(|e| wasmtime::Error::msg(format!("failed to write image width: {e}")))?;
    memory
        .write(&mut caller, out_h, &(info.height as i32).to_le_bytes())
        .map_err(|e| wasmtime::Error::msg(format!("failed to write image height: {e}")))?;

    Ok(0)
}

/// Host function: erp_render_image(file_ptr, file_len, width, height) -> i32
///
/// Native engine decodes and resizes the image, then writes the RGBA buffer into guest memory.
fn host_render_image(
    mut caller: Caller<'_, ErpSessionState>,
    file_ptr: i32,
    file_len: i32,
    width: i32,
    height: i32,
) -> wasmtime::Result<i32> {
    let filename = match read_guest_string(&mut caller, file_ptr, file_len) {
        Ok(s) => s,
        Err(e) => {
            let msg = format!("erp_render_image: failed to read filename: {e}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    if width <= 0 || height <= 0 {
        caller.data_mut().last_error = Some("erp_render_image: invalid dimensions".to_string());
        return Ok(-1);
    }

    let file_abs = resolve_file_path(&caller, &filename);
    let renderer = crate::image_renderer::ImageRenderer::new();
    let frame = match renderer.render(&file_abs, width as u32, height as u32) {
        Ok(frame) => frame,
        Err(error) => {
            let msg = format!("erp_render_image: {error}");
            caller.data_mut().last_error = Some(msg);
            return Ok(-1);
        }
    };

    let byte_count = frame.data.len();
    let memory = caller
        .get_export("memory")
        .and_then(|e| e.into_memory())
        .ok_or_else(|| wasmtime::Error::msg("wasm guest did not export memory"))?;

    let rgba_offset = WASM_PAGE_SIZE * 2;
    let rgba_end = rgba_offset + byte_count;
    let current_size = memory.data_size(&mut caller);
    if rgba_end > current_size {
        let pages_needed = (rgba_end - current_size).div_ceil(WASM_PAGE_SIZE);
        memory
            .grow(&mut caller, pages_needed as u64)
            .map_err(|e| wasmtime::Error::msg(format!("failed to grow memory: {e}")))?;
    }

    memory
        .write(&mut caller, rgba_offset, &frame.data)
        .map_err(|e| wasmtime::Error::msg(format!("failed to write image RGBA data: {e}")))?;

    caller.data_mut().output_buffer_ptr = Some(rgba_offset);
    caller.data_mut().output_buffer_len = Some(byte_count);

    Ok(byte_count as i32)
}

/// Resolve a filename to an absolute path using the session's file directory.
fn resolve_file_path(caller: &Caller<'_, ErpSessionState>, filename: &str) -> String {
    let session_path = &caller.data().file_abs_path;
    let parent = std::path::Path::new(session_path)
        .parent()
        .unwrap_or(std::path::Path::new("/"));
    parent.join(filename).to_string_lossy().to_string()
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

fn fallback_metadata(file_path: &Path) -> String {
    let size_bytes = fs::metadata(file_path).map(|meta| meta.len()).unwrap_or(0);
    let file_name = file_path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or_default();
    let extension = file_path
        .extension()
        .and_then(|ext| ext.to_str())
        .unwrap_or_default();

    format!(
        "{{\"v\":1,\"kind\":\"event\",\"topic\":\"document.metadata\",\"source\":\"erp-host\",\"payload\":{{\"name\":\"{}\",\"extension\":\"{}\",\"size_bytes\":{}}}}}",
        escape_json(file_name),
        escape_json(extension),
        size_bytes
    )
}

fn ready_event(source: &str) -> String {
    format!(
        "{{\"v\":1,\"kind\":\"event\",\"topic\":\"viewer.ready\",\"source\":\"{}\",\"payload\":{{}}}}",
        escape_json(source)
    )
}

fn rendered_event(page_index: i32, descriptor: &ArtifactDescriptor) -> String {
    format!(
        "{{\"v\":1,\"kind\":\"event\",\"topic\":\"viewer.rendered\",\"source\":\"erp-host\",\"payload\":{{\"page_index\":{},\"artifact_id\":{},\"kind\":\"{}\",\"pixel_format\":\"{}\",\"width\":{},\"height\":{},\"byte_len\":{}}}}}",
        page_index,
        descriptor.artifact_id,
        escape_json(&descriptor.kind),
        escape_json(&descriptor.pixel_format),
        descriptor.width,
        descriptor.height,
        descriptor.byte_len
    )
}

fn escape_json(value: &str) -> String {
    value
        .chars()
        .flat_map(|ch| match ch {
            '"' => "\\\"".chars().collect::<Vec<_>>(),
            '\\' => "\\\\".chars().collect::<Vec<_>>(),
            '\n' => "\\n".chars().collect::<Vec<_>>(),
            '\r' => "\\r".chars().collect::<Vec<_>>(),
            '\t' => "\\t".chars().collect::<Vec<_>>(),
            other => vec![other],
        })
        .collect()
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
        .grow(
            &mut *store,
            u64::try_from(pages).map_err(|_| "memory grow overflow".to_string())?,
        )
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
