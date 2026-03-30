use serde::Deserialize;
use std::{
    collections::{BTreeMap, BTreeSet, HashMap, HashSet},
    fs,
    path::{Path, PathBuf},
    sync::{LazyLock, Mutex},
};
use wasmtime::{Caller, Engine, Instance, Linker, Module, Store};

#[derive(Debug, Clone)]
pub struct ExtensionMeta {
    pub name: String,
    pub path: PathBuf,
    pub entry: Option<String>,
    pub filetypes: Vec<String>,
    pub language_id: Option<String>,
    pub lsp_executable: Option<String>,
    pub rendering: bool,
    pub enabled: bool,
}

#[derive(Debug, Clone)]
pub struct ExtensionInfo {
    pub name: String,
    pub path: String,
    pub entry: Option<String>,
    pub filetypes: Vec<String>,
    pub language_id: Option<String>,
    pub lsp_executable: Option<String>,
    pub rendering: bool,
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
    #[serde(default)]
    entry: Option<String>,
    #[serde(default)]
    filetypes: Vec<String>,
    #[serde(default)]
    language_id: Option<String>,
    #[serde(default)]
    lsp_executable: Option<String>,
    #[serde(default)]
    rendering: bool,
}

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
    let Some(entry) = extension.entry.as_deref() else {
        return false;
    };

    let module_path = extension.path.join(entry);
    let canonical_module_path = fs::canonicalize(&module_path).unwrap_or(module_path.clone());

    {
        let runtime = RUNTIME.lock().unwrap();
        if runtime.activated_modules.contains(&canonical_module_path) {
            return true;
        }
    }

    let bytes = match fs::read(&module_path) {
        Ok(bytes) => bytes,
        Err(error) => {
            debug_log(format!(
                "failed to read wasm plugin {}: {}",
                module_path.display(),
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
                module_path.display(),
                error
            ));
            return false;
        }
    };

    {
        let mut runtime = RUNTIME.lock().unwrap();
        runtime
            .module_cache
            .insert(canonical_module_path.clone(), std::sync::Arc::new(module));
    }

    let module = {
        let runtime = RUNTIME.lock().unwrap();
        runtime.module_cache.get(&canonical_module_path).cloned()
    };

    let Some(module) = module else {
        return false;
    };

    let mut linker = Linker::new(&ENGINE);
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

    let mut store = Store::new(&ENGINE, ());
    let instance = match linker.instantiate(&mut store, &module) {
        Ok(instance) => instance,
        Err(error) => {
            debug_log(format!(
                "failed to instantiate wasm plugin {}: {}",
                module_path.display(),
                error
            ));
            return false;
        }
    };

    if let Err(error) = call_activate(&mut store, &instance) {
        debug_log(format!(
            "failed to activate wasm plugin {}: {}",
            module_path.display(),
            error
        ));
        return false;
    }

    let mut runtime = RUNTIME.lock().unwrap();
    runtime.activated_modules.insert(canonical_module_path);
    true
}

fn call_activate(store: &mut Store<()>, instance: &Instance) -> wasmtime::Result<()> {
    let activate = instance.get_typed_func::<(), ()>(&mut *store, "activate")?;
    activate.call(&mut *store, ())?;
    Ok(())
}

fn host_log(mut caller: Caller<'_, ()>, ptr: i32, len: i32) -> wasmtime::Result<()> {
    let message = read_guest_string(&mut caller, ptr, len)?;
    debug_log(message);
    Ok(())
}

fn host_register_command(_caller: Caller<'_, ()>, ptr: i32, len: i32) -> wasmtime::Result<()> {
    let mut caller = _caller;
    let command = read_guest_string(&mut caller, ptr, len)?;
    let mut runtime = RUNTIME.lock().unwrap();
    runtime.loaded_commands.insert(command);
    Ok(())
}

fn read_guest_string(caller: &mut Caller<'_, ()>, ptr: i32, len: i32) -> wasmtime::Result<String> {
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

fn read_extension_config(path: &Path, scope: ExtensionScope) -> Option<ExtensionMeta> {
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

    let extension = ExtensionMeta {
        name: parsed.name,
        path: path.to_path_buf(),
        entry: parsed.entry.filter(|entry| !entry.trim().is_empty()),
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
        rendering: parsed.rendering,
        enabled: is_extension_enabled(path),
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
            filetypes: value.filetypes.clone(),
            language_id: value.language_id.clone(),
            lsp_executable: value.lsp_executable.clone(),
            rendering: value.rendering,
        }
    }
}

fn debug_log(message: String) {
    eprintln!("{message}");
    RUNTIME.lock().unwrap().logs.push(message);
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

    fn write_config(
        dir: &Path,
        name: &str,
        entry: Option<&str>,
        filetypes: &[&str],
        language_id: Option<&str>,
        lsp_executable: Option<&str>,
    ) {
        fs::create_dir_all(dir).unwrap();
        let mut file = File::create(dir.join("config.json")).unwrap();
        let filetypes_json = filetypes
            .iter()
            .map(|filetype| format!("\"{filetype}\""))
            .collect::<Vec<_>>()
            .join(",");
        let entry_json = entry.map_or(String::from("null"), |entry| format!(r#""{entry}""#));
        let language_id_json = language_id.map_or(String::from("null"), |language_id| {
            format!(r#""{language_id}""#)
        });
        let lsp_executable_json =
            lsp_executable.map_or(String::from("null"), |lsp| format!(r#""{lsp}""#));
        let body = format!(
            r#"{{"name":"{name}","entry":{entry_json},"filetypes":[{filetypes_json}],"language_id":{language_id_json},"lsp_executable":{lsp_executable_json}}}"#
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
            &["pdf"],
            None,
            None,
        );
        write_config(
            &workspace_plugin,
            "pdf-viewer",
            Some("plugin.wasm"),
            &["pdf", "pdfa"],
            None,
            None,
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
            &["py", "pyw"],
            Some("python"),
            Some("pyright-langserver"),
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
    fn activates_sample_pdf_viewer_plugin() {
        let workspace_root = fs::canonicalize(Path::new(env!("CARGO_MANIFEST_DIR")).join("../.."))
            .expect("workspace root should exist");
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
        assert!(activate_extension_for_file(
            workspace_root.display().to_string(),
            pdf_path.display().to_string(),
        ));

        let commands = registered_extension_commands();
        assert!(commands.iter().any(|command| command == "doc.openPdf"));
    }
}
