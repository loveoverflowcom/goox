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
    pub entry: String,
    pub filetypes: Vec<String>,
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

        if let Some(global_root) = global_extensions_dir() {
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
            self.extensions_by_name
                .insert(extension.name.clone(), extension.clone());

            for filetype in &extension.filetypes {
                self.filetype_index
                    .insert(normalize_filetype(filetype), extension.name.clone());
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
    entry: String,
    #[serde(default)]
    filetypes: Vec<String>,
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

pub fn refresh_workspace_extensions(workspace_root: String) -> usize {
    let workspace_root = normalize_workspace_root(&workspace_root);
    let registry = ExtensionRegistry::build(workspace_root.as_deref());
    let count = registry.extensions_by_name.len();

    let mut runtime = RUNTIME.lock().unwrap();
    runtime.registry = registry;

    count
}

pub fn activate_extension_for_file(workspace_root: String, file_path: String) -> bool {
    let workspace_root = normalize_workspace_root(&workspace_root);
    let filetype = match Path::new(&file_path).extension().and_then(|ext| ext.to_str()) {
        Some(filetype) if !filetype.is_empty() => filetype.to_string(),
        _ => return false,
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
    let module_path = extension.path.join(&extension.entry);
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
        runtime
            .module_cache
            .get(&canonical_module_path)
            .cloned()
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

fn read_guest_string(
    caller: &mut Caller<'_, ()>,
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
        if entry.file_type().map(|file_type| file_type.is_dir()).unwrap_or(false) {
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

    if parsed.name.trim().is_empty() || parsed.entry.trim().is_empty() {
        return None;
    }

    let mut filetypes = parsed.filetypes;
    filetypes.retain(|filetype| !filetype.trim().is_empty());
    filetypes.sort_by_key(|filetype| filetype.to_lowercase());
    filetypes.dedup_by(|left, right| left.eq_ignore_ascii_case(right));

    let extension = ExtensionMeta {
        name: parsed.name,
        path: path.to_path_buf(),
        entry: parsed.entry,
        filetypes: filetypes.into_iter().map(|filetype| normalize_filetype(&filetype)).collect(),
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

fn global_extensions_dir() -> Option<PathBuf> {
    let home = std::env::var_os("HOME").or_else(|| std::env::var_os("USERPROFILE"))?;
    Some(PathBuf::from(home).join(".goox/extensions"))
}

fn normalize_filetype(filetype: &str) -> String {
    filetype.trim().trim_start_matches('.').to_lowercase()
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

    fn write_config(dir: &Path, name: &str, entry: &str, filetypes: &[&str]) {
        fs::create_dir_all(dir).unwrap();
        let mut file = File::create(dir.join("config.json")).unwrap();
        let filetypes_json = filetypes
            .iter()
            .map(|filetype| format!("\"{filetype}\""))
            .collect::<Vec<_>>()
            .join(",");
        let body = format!(
            r#"{{"name":"{name}","entry":"{entry}","filetypes":[{filetypes_json}]}}"#
        );
        file.write_all(body.as_bytes()).unwrap();
    }

    #[test]
    fn workspace_overrides_global_by_name() {
        let workspace_root = unique_temp_dir("workspace");
        let global_root = unique_temp_dir("global");
        let global_plugin = global_root.join("pdf-viewer");
        let workspace_plugin = workspace_root.join(".goox/extensions/pdf-viewer");

        write_config(&global_plugin, "pdf-viewer", "plugin.wasm", &["pdf"]);
        write_config(
            &workspace_plugin,
            "pdf-viewer",
            "plugin.wasm",
            &["pdf", "pdfa"],
        );

        let mut registry = ExtensionRegistry::default();
        registry.merge_scanned(scan_extensions_dir(&global_root, ExtensionScope::Global));
        registry.merge_scanned(scan_extensions_dir(
            &workspace_root.join(".goox/extensions"),
            ExtensionScope::Workspace,
        ));

        let extension = registry.find_for_filetype("pdf").unwrap();
        assert_eq!(extension.path, workspace_plugin);
        assert_eq!(extension.filetypes, vec!["pdf".to_string(), "pdfa".to_string()]);
    }

    #[test]
    fn activates_sample_pdf_viewer_plugin() {
        let workspace_root = fs::canonicalize(
            Path::new(env!("CARGO_MANIFEST_DIR")).join("../.."),
        )
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

        assert!(refresh_workspace_extensions(
            workspace_root.display().to_string(),
        ) > 0);
        assert!(activate_extension_for_file(
            workspace_root.display().to_string(),
            pdf_path.display().to_string(),
        ));

        let commands = registered_extension_commands();
        assert!(commands.iter().any(|command| command == "doc.openPdf"));
    }
}
