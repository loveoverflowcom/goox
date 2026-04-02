use serde::{Deserialize, Serialize};
use std::{
    collections::{BTreeMap, BTreeSet, HashMap, HashSet},
    fs,
    path::{Component, Path, PathBuf},
    sync::{LazyLock, Mutex},
};
use wasmtime::{Caller, Engine, Instance, Linker, Module, Store};
use wasmtime_wasi::WasiCtxBuilder;
use wasmtime_wasi::p1::{WasiP1Ctx, add_to_linker_sync};

#[derive(Debug, Clone)]
pub struct ExtensionMeta {
    pub name: String,
    pub path: PathBuf,
    pub entry: Option<String>,
    pub web_entry: Option<String>,
    pub filetypes: Vec<String>,
    pub language_id: Option<String>,
    pub lsp_executable: Option<String>,
    pub syntax_grammar: Option<String>,
    pub ui_mode: String,
    pub protocol: String,
    pub capabilities: Vec<String>,
    pub rendering: bool,
    pub enabled: bool,
    pub extension_type: ExtensionType,
}

#[derive(Debug, Clone)]
pub struct ExtensionInfo {
    pub name: String,
    pub path: String,
    pub entry: Option<String>,
    pub web_entry: Option<String>,
    pub filetypes: Vec<String>,
    pub language_id: Option<String>,
    pub lsp_executable: Option<String>,
    pub ui_mode: String,
    pub protocol: String,
    pub capabilities: Vec<String>,
    pub rendering: bool,
    pub extension_type: ExtensionType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ExtensionScope {
    Global,
    Workspace,
}

#[derive(Debug, Clone, Default)]
struct ExtensionRegistry {
    extensions_by_name: BTreeMap<String, ExtensionMeta>,
    filetype_index: BTreeMap<String, String>,
}

impl ExtensionRegistry {
    fn build(workspace_root: Option<&Path>) -> Self {
        let mut registry = Self::default();

        for global_root in global_extensions_dirs() {
            registry.merge_scanned(scan_extensions_dir(&global_root, ExtensionScope::Global));
        }

        if let Some(workspace_root) = workspace_root {
            let workspace_extensions = workspace_root.join(".goox/extensions");
            registry.merge_scanned(scan_extensions_dir(
                &workspace_extensions,
                ExtensionScope::Workspace,
            ));
        }

        registry
    }

    fn merge_scanned(&mut self, scanned: Vec<ExtensionMeta>) {
        for extension in scanned {
            if extension.enabled {
                self.extensions_by_name
                    .insert(extension.name.clone(), extension.clone());

                for filetype in &extension.filetypes {
                    self.filetype_index
                        .insert(normalize_filetype(filetype), extension.name.clone());
                }
            }
        }
    }

    fn find_for_filetype(&self, filetype: &str) -> Option<ExtensionMeta> {
        let extension_name = self.filetype_index.get(&normalize_filetype(filetype))?;
        self.extensions_by_name.get(extension_name).cloned()
    }
}

#[derive(Debug, Deserialize)]
struct ExtensionConfig {
    name: String,
    #[serde(default, rename = "type")]
    extension_type: Option<String>,
    #[serde(default)]
    entry: Option<String>,
    #[serde(default)]
    web_entry: Option<String>,
    #[serde(default)]
    filetypes: Vec<String>,
    #[serde(default)]
    language_id: Option<String>,
    #[serde(default)]
    lsp_executable: Option<String>,
    #[serde(default)]
    syntax_grammar: Option<String>,
    #[serde(default)]
    ui_mode: Option<String>,
    #[serde(default)]
    protocol: Option<String>,
    #[serde(default)]
    capabilities: Vec<String>,
    #[serde(default)]
    rendering: bool,
}

/// TOML-based extension configuration
#[derive(Debug, Deserialize)]
struct ExtensionToml {
    extension: ExtensionMetadata,
    #[serde(default)]
    language: Option<LanguageConfig>,
    #[serde(default)]
    webview: Option<WebviewConfig>,
    #[serde(default)]
    ui: Option<UiConfig>,
    #[serde(default)]
    protocol: Option<ProtocolConfig>,
}

#[derive(Debug, Deserialize)]
struct ExtensionMetadata {
    id: String,
    name: String,
    version: String,
    #[serde(default)]
    description: Option<String>,
    #[serde(default)]
    author: Option<String>,
    #[serde(default)]
    repository: Option<String>,
    #[serde(default, rename = "type")]
    extension_type: Option<String>,
    files: FilesConfig,
}

#[derive(Debug, Deserialize)]
struct FilesConfig {
    types: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct LanguageConfig {
    id: String,
    #[serde(default)]
    lsp_command: Option<String>,
    #[serde(default)]
    lsp_args: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct WebviewConfig {
    entry: String,
}

#[derive(Debug, Deserialize)]
struct UiConfig {
    #[serde(default)]
    mode: Option<String>,
    #[serde(default)]
    rendering: bool,
}

#[derive(Debug, Deserialize)]
struct ProtocolConfig {
    #[serde(default)]
    version: Option<String>,
    #[serde(default)]
    capabilities: Vec<String>,
}

/// New extension manifest structure for extension.json
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtensionManifest {
    pub id: String,
    pub name: String,
    pub version: String,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub author: Option<String>,
    #[serde(default)]
    pub repository: Option<String>,
    #[serde(default)]
    pub file_types: Vec<String>,
    #[serde(default)]
    pub webview_entry: Option<String>,
}

/// Extension type classification based on capabilities
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ExtensionType {
    /// Extension provides only language support (syntax highlighting, LSP)
    Language,
    /// Extension provides only webview rendering
    Renderer,
    /// Extension provides both language support and webview rendering
    DualMode,
}

#[derive(Debug, Clone)]
pub struct ValidationError {
    pub field: String,
    pub message: String,
}

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Validation error in field '{}': {}", self.field, self.message)
    }
}

impl std::error::Error for ValidationError {}

#[derive(Debug, Default)]
struct ExtensionRuntime {
    registry: ExtensionRegistry,
    module_cache: HashMap<PathBuf, std::sync::Arc<Module>>,
    activated_modules: HashSet<PathBuf>,
    loaded_commands: BTreeSet<String>,
    logs: Vec<String>,
}

static ENGINE: LazyLock<Engine> = LazyLock::new(Engine::default);
static RUNTIME: LazyLock<Mutex<ExtensionRuntime>> =
    LazyLock::new(|| Mutex::new(ExtensionRuntime::default()));

struct ExtensionActivationState {
    wasi: WasiP1Ctx,
}

pub(crate) fn wasm_engine() -> &'static Engine {
    &ENGINE
}

pub fn refresh_workspace_extensions(workspace_root: String) -> usize {
    let workspace_root = normalize_workspace_root(&workspace_root);
    let registry = ExtensionRegistry::build(workspace_root.as_deref());
    let count = registry.extensions_by_name.len();

    let mut runtime = RUNTIME.lock().unwrap();
    runtime.registry = registry;

    count
}

pub fn activate_extension_for_file(workspace_root: String, file_path: String) -> bool {
    let workspace_root = resolve_workspace_root(&workspace_root, Path::new(&file_path));
    let Some(filetype) = filetype_for_path(Path::new(&file_path)) else {
        return false;
    };

    let registry = ExtensionRegistry::build(workspace_root.as_deref());
    let selected = registry.find_for_filetype(&filetype);

    {
        let mut runtime = RUNTIME.lock().unwrap();
        runtime.registry = registry;
    }

    let Some(extension) = selected else {
        return false;
    };

    activate_extension(&extension)
}

pub fn extension_for_file(workspace_root: String, file_path: String) -> Option<ExtensionInfo> {
    let workspace_root = resolve_workspace_root(&workspace_root, Path::new(&file_path));
    let filetype = filetype_for_path(Path::new(&file_path))?;
    let registry = ExtensionRegistry::build(workspace_root.as_deref());
    {
        let mut runtime = RUNTIME.lock().unwrap();
        runtime.registry = registry.clone();
    }
    let extension = registry.find_for_filetype(&filetype)?;
    debug_log(format!(
        "matched extension {} for .{} (language_id={}, lsp_executable={})",
        extension.name,
        filetype,
        extension.language_id.as_deref().unwrap_or("none"),
        extension.lsp_executable.as_deref().unwrap_or("none")
    ));
    Some(ExtensionInfo::from(&extension))
}

pub fn validate_source_text(language_id: String, text: String) -> Option<String> {
    let normalized = language_id.trim().to_lowercase();
    if normalized.is_empty() || text.trim().is_empty() {
        return None;
    }

    debug_log(format!(
        "validate_source_text language={} chars={}",
        normalized,
        text.chars().count()
    ));

    let result = match normalized.as_str() {
        "python" => validate_python_source(&text),
        "javascript" | "js" | "typescript" => validate_javascript_source(&text),
        _ => None,
    };

    debug_log(format!(
        "validate_source_text result={} message={}",
        if result.is_some() { "error" } else { "ok" },
        result.as_deref().unwrap_or("none")
    ));
    result
}

pub fn registered_extension_commands() -> Vec<String> {
    RUNTIME
        .lock()
        .unwrap()
        .loaded_commands
        .iter()
        .cloned()
        .collect()
}

pub fn extension_logs() -> Vec<String> {
    RUNTIME.lock().unwrap().logs.clone()
}

fn activate_extension(extension: &ExtensionMeta) -> bool {
    let entry = if extension.ui_mode == "webview" {
        extension.web_entry.as_deref()
    } else {
        extension.entry.as_deref()
    };

    let Some(entry) = entry else {
        return false;
    };

    let entry_path = extension.path.join(entry);
    let canonical_entry_path = fs::canonicalize(&entry_path).unwrap_or(entry_path.clone());

    {
        let runtime = RUNTIME.lock().unwrap();
        if runtime.activated_modules.contains(&canonical_entry_path) {
            return true;
        }
    }

    if extension.ui_mode == "webview" {
        if !entry_path.exists() {
            debug_log(format!(
                "failed to activate webview extension {}: web entry {} does not exist",
                extension.name,
                entry_path.display()
            ));
            return false;
        }

        let mut runtime = RUNTIME.lock().unwrap();
        runtime.activated_modules.insert(canonical_entry_path);
        return true;
    }

    let bytes = match fs::read(&entry_path) {
        Ok(bytes) => bytes,
        Err(error) => {
            debug_log(format!(
                "failed to read wasm plugin {}: {}",
                entry_path.display(),
                error
            ));
            return false;
        }
    };

    let module = match Module::new(&ENGINE, bytes) {
        Ok(module) => module,
        Err(error) => {
            debug_log(format!(
                "failed to compile wasm plugin {}: {}",
                entry_path.display(),
                error
            ));
            return false;
        }
    };

    {
        let mut runtime = RUNTIME.lock().unwrap();
        runtime
            .module_cache
            .insert(canonical_entry_path.clone(), std::sync::Arc::new(module));
    }

    let module = {
        let runtime = RUNTIME.lock().unwrap();
        runtime.module_cache.get(&canonical_entry_path).cloned()
    };

    let Some(module) = module else {
        return false;
    };

    let mut linker: Linker<ExtensionActivationState> = Linker::new(&ENGINE);
    if let Err(error) = linker.func_wrap("env", "log", host_log) {
        debug_log(format!("failed to register log host function: {}", error));
        return false;
    }

    if let Err(error) = linker.func_wrap("env", "register_command", host_register_command) {
        debug_log(format!(
            "failed to register register_command host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) =
        linker.func_wrap("env", "erp_set_output_buffer", host_noop_set_output_buffer)
    {
        debug_log(format!(
            "failed to register erp_set_output_buffer host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "erp_set_metadata", host_noop_set_metadata) {
        debug_log(format!(
            "failed to register erp_set_metadata host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "erp_report_error", host_noop_report_error) {
        debug_log(format!(
            "failed to register erp_report_error host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap(
        "env",
        "erp_get_pdf_page_count",
        host_noop_get_pdf_page_count,
    ) {
        debug_log(format!(
            "failed to register erp_get_pdf_page_count host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "erp_render_pdf_page", host_noop_render_pdf_page) {
        debug_log(format!(
            "failed to register erp_render_pdf_page host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "erp_get_image_info", host_noop_get_image_info) {
        debug_log(format!(
            "failed to register erp_get_image_info host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "erp_render_image", host_noop_render_image) {
        debug_log(format!(
            "failed to register erp_render_image host function: {}",
            error
        ));
        return false;
    }

    // Register new host functions for WASM extension communication
    if let Err(error) = linker.func_wrap("env", "send_notification", host_send_notification) {
        debug_log(format!(
            "failed to register send_notification host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "read_file", host_read_file) {
        debug_log(format!(
            "failed to register read_file host function: {}",
            error
        ));
        return false;
    }
    if let Err(error) = linker.func_wrap("env", "update_ui", host_update_ui) {
        debug_log(format!(
            "failed to register update_ui host function: {}",
            error
        ));
        return false;
    }

    let wasi = WasiCtxBuilder::new()
        .inherit_stderr()
        .inherit_stdout()
        .build_p1();
    let state = ExtensionActivationState { wasi };

    if let Err(error) = add_to_linker_sync(&mut linker, |state| &mut state.wasi) {
        debug_log(format!("failed to add WASI to linker: {}", error));
        return false;
    }

    let mut store = Store::new(&ENGINE, state);
    let instance = match linker.instantiate(&mut store, &module) {
        Ok(instance) => instance,
        Err(error) => {
            debug_log(format!(
                "failed to instantiate wasm plugin {}: {}",
                entry_path.display(),
                error
            ));
            return false;
        }
    };

    if let Err(error) = call_activate(&mut store, &instance) {
        debug_log(format!(
            "failed to activate wasm plugin {}: {}",
            entry_path.display(),
            error
        ));
        return false;
    }

    let mut runtime = RUNTIME.lock().unwrap();
    runtime.activated_modules.insert(canonical_entry_path);
    true
}

fn call_activate<T>(store: &mut Store<T>, instance: &Instance) -> wasmtime::Result<()> {
    let activate = instance.get_typed_func::<(), ()>(&mut *store, "activate")?;
    activate.call(&mut *store, ())?;
    Ok(())
}

fn host_log<T>(mut caller: Caller<'_, T>, ptr: i32, len: i32) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    debug_log(message);
    Ok(())
}

fn host_register_command<T>(_caller: Caller<'_, T>, ptr: i32, len: i32) -> wasmtime::Result<()> {
    let mut caller = _caller;
    let command = read_guest_string(&mut caller, ptr, len)?;
    let mut runtime = RUNTIME.lock().unwrap();
    runtime.loaded_commands.insert(command);
    Ok(())
}

fn host_noop_set_output_buffer<T>(
    _caller: Caller<'_, T>,
    _ptr: i32,
    _len: i32,
) -> wasmtime::Result<()> {
    Ok(())
}

fn host_noop_set_metadata<T>(_caller: Caller<'_, T>, _ptr: i32, _len: i32) -> wasmtime::Result<()> {
    Ok(())
}

fn host_noop_report_error<T>(_caller: Caller<'_, T>, _ptr: i32, _len: i32) -> wasmtime::Result<()> {
    Ok(())
}

fn host_noop_get_pdf_page_count<T>(
    _caller: Caller<'_, T>,
    _file_ptr: i32,
    _file_len: i32,
) -> wasmtime::Result<i32> {
    Ok(-1)
}

fn host_noop_render_pdf_page<T>(
    _caller: Caller<'_, T>,
    _file_ptr: i32,
    _file_len: i32,
    _page_index: i32,
    _dpi: i32,
    _out_width_ptr: i32,
    _out_height_ptr: i32,
) -> wasmtime::Result<i32> {
    Ok(-1)
}

fn host_noop_get_image_info<T>(
    _caller: Caller<'_, T>,
    _file_ptr: i32,
    _file_len: i32,
    _out_width_ptr: i32,
    _out_height_ptr: i32,
) -> wasmtime::Result<i32> {
    Ok(-1)
}

fn host_noop_render_image<T>(
    _caller: Caller<'_, T>,
    _file_ptr: i32,
    _file_len: i32,
    _width: i32,
    _height: i32,
) -> wasmtime::Result<i32> {
    Ok(-1)
}

fn host_send_notification<T>(mut caller: Caller<'_, T>, ptr: i32, len: i32) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    debug_log(format!("[NOTIFICATION] {}", message));
    // TODO: Send notification to Dart side via message channel
    Ok(())
}

fn host_read_file<T>(mut caller: Caller<'_, T>, path_ptr: i32, path_len: i32) -> wasmtime::Result<i32> {
    let path = read_guest_string(&mut caller, path_ptr, path_len)?;
    debug_log(format!("[READ_FILE] Requested: {}", path));
    
    // TODO: Implement secure file reading with sandboxing
    // For now, return -1 to indicate file not found/not accessible
    // In the future, this should:
    // 1. Validate path is within extension directory
    // 2. Read file content
    // 3. Write content to WASM memory
    // 4. Return pointer to content
    Ok(-1)
}

fn host_update_ui<T>(mut caller: Caller<'_, T>, data_ptr: i32, data_len: i32) -> wasmtime::Result<()> {
    let data = read_guest_string(&mut caller, data_ptr, data_len)?;
    debug_log(format!("[UPDATE_UI] Data: {}", data));
    // TODO: Send UI update to Dart side via message channel
    Ok(())
}

fn read_guest_string<T>(
    caller: &mut Caller<'_, T>,
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

fn scan_extensions_dir(root: &Path, scope: ExtensionScope) -> Vec<ExtensionMeta> {
    let Ok(entries) = fs::read_dir(root) else {
        return Vec::new();
    };

    let mut directories = Vec::new();
    for entry in entries.flatten() {
        if entry
            .file_type()
            .map(|file_type| file_type.is_dir())
            .unwrap_or(false)
        {
            directories.push(entry.path());
        }
    }

    directories.sort_by(|left, right| {
        left.file_name()
            .and_then(|name| name.to_str())
            .unwrap_or_default()
            .to_lowercase()
            .cmp(
                &right
                    .file_name()
                    .and_then(|name| name.to_str())
                    .unwrap_or_default()
                    .to_lowercase(),
            )
    });

    directories
        .into_iter()
        .filter_map(|directory| read_extension_config(&directory, scope))
        .collect()
}

/// Classify extension type based on directory structure
/// 
/// This function determines the extension type by checking for:
/// - languages/ directory: indicates language support
/// - webview/ directory or webview_entry in manifest: indicates rendering capability
/// 
/// # Examples
/// 
/// ```no_run
/// use goox_core::extensions::classify_extension_type;
/// use std::path::Path;
/// 
/// let extension_path = Path::new("/path/to/extension");
/// let ext_type = classify_extension_type(extension_path, None);
/// ```
pub fn classify_extension_type(extension_path: &Path, webview_entry: Option<&str>) -> ExtensionType {
    let has_languages = extension_path.join("languages").is_dir();
    let has_webview = extension_path.join("webview").is_dir() || webview_entry.is_some();
    
    match (has_languages, has_webview) {
        (true, true) => ExtensionType::DualMode,
        (true, false) => ExtensionType::Language,
        (false, true) => ExtensionType::Renderer,
        (false, false) => ExtensionType::Language, // Default to language if neither
    }
}

fn read_extension_config(path: &Path, scope: ExtensionScope) -> Option<ExtensionMeta> {
    // Try TOML first (new format), then fall back to JSON (legacy)
    if let Some(meta) = read_extension_toml(path, scope) {
        return Some(meta);
    }
    
    read_extension_json(path, scope)
}

fn read_extension_toml(path: &Path, scope: ExtensionScope) -> Option<ExtensionMeta> {
    let toml_path = path.join("extension.toml");
    let content = fs::read_to_string(&toml_path).ok()?;
    let parsed: ExtensionToml = toml::from_str(&content).ok()?;

    let metadata = parsed.extension;
    if metadata.name.trim().is_empty() {
        return None;
    }

    let mut filetypes = metadata.files.types;
    filetypes.retain(|filetype| !filetype.trim().is_empty());
    filetypes.sort_by_key(|filetype| filetype.to_lowercase());
    filetypes.dedup_by(|left, right| left.eq_ignore_ascii_case(right));

    if filetypes.is_empty() {
        return None;
    }

    // Build LSP executable from command + args
    let lsp_executable = parsed.language.as_ref().and_then(|lang| {
        lang.lsp_command.as_ref().map(|cmd| {
            if lang.lsp_args.is_empty() {
                cmd.clone()
            } else {
                format!("{} {}", cmd, lang.lsp_args.join(" "))
            }
        })
    });

    let web_entry = parsed.webview.as_ref().map(|w| w.entry.clone());
    let ui_mode = parsed.ui.as_ref()
        .and_then(|u| u.mode.clone())
        .or_else(|| {
            if web_entry.is_some() {
                Some("webview".to_string())
            } else {
                Some("none".to_string())
            }
        });
    
    let rendering = parsed.ui.as_ref().map(|u| u.rendering).unwrap_or(false);
    let extension_type_str = metadata.extension_type.as_deref();
    
    let ui_mode = normalize_ui_mode(ui_mode, rendering, extension_type_str);
    let syntax_grammar = validate_syntax_grammar(path, None)?;
    
    // Classify extension type
    let classified_type = classify_extension_type(path, web_entry.as_deref());
    
    let extension = ExtensionMeta {
        name: metadata.name,
        path: path.to_path_buf(),
        entry: None, // WASM entry not supported in TOML yet
        web_entry: web_entry.filter(|entry| !entry.trim().is_empty()),
        filetypes: filetypes
            .into_iter()
            .map(|filetype| normalize_filetype(&filetype))
            .collect(),
        language_id: parsed.language.as_ref().map(|l| l.id.clone()),
        lsp_executable,
        syntax_grammar,
        ui_mode: ui_mode.clone(),
        protocol: parsed.protocol.as_ref()
            .and_then(|p| p.version.clone())
            .unwrap_or_else(|| "erp/1".to_string()),
        capabilities: parsed.protocol.as_ref()
            .map(|p| normalize_capabilities(p.capabilities.clone()))
            .unwrap_or_default(),
        rendering: rendering || ui_mode != "none" || extension_type_str == Some("renderer"),
        enabled: is_extension_enabled(path),
        extension_type: classified_type,
    };

    match scope {
        ExtensionScope::Global | ExtensionScope::Workspace => Some(extension),
    }
}

fn read_extension_json(path: &Path, scope: ExtensionScope) -> Option<ExtensionMeta> {
    let config_path = path.join("config.json");
    let config = fs::read_to_string(&config_path).ok()?;
    let parsed: ExtensionConfig = serde_json::from_str(&config).ok()?;

    if parsed.name.trim().is_empty() {
        return None;
    }

    let mut filetypes = parsed.filetypes;
    filetypes.retain(|filetype| !filetype.trim().is_empty());
    filetypes.sort_by_key(|filetype| filetype.to_lowercase());
    filetypes.dedup_by(|left, right| left.eq_ignore_ascii_case(right));

    if filetypes.is_empty() {
        return None;
    }

    let extension_type = parsed
        .extension_type
        .as_deref()
        .map(|value| value.trim().to_lowercase())
        .filter(|value| !value.is_empty());
    let ui_mode = normalize_ui_mode(parsed.ui_mode, parsed.rendering, extension_type.as_deref());
    let syntax_grammar = validate_syntax_grammar(path, parsed.syntax_grammar.as_deref())?;
    
    // Classify extension type based on directory structure
    let classified_type = classify_extension_type(
        path,
        parsed.web_entry.as_deref(),
    );
    
    let extension = ExtensionMeta {
        name: parsed.name,
        path: path.to_path_buf(),
        entry: parsed.entry.filter(|entry| !entry.trim().is_empty()),
        web_entry: parsed.web_entry.filter(|entry| !entry.trim().is_empty()),
        filetypes: filetypes
            .into_iter()
            .map(|filetype| normalize_filetype(&filetype))
            .collect(),
        language_id: parsed
            .language_id
            .filter(|language_id| !language_id.trim().is_empty()),
        lsp_executable: parsed
            .lsp_executable
            .filter(|lsp_executable| !lsp_executable.trim().is_empty()),
        syntax_grammar,
        ui_mode: ui_mode.clone(),
        protocol: parsed
            .protocol
            .filter(|protocol| !protocol.trim().is_empty())
            .unwrap_or_else(|| "erp/1".to_string()),
        capabilities: normalize_capabilities(parsed.capabilities),
        rendering: parsed.rendering
            || ui_mode != "none"
            || extension_type.as_deref() == Some("renderer"),
        enabled: is_extension_enabled(path),
        extension_type: classified_type,
    };

    match scope {
        ExtensionScope::Global | ExtensionScope::Workspace => Some(extension),
    }
}

fn normalize_workspace_root(workspace_root: &str) -> Option<PathBuf> {
    let trimmed = workspace_root.trim();
    if trimmed.is_empty() {
        return None;
    }

    Some(PathBuf::from(trimmed))
}

fn resolve_workspace_root(workspace_root: &str, file_path: &Path) -> Option<PathBuf> {
    normalize_workspace_root(workspace_root)
        .or_else(|| discover_workspace_root_from_file(file_path))
}

fn discover_workspace_root_from_file(file_path: &Path) -> Option<PathBuf> {
    let absolute = if file_path.is_absolute() {
        file_path.to_path_buf()
    } else {
        std::env::current_dir().ok()?.join(file_path)
    };

    for ancestor in absolute.ancestors() {
        if ancestor.join(".goox/extensions").is_dir() {
            return Some(ancestor.to_path_buf());
        }
    }

    None
}

fn global_extensions_dirs() -> Vec<PathBuf> {
    // Single canonical location matching Flutter's getApplicationSupportDirectory():
    //   macOS:   ~/Library/Application Support/dev.goox.goox/extensions
    //   Windows: %APPDATA%\dev.goox.goox\extensions
    //   Linux:   ~/.local/share/dev.goox.goox/extensions
    if let Some(data_dir) = dirs::data_dir() {
        vec![data_dir.join("dev.goox.goox").join("extensions")]
    } else {
        vec![]
    }
}

fn is_extension_enabled(path: &Path) -> bool {
    !path.join(".goox.disabled").exists()
}

fn normalize_filetype(filetype: &str) -> String {
    filetype.trim().trim_start_matches('.').to_lowercase()
}

fn normalize_ui_mode(
    ui_mode: Option<String>,
    rendering: bool,
    extension_type: Option<&str>,
) -> String {
    let normalized = ui_mode
        .as_deref()
        .map(|mode| mode.trim().to_lowercase())
        .filter(|mode| !mode.is_empty())
        .unwrap_or_default();

    if matches!(extension_type, Some("renderer")) {
        return "webview".to_string();
    }

    match normalized.as_str() {
        "canvas" | "webview" | "native" | "none" => normalized,
        _ if rendering => "canvas".to_string(),
        _ => "none".to_string(),
    }
}

fn normalize_capabilities(capabilities: Vec<String>) -> Vec<String> {
    let mut normalized = capabilities
        .into_iter()
        .map(|capability| capability.trim().to_lowercase())
        .filter(|capability| !capability.is_empty())
        .collect::<Vec<_>>();
    normalized.sort();
    normalized.dedup();
    normalized
}

fn validate_syntax_grammar(
    extension_path: &Path,
    syntax_grammar: Option<&str>,
) -> Option<Option<String>> {
    let Some(raw_path) = syntax_grammar else {
        return Some(None);
    };

    let trimmed = raw_path.trim();
    if trimmed.is_empty() {
        return Some(None);
    }

    let grammar_path = Path::new(trimmed);
    if grammar_path.is_absolute()
        || grammar_path.components().any(|component| {
            matches!(
                component,
                Component::ParentDir | Component::Prefix(_) | Component::RootDir
            )
        })
    {
        debug_log(format!(
            "invalid syntax_grammar path {}: absolute paths and path traversal are not allowed",
            grammar_path.display()
        ));
        return None;
    }

    let resolved = extension_path.join(grammar_path);
    if !resolved.exists() {
        debug_log(format!(
            "missing syntax_grammar file for {}: {}",
            extension_path.display(),
            resolved.display()
        ));
        return None;
    }

    Some(Some(resolved.display().to_string()))
}

fn validate_python_source(text: &str) -> Option<String> {
    validate_source_with_rules(text, SyntaxRules::python())
}

fn validate_javascript_source(text: &str) -> Option<String> {
    validate_source_with_rules(text, SyntaxRules::javascript())
}

fn validate_source_with_rules(text: &str, rules: SyntaxRules) -> Option<String> {
    let mut stack: Vec<(char, usize)> = Vec::new();
    let bytes = text.as_bytes();
    let mut index = 0usize;

    while index < bytes.len() {
        let current = bytes[index] as char;

        if rules.allow_hash_comments && current == '#' {
            index = line_end(text, index);
            continue;
        }

        if rules.allow_block_comments && starts_with(text, index, "/*") {
            match text[index + 2..].find("*/") {
                Some(offset) => {
                    index += offset + 4;
                    continue;
                }
                None => {
                    return Some(format!(
                        "{} syntax error: block comment is not closed.",
                        rules.language_name
                    ));
                }
            }
        }

        if rules.allow_block_comments && starts_with(text, index, "//") {
            index = line_end(text, index);
            continue;
        }

        if rules.allow_backticks && current == '`' {
            match consume_string(text, index, '`', true) {
                Some(end) => {
                    index = end;
                    continue;
                }
                None => {
                    return Some(format!(
                        "{} syntax error: template string is not closed.",
                        rules.language_name
                    ));
                }
            }
        }

        if starts_with(text, index, "'''") || starts_with(text, index, "\"\"\"") {
            let quote = if starts_with(text, index, "'''") {
                "'''"
            } else {
                "\"\"\""
            };
            match consume_triple_string(text, index, quote) {
                Some(end) => {
                    index = end;
                    continue;
                }
                None => {
                    return Some(format!(
                        "{} syntax error: string is not closed.",
                        rules.language_name
                    ));
                }
            }
        }

        if current == '\'' || current == '"' {
            match consume_string(text, index, current, false) {
                Some(end) => {
                    index = end;
                    continue;
                }
                None => {
                    return Some(format!(
                        "{} syntax error: string is not closed.",
                        rules.language_name
                    ));
                }
            }
        }

        if is_open_delimiter(current) {
            stack.push((current, index));
            index += 1;
            continue;
        }

        if is_close_delimiter(current) {
            let Some((opening, _opening_index)) = stack.pop() else {
                return Some(format!(
                    "{} syntax error: unexpected \"{}\".",
                    rules.language_name, current
                ));
            };

            if matching_closing(opening) != current {
                return Some(format!(
                    "{} syntax error: expected \"{}\" before \"{}\".",
                    rules.language_name,
                    matching_closing(opening),
                    current
                ));
            }

            index += 1;
            continue;
        }

        index += 1;
    }

    if let Some((opening, _)) = stack.last().copied() {
        return Some(format!(
            "{} syntax error: missing \"{}\".",
            rules.language_name,
            matching_closing(opening)
        ));
    }

    None
}

fn starts_with(text: &str, index: usize, pattern: &str) -> bool {
    text.get(index..)
        .is_some_and(|remaining| remaining.starts_with(pattern))
}

fn line_end(text: &str, index: usize) -> usize {
    match text[index..].find('\n') {
        Some(offset) => index + offset,
        None => text.len(),
    }
}

fn consume_string(text: &str, start: usize, quote: char, allow_multiline: bool) -> Option<usize> {
    let mut escaped = false;
    let mut index = start + quote.len_utf8();

    while index < text.len() {
        let current = text[index..].chars().next()?;
        if !allow_multiline && current == '\n' {
            return None;
        }

        if escaped {
            escaped = false;
            index += current.len_utf8();
            continue;
        }

        if current == '\\' {
            escaped = true;
            index += current.len_utf8();
            continue;
        }

        if current == quote {
            return Some(index + current.len_utf8());
        }

        index += current.len_utf8();
    }

    None
}

fn consume_triple_string(text: &str, start: usize, quote: &str) -> Option<usize> {
    let mut index = start + quote.len();
    while index < text.len() {
        if starts_with(text, index, quote) {
            return Some(index + quote.len());
        }
        let current = text[index..].chars().next()?;
        index += current.len_utf8();
    }

    None
}

fn is_open_delimiter(current: char) -> bool {
    matches!(current, '(' | '{' | '[')
}

fn is_close_delimiter(current: char) -> bool {
    matches!(current, ')' | '}' | ']')
}

fn matching_closing(current: char) -> char {
    match current {
        '(' => ')',
        '{' => '}',
        '[' => ']',
        _ => current,
    }
}

struct SyntaxRules {
    language_name: &'static str,
    allow_hash_comments: bool,
    allow_block_comments: bool,
    allow_backticks: bool,
}

impl SyntaxRules {
    fn python() -> Self {
        Self {
            language_name: "Python",
            allow_hash_comments: true,
            allow_block_comments: false,
            allow_backticks: false,
        }
    }

    fn javascript() -> Self {
        Self {
            language_name: "JavaScript",
            allow_hash_comments: false,
            allow_block_comments: true,
            allow_backticks: true,
        }
    }
}

fn filetype_for_path(path: &Path) -> Option<String> {
    let extension = path.extension().and_then(|ext| ext.to_str())?;
    let normalized = normalize_filetype(extension);
    if normalized.is_empty() {
        None
    } else {
        Some(normalized)
    }
}

impl From<&ExtensionMeta> for ExtensionInfo {
    fn from(value: &ExtensionMeta) -> Self {
        Self {
            name: value.name.clone(),
            path: value.path.display().to_string(),
            entry: value.entry.clone(),
            web_entry: value.web_entry.clone(),
            filetypes: value.filetypes.clone(),
            language_id: value.language_id.clone(),
            lsp_executable: value.lsp_executable.clone(),
            ui_mode: value.ui_mode.clone(),
            protocol: value.protocol.clone(),
            capabilities: value.capabilities.clone(),
            rendering: value.rendering,
            extension_type: value.extension_type,
        }
    }
}

fn debug_log(message: String) {
    eprintln!("{message}");
    RUNTIME.lock().unwrap().logs.push(message);
}

/// Validate extension.json manifest
/// 
/// This function validates the extension manifest structure according to the requirements:
/// - Required fields: id, name, version
/// - Version must follow semver format (e.g., 1.0.0)
/// - At least one file type must be specified
/// - Webview entry path must be relative and cannot contain path traversal
/// 
/// # Examples
/// 
/// ```
/// use goox_core::extensions::{ExtensionManifest, validate_manifest};
/// 
/// let manifest = ExtensionManifest {
///     id: "my-extension".to_string(),
///     name: "My Extension".to_string(),
///     version: "1.0.0".to_string(),
///     description: Some("A sample extension".to_string()),
///     author: Some("Author Name".to_string()),
///     repository: Some("https://github.com/user/repo".to_string()),
///     file_types: vec!["txt".to_string()],
///     webview_entry: Some("webview/index.html".to_string()),
/// };
/// 
/// assert!(validate_manifest(&manifest).is_ok());
/// ```
pub fn validate_manifest(manifest: &ExtensionManifest) -> Result<(), ValidationError> {
    // Validate required fields
    if manifest.id.trim().is_empty() {
        return Err(ValidationError {
            field: "id".to_string(),
            message: "Extension ID cannot be empty".to_string(),
        });
    }

    if manifest.name.trim().is_empty() {
        return Err(ValidationError {
            field: "name".to_string(),
            message: "Extension name cannot be empty".to_string(),
        });
    }

    if manifest.version.trim().is_empty() {
        return Err(ValidationError {
            field: "version".to_string(),
            message: "Extension version cannot be empty".to_string(),
        });
    }

    // Validate version format (basic semver check)
    if !is_valid_semver(&manifest.version) {
        return Err(ValidationError {
            field: "version".to_string(),
            message: format!("Invalid version format: '{}'. Expected semver format (e.g., 1.0.0)", manifest.version),
        });
    }

    // Validate file_types
    if manifest.file_types.is_empty() {
        return Err(ValidationError {
            field: "file_types".to_string(),
            message: "At least one file type must be specified".to_string(),
        });
    }

    for file_type in &manifest.file_types {
        if file_type.trim().is_empty() {
            return Err(ValidationError {
                field: "file_types".to_string(),
                message: "File types cannot contain empty strings".to_string(),
            });
        }
    }

    // Validate webview_entry path if present
    if let Some(webview_entry) = &manifest.webview_entry {
        if webview_entry.trim().is_empty() {
            return Err(ValidationError {
                field: "webview_entry".to_string(),
                message: "Webview entry cannot be empty string".to_string(),
            });
        }

        // Check for path traversal and absolute paths
        let entry_path = Path::new(webview_entry);
        if entry_path.is_absolute() {
            return Err(ValidationError {
                field: "webview_entry".to_string(),
                message: "Webview entry must be a relative path, not absolute".to_string(),
            });
        }

        if entry_path.components().any(|component| {
            matches!(
                component,
                Component::ParentDir | Component::Prefix(_) | Component::RootDir
            )
        }) {
            return Err(ValidationError {
                field: "webview_entry".to_string(),
                message: "Webview entry cannot contain path traversal (..)".to_string(),
            });
        }
    }

    Ok(())
}

/// Validate query files in languages/ directory
/// 
/// This function validates the structure of language query files:
/// - If languages/ directory exists, it must contain at least one language subdirectory
/// - Each language subdirectory must have:
///   - config.toml file
///   - queries/ directory with at least one .scm file
/// - All .scm files must be readable
/// 
/// # Examples
/// 
/// ```no_run
/// use goox_core::extensions::validate_queries;
/// use std::path::Path;
/// 
/// let extension_path = Path::new("/path/to/extension");
/// match validate_queries(extension_path) {
///     Ok(()) => println!("Queries are valid"),
///     Err(e) => eprintln!("Validation error: {}", e),
/// }
/// ```
pub fn validate_queries(extension_path: &Path) -> Result<(), ValidationError> {
    let languages_dir = extension_path.join("languages");
    
    // If languages directory doesn't exist, that's okay - not all extensions need it
    if !languages_dir.exists() {
        return Ok(());
    }

    if !languages_dir.is_dir() {
        return Err(ValidationError {
            field: "languages".to_string(),
            message: "languages/ must be a directory".to_string(),
        });
    }

    // Read all language subdirectories
    let entries = fs::read_dir(&languages_dir).map_err(|e| ValidationError {
        field: "languages".to_string(),
        message: format!("Failed to read languages directory: {}", e),
    })?;

    let mut found_language = false;
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }

        found_language = true;
        let lang_name = path.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unknown");

        // Check for config.toml
        let config_path = path.join("config.toml");
        if !config_path.exists() {
            return Err(ValidationError {
                field: format!("languages/{}", lang_name),
                message: "Missing required config.toml file".to_string(),
            });
        }

        // Check for queries directory
        let queries_dir = path.join("queries");
        if !queries_dir.exists() {
            return Err(ValidationError {
                field: format!("languages/{}", lang_name),
                message: "Missing required queries/ directory".to_string(),
            });
        }

        if !queries_dir.is_dir() {
            return Err(ValidationError {
                field: format!("languages/{}", lang_name),
                message: "queries/ must be a directory".to_string(),
            });
        }

        // Validate that at least one .scm file exists
        let query_entries = fs::read_dir(&queries_dir).map_err(|e| ValidationError {
            field: format!("languages/{}/queries", lang_name),
            message: format!("Failed to read queries directory: {}", e),
        })?;

        let mut has_scm_file = false;
        for query_entry in query_entries.flatten() {
            let query_path = query_entry.path();
            if query_path.extension().and_then(|e| e.to_str()) == Some("scm") {
                has_scm_file = true;
                
                // Validate .scm file is readable
                if let Err(e) = fs::read_to_string(&query_path) {
                    return Err(ValidationError {
                        field: format!("languages/{}/queries/{}", lang_name, query_path.file_name().unwrap().to_string_lossy()),
                        message: format!("Failed to read query file: {}", e),
                    });
                }
            }
        }

        if !has_scm_file {
            return Err(ValidationError {
                field: format!("languages/{}/queries", lang_name),
                message: "No .scm query files found in queries/ directory".to_string(),
            });
        }
    }

    // If languages/ directory exists but is empty, that's an error
    if !found_language {
        return Err(ValidationError {
            field: "languages".to_string(),
            message: "languages/ directory exists but contains no language subdirectories".to_string(),
        });
    }

    Ok(())
}

/// Helper function to validate semver format
fn is_valid_semver(version: &str) -> bool {
    let parts: Vec<&str> = version.split('.').collect();
    if parts.len() != 3 {
        return false;
    }

    for part in parts {
        // Each part should be a number
        if part.parse::<u32>().is_err() {
            return false;
        }
    }

    true
}

/// Load and validate extension manifest from extension.json
/// 
/// This function:
/// 1. Reads the extension.json file from the given path
/// 2. Parses it into an ExtensionManifest struct
/// 3. Validates the manifest structure
/// 4. Validates query files if languages/ directory exists
/// 
/// # Examples
/// 
/// ```no_run
/// use goox_core::extensions::load_extension_manifest;
/// use std::path::Path;
/// 
/// let extension_path = Path::new("/path/to/extension");
/// match load_extension_manifest(extension_path) {
///     Ok(manifest) => println!("Loaded extension: {}", manifest.name),
///     Err(e) => eprintln!("Failed to load manifest: {}", e),
/// }
/// ```
pub fn load_extension_manifest(extension_path: &Path) -> Result<ExtensionManifest, ValidationError> {
    let manifest_path = extension_path.join("extension.json");
    
    if !manifest_path.exists() {
        return Err(ValidationError {
            field: "manifest".to_string(),
            message: "extension.json file not found".to_string(),
        });
    }

    let content = fs::read_to_string(&manifest_path).map_err(|e| ValidationError {
        field: "manifest".to_string(),
        message: format!("Failed to read extension.json: {}", e),
    })?;

    let manifest: ExtensionManifest = serde_json::from_str(&content).map_err(|e| ValidationError {
        field: "manifest".to_string(),
        message: format!("Failed to parse extension.json: {}", e),
    })?;

    validate_manifest(&manifest)?;
    validate_queries(extension_path)?;

    Ok(manifest)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{
        fs::{self, File},
        io::Write,
        time::{SystemTime, UNIX_EPOCH},
    };

    fn unique_temp_dir(label: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("clock moved backwards")
            .as_nanos();
        std::env::temp_dir().join(format!("goox-{label}-{nanos}"))
    }

    fn copy_directory(source: &Path, target: &Path) {
        fs::create_dir_all(target).unwrap();
        for entry in fs::read_dir(source).unwrap() {
            let entry = entry.unwrap();
            let source_path = entry.path();
            let target_path = target.join(entry.file_name());
            if source_path.is_dir() {
                copy_directory(&source_path, &target_path);
            } else {
                fs::copy(&source_path, &target_path).unwrap();
            }
        }
    }

    fn write_config(
        dir: &Path,
        name: &str,
        entry: Option<&str>,
        web_entry: Option<&str>,
        extension_type: Option<&str>,
        filetypes: &[&str],
        language_id: Option<&str>,
        lsp_executable: Option<&str>,
        syntax_grammar: Option<&str>,
        ui_mode: Option<&str>,
        protocol: Option<&str>,
        capabilities: &[&str],
        rendering: bool,
    ) {
        fs::create_dir_all(dir).unwrap();
        let mut file = File::create(dir.join("config.json")).unwrap();
        let filetypes_json = filetypes
            .iter()
            .map(|filetype| format!("\"{filetype}\""))
            .collect::<Vec<_>>()
            .join(",");
        let entry_json = entry.map_or(String::from("null"), |entry| format!(r#""{entry}""#));
        let web_entry_json =
            web_entry.map_or(String::from("null"), |entry| format!(r#""{entry}""#));
        let extension_type_json =
            extension_type.map_or(String::from("null"), |value| format!(r#""{value}""#));
        let language_id_json = language_id.map_or(String::from("null"), |language_id| {
            format!(r#""{language_id}""#)
        });
        let lsp_executable_json =
            lsp_executable.map_or(String::from("null"), |lsp| format!(r#""{lsp}""#));
        let syntax_grammar_json =
            syntax_grammar.map_or(String::from("null"), |value| format!(r#""{value}""#));
        let ui_mode_json = ui_mode.map_or(String::from("null"), |mode| format!(r#""{mode}""#));
        let protocol_json = protocol.map_or(String::from("null"), |value| format!(r#""{value}""#));
        let capabilities_json = capabilities
            .iter()
            .map(|capability| format!(r#""{capability}""#))
            .collect::<Vec<_>>()
            .join(",");
        let body = format!(
            r#"{{"name":"{name}","type":{extension_type_json},"entry":{entry_json},"web_entry":{web_entry_json},"filetypes":[{filetypes_json}],"language_id":{language_id_json},"lsp_executable":{lsp_executable_json},"syntax_grammar":{syntax_grammar_json},"ui_mode":{ui_mode_json},"protocol":{protocol_json},"capabilities":[{capabilities_json}],"rendering":{rendering}}}"#
        );
        file.write_all(body.as_bytes()).unwrap();
    }

    #[test]
    fn workspace_overrides_global_by_name() {
        let workspace_root = unique_temp_dir("workspace");
        let global_root = unique_temp_dir("global");
        let global_plugin = global_root.join("pdf-viewer");
        let workspace_plugin = workspace_root.join(".goox/extensions/pdf-viewer");

        write_config(
            &global_plugin,
            "pdf-viewer",
            Some("plugin.wasm"),
            None,
            None,
            &["pdf"],
            None,
            None,
            None,
            Some("canvas"),
            Some("erp/1"),
            &["render.pdf"],
            true,
        );
        write_config(
            &workspace_plugin,
            "pdf-viewer",
            Some("plugin.wasm"),
            None,
            None,
            &["pdf", "pdfa"],
            None,
            None,
            None,
            Some("canvas"),
            Some("erp/1"),
            &["render.pdf", "document.read"],
            true,
        );

        let mut registry = ExtensionRegistry::default();
        registry.merge_scanned(scan_extensions_dir(&global_root, ExtensionScope::Global));
        registry.merge_scanned(scan_extensions_dir(
            &workspace_root.join(".goox/extensions"),
            ExtensionScope::Workspace,
        ));

        let extension = registry.find_for_filetype("pdf").unwrap();
        assert_eq!(extension.path, workspace_plugin);
        assert_eq!(
            extension.filetypes,
            vec!["pdf".to_string(), "pdfa".to_string()]
        );
    }

    #[test]
    fn scans_metadata_only_language_extension() {
        let workspace_root = unique_temp_dir("workspace-language");
        let python_plugin = workspace_root.join(".goox/extensions/python");

        write_config(
            &python_plugin,
            "python",
            None,
            None,
            None,
            &["py", "pyw"],
            Some("python"),
            Some("pyright-langserver"),
            None,
            None,
            None,
            &[],
            false,
        );

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        let extension = registry.find_for_filetype("py").unwrap();
        assert_eq!(extension.name, "python");
        assert_eq!(extension.entry, None);
        assert_eq!(extension.language_id.as_deref(), Some("python"));
        assert_eq!(
            extension.lsp_executable.as_deref(),
            Some("pyright-langserver")
        );
    }

    #[test]
    fn loads_valid_textmate_grammar_reference() {
        let workspace_root = unique_temp_dir("workspace-grammar");
        let extension_dir = workspace_root.join(".goox/extensions/dart");
        fs::create_dir_all(&extension_dir).unwrap();
        fs::write(
            extension_dir.join("dart.tmLanguage.json"),
            r#"{
                "name": "Dart",
                "scopeName": "source.dart",
                "fileTypes": ["dart"],
                "patterns": [
                  { "match": "\\bclass\\b", "name": "keyword.control.dart" }
                ]
            }"#,
        )
        .unwrap();

        write_config(
            &extension_dir,
            "dart",
            None,
            None,
            None,
            &["tmxlang"],
            Some("dart"),
            None,
            Some("dart.tmLanguage.json"),
            None,
            Some("erp/1"),
            &[],
            false,
        );

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        let extension = registry.find_for_filetype("tmxlang").unwrap();
        assert_eq!(extension.name, "dart");
    }

    #[test]
    fn rejects_absolute_textmate_grammar_path() {
        let workspace_root = unique_temp_dir("workspace-grammar-invalid");
        let extension_dir = workspace_root.join(".goox/extensions/dart");

        write_config(
            &extension_dir,
            "dart",
            None,
            None,
            None,
            &["tmxinvalid"],
            Some("dart"),
            None,
            Some("/tmp/invalid.tmLanguage.json"),
            None,
            Some("erp/1"),
            &[],
            false,
        );

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        assert!(registry.find_for_filetype("tmxinvalid").is_none());
    }

    #[test]
    fn activates_sample_flutter_webview_extension() {
        let workspace_root = unique_temp_dir("workspace-pdf");
        let workspace_extension = workspace_root.join(".goox/extensions/pdf-viewer");
        let source_extension = fs::canonicalize(
            Path::new(env!("CARGO_MANIFEST_DIR")).join("../../dummy_extensions/pdf-viewer"),
        )
        .expect("sample extension should exist");
        copy_directory(&source_extension, &workspace_extension);
        let pdf_path = workspace_root.join("sample.pdf");

        {
            let mut runtime = RUNTIME.lock().unwrap();
            runtime.registry = ExtensionRegistry::default();
            runtime.module_cache.clear();
            runtime.activated_modules.clear();
            runtime.loaded_commands.clear();
            runtime.logs.clear();
        }

        assert!(refresh_workspace_extensions(workspace_root.display().to_string(),) > 0);

        let extension = extension_for_file(
            workspace_root.display().to_string(),
            pdf_path.display().to_string(),
        )
        .expect("webview extension should be resolved");
        assert_eq!(extension.ui_mode, "webview");
        assert_eq!(extension.web_entry.as_deref(), Some("webview/index.html"));

        assert!(activate_extension_for_file(
            workspace_root.display().to_string(),
            pdf_path.display().to_string(),
        ));
        assert!(registered_extension_commands().is_empty());
    }

    #[test]
    fn renderer_type_defaults_to_webview_mode() {
        let workspace_root = unique_temp_dir("workspace-renderer-type");
        let renderer_extension = workspace_root.join(".goox/extensions/image-viewer");

        write_config(
            &renderer_extension,
            "image-viewer",
            None,
            Some("webview/index.html"),
            Some("renderer"),
            &["png"],
            None,
            None,
            None,
            None,
            Some("erp/1"),
            &["render.image"],
            true,
        );

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        let extension = registry.find_for_filetype("png").unwrap();
        assert_eq!(extension.ui_mode, "webview");
        assert_eq!(extension.web_entry.as_deref(), Some("webview/index.html"));
    }

    #[test]
    fn validates_extension_manifest_with_required_fields() {
        let manifest = ExtensionManifest {
            id: "test-extension".to_string(),
            name: "Test Extension".to_string(),
            version: "1.0.0".to_string(),
            description: Some("A test extension".to_string()),
            author: Some("Test Author".to_string()),
            repository: Some("https://github.com/test/test".to_string()),
            file_types: vec!["txt".to_string()],
            webview_entry: None,
        };

        assert!(validate_manifest(&manifest).is_ok());
    }

    #[test]
    fn rejects_manifest_with_empty_id() {
        let manifest = ExtensionManifest {
            id: "".to_string(),
            name: "Test Extension".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            author: None,
            repository: None,
            file_types: vec!["txt".to_string()],
            webview_entry: None,
        };

        let result = validate_manifest(&manifest);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.field, "id");
    }

    #[test]
    fn rejects_manifest_with_empty_name() {
        let manifest = ExtensionManifest {
            id: "test-extension".to_string(),
            name: "".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            author: None,
            repository: None,
            file_types: vec!["txt".to_string()],
            webview_entry: None,
        };

        let result = validate_manifest(&manifest);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.field, "name");
    }

    #[test]
    fn rejects_manifest_with_invalid_version() {
        let manifest = ExtensionManifest {
            id: "test-extension".to_string(),
            name: "Test Extension".to_string(),
            version: "invalid".to_string(),
            description: None,
            author: None,
            repository: None,
            file_types: vec!["txt".to_string()],
            webview_entry: None,
        };

        let result = validate_manifest(&manifest);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.field, "version");
    }

    #[test]
    fn rejects_manifest_with_empty_file_types() {
        let manifest = ExtensionManifest {
            id: "test-extension".to_string(),
            name: "Test Extension".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            author: None,
            repository: None,
            file_types: vec![],
            webview_entry: None,
        };

        let result = validate_manifest(&manifest);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.field, "file_types");
    }

    #[test]
    fn rejects_manifest_with_absolute_webview_path() {
        let manifest = ExtensionManifest {
            id: "test-extension".to_string(),
            name: "Test Extension".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            author: None,
            repository: None,
            file_types: vec!["txt".to_string()],
            webview_entry: Some("/absolute/path/index.html".to_string()),
        };

        let result = validate_manifest(&manifest);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.field, "webview_entry");
        assert!(err.message.contains("absolute"));
    }

    #[test]
    fn rejects_manifest_with_path_traversal() {
        let manifest = ExtensionManifest {
            id: "test-extension".to_string(),
            name: "Test Extension".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            author: None,
            repository: None,
            file_types: vec!["txt".to_string()],
            webview_entry: Some("../../../etc/passwd".to_string()),
        };

        let result = validate_manifest(&manifest);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.field, "webview_entry");
        assert!(err.message.contains("traversal"));
    }

    #[test]
    fn validates_queries_with_proper_structure() {
        let temp_dir = unique_temp_dir("validate-queries");
        let extension_dir = temp_dir.join("test-extension");
        let languages_dir = extension_dir.join("languages");
        let dart_dir = languages_dir.join("dart");
        let queries_dir = dart_dir.join("queries");

        fs::create_dir_all(&queries_dir).unwrap();
        
        // Create config.toml
        fs::write(
            dart_dir.join("config.toml"),
            r#"name = "Dart"
grammar = "dart"
path_suffixes = ["dart"]"#,
        )
        .unwrap();

        // Create a query file
        fs::write(
            queries_dir.join("highlights.scm"),
            r#"(identifier) @variable"#,
        )
        .unwrap();

        let result = validate_queries(&extension_dir);
        assert!(result.is_ok());
    }

    #[test]
    fn rejects_queries_without_config_toml() {
        let temp_dir = unique_temp_dir("validate-queries-no-config");
        let extension_dir = temp_dir.join("test-extension");
        let languages_dir = extension_dir.join("languages");
        let dart_dir = languages_dir.join("dart");
        let queries_dir = dart_dir.join("queries");

        fs::create_dir_all(&queries_dir).unwrap();
        
        // Create query file but no config.toml
        fs::write(
            queries_dir.join("highlights.scm"),
            r#"(identifier) @variable"#,
        )
        .unwrap();

        let result = validate_queries(&extension_dir);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(err.field.contains("dart"));
        assert!(err.message.contains("config.toml"));
    }

    #[test]
    fn rejects_queries_without_queries_directory() {
        let temp_dir = unique_temp_dir("validate-queries-no-dir");
        let extension_dir = temp_dir.join("test-extension");
        let languages_dir = extension_dir.join("languages");
        let dart_dir = languages_dir.join("dart");

        fs::create_dir_all(&dart_dir).unwrap();
        
        // Create config.toml but no queries directory
        fs::write(
            dart_dir.join("config.toml"),
            r#"name = "Dart""#,
        )
        .unwrap();

        let result = validate_queries(&extension_dir);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(err.field.contains("dart"));
        assert!(err.message.contains("queries"));
    }

    #[test]
    fn rejects_queries_without_scm_files() {
        let temp_dir = unique_temp_dir("validate-queries-no-scm");
        let extension_dir = temp_dir.join("test-extension");
        let languages_dir = extension_dir.join("languages");
        let dart_dir = languages_dir.join("dart");
        let queries_dir = dart_dir.join("queries");

        fs::create_dir_all(&queries_dir).unwrap();
        
        // Create config.toml and queries dir but no .scm files
        fs::write(
            dart_dir.join("config.toml"),
            r#"name = "Dart""#,
        )
        .unwrap();

        let result = validate_queries(&extension_dir);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(err.message.contains(".scm"));
    }

    #[test]
    fn accepts_extension_without_languages_directory() {
        let temp_dir = unique_temp_dir("validate-no-languages");
        let extension_dir = temp_dir.join("test-extension");
        fs::create_dir_all(&extension_dir).unwrap();

        // Extension without languages/ directory should be valid
        let result = validate_queries(&extension_dir);
        assert!(result.is_ok());
    }

    #[test]
    fn host_functions_are_callable() {
        // Test that host functions can be called with valid parameters
        // This verifies the function signatures are correct
        
        // Create a simple WASM module that calls the host functions
        let wat = r#"
            (module
                (import "env" "send_notification" (func $send_notification (param i32 i32)))
                (import "env" "read_file" (func $read_file (param i32 i32) (result i32)))
                (import "env" "update_ui" (func $update_ui (param i32 i32)))
                (memory (export "memory") 1)
                
                (func (export "test_send_notification")
                    (call $send_notification (i32.const 0) (i32.const 5))
                )
                
                (func (export "test_read_file") (result i32)
                    (call $read_file (i32.const 0) (i32.const 5))
                )
                
                (func (export "test_update_ui")
                    (call $update_ui (i32.const 0) (i32.const 5))
                )
                
                (data (i32.const 0) "hello")
            )
        "#;
        
        let wasm_bytes = wat::parse_str(wat).expect("Failed to parse WAT");
        let module = Module::new(&ENGINE, &wasm_bytes).expect("Failed to compile WASM");
        
        let mut linker: Linker<ExtensionActivationState> = Linker::new(&ENGINE);
        linker.func_wrap("env", "send_notification", host_send_notification).unwrap();
        linker.func_wrap("env", "read_file", host_read_file).unwrap();
        linker.func_wrap("env", "update_ui", host_update_ui).unwrap();
        
        let wasi = WasiCtxBuilder::new()
            .inherit_stderr()
            .inherit_stdout()
            .build_p1();
        let state = ExtensionActivationState { wasi };
        let mut store = Store::new(&ENGINE, state);
        
        let instance = linker.instantiate(&mut store, &module).expect("Failed to instantiate");
        
        // Test send_notification
        let send_notification_func = instance
            .get_typed_func::<(), ()>(&mut store, "test_send_notification")
            .expect("Failed to get send_notification function");
        send_notification_func.call(&mut store, ()).expect("send_notification failed");
        
        // Test read_file
        let read_file_func = instance
            .get_typed_func::<(), i32>(&mut store, "test_read_file")
            .expect("Failed to get read_file function");
        let result = read_file_func.call(&mut store, ()).expect("read_file failed");
        assert_eq!(result, -1); // Should return -1 for now (not implemented)
        
        // Test update_ui
        let update_ui_func = instance
            .get_typed_func::<(), ()>(&mut store, "test_update_ui")
            .expect("Failed to get update_ui function");
        update_ui_func.call(&mut store, ()).expect("update_ui failed");
    }

    #[test]
    fn loads_toml_extension_with_language_support() {
        let workspace_root = unique_temp_dir("workspace-toml-dart");
        let dart_extension = workspace_root.join(".goox/extensions/dart");
        fs::create_dir_all(&dart_extension).unwrap();

        // Create extension.toml
        fs::write(
            dart_extension.join("extension.toml"),
            r#"
[extension]
id = "dart-language-support"
name = "Dart Language Support"
version = "1.0.0"
description = "Syntax highlighting and language support for Dart"
author = "Goox Team"
repository = "https://github.com/goox/extensions"

[extension.files]
types = ["dart"]

[language]
id = "dart"
lsp_command = "dart"
lsp_args = ["language-server", "--protocol=lsp"]

[ui]
mode = "none"
rendering = false

[protocol]
version = "erp/1"
capabilities = []
"#,
        )
        .unwrap();

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        let extension = registry.find_for_filetype("dart").unwrap();
        
        assert_eq!(extension.name, "Dart Language Support");
        assert_eq!(extension.language_id.as_deref(), Some("dart"));
        assert_eq!(extension.lsp_executable.as_deref(), Some("dart language-server --protocol=lsp"));
        assert_eq!(extension.ui_mode, "none");
        assert_eq!(extension.rendering, false);
        assert_eq!(extension.extension_type, ExtensionType::Language);
    }

    #[test]
    fn loads_toml_extension_with_webview() {
        let workspace_root = unique_temp_dir("workspace-toml-markdown");
        let markdown_extension = workspace_root.join(".goox/extensions/markdown");
        let webview_dir = markdown_extension.join("webview");
        let languages_dir = markdown_extension.join("languages/markdown");
        fs::create_dir_all(&webview_dir).unwrap();
        fs::create_dir_all(&languages_dir).unwrap();

        // Create extension.toml
        fs::write(
            markdown_extension.join("extension.toml"),
            r#"
[extension]
id = "markdown-support"
name = "Markdown Support"
version = "1.0.0"
description = "Edit and preview Markdown files"
author = "Goox Team"

[extension.files]
types = ["md", "markdown"]

[language]
id = "markdown"

[webview]
entry = "webview/index.html"

[ui]
mode = "webview"
rendering = true

[protocol]
version = "erp/1"
capabilities = ["render.markdown"]
"#,
        )
        .unwrap();

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        let extension = registry.find_for_filetype("md").unwrap();
        
        assert_eq!(extension.name, "Markdown Support");
        assert_eq!(extension.language_id.as_deref(), Some("markdown"));
        assert_eq!(extension.web_entry.as_deref(), Some("webview/index.html"));
        assert_eq!(extension.ui_mode, "webview");
        assert_eq!(extension.rendering, true);
        assert_eq!(extension.capabilities, vec!["render.markdown"]);
        assert_eq!(extension.extension_type, ExtensionType::DualMode);
    }

    #[test]
    fn prefers_toml_over_json() {
        let workspace_root = unique_temp_dir("workspace-toml-priority");
        let test_extension = workspace_root.join(".goox/extensions/test");
        fs::create_dir_all(&test_extension).unwrap();

        // Create both TOML and JSON configs
        fs::write(
            test_extension.join("extension.toml"),
            r#"
[extension]
id = "test-extension"
name = "TOML Version"
version = "2.0.0"

[extension.files]
types = ["test"]

[ui]
mode = "none"
"#,
        )
        .unwrap();

        write_config(
            &test_extension,
            "JSON Version",
            None,
            None,
            None,
            &["test"],
            None,
            None,
            None,
            None,
            None,
            &[],
            false,
        );

        let registry = ExtensionRegistry::build(Some(&workspace_root));
        let extension = registry.find_for_filetype("test").unwrap();
        
        // Should load TOML version, not JSON
        assert_eq!(extension.name, "TOML Version");
    }
}
