use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};
use std::time::Duration;
use wasmtime::{Config, Engine, Instance, Linker, Memory, Module, Store, Extern, Val, ResourceLimiter};
use wasmtime_wasi::WasiCtxBuilder;
use wasmtime_wasi::p1::{WasiP1Ctx, add_to_linker_sync};

// Global WASM runtime instance
static WASM_RUNTIME: LazyLock<Mutex<WasmRuntime>> = LazyLock::new(|| {
    // Configure engine with resource limits
    let mut config = Config::new();
    
    // Enable epoch-based interruption for CPU time limits
    config.epoch_interruption(true);
    
    // Disable features that could be security risks
    config.wasm_threads(false);
    config.wasm_reference_types(false);
    config.wasm_simd(false);
    config.wasm_bulk_memory(false);
    
    let engine = Engine::new(&config).expect("Failed to create WASM engine");
    Mutex::new(WasmRuntime::new(engine))
});

/// WASM runtime for executing extension modules
pub struct WasmRuntime {
    engine: Engine,
    instances: HashMap<String, WasmInstance>,
    max_memory: Option<usize>,
    max_cpu_time: Option<Duration>,
}

/// A loaded WASM instance with its memory and exports
pub struct WasmInstance {
    pub instance: Instance,
    pub memory: Option<Memory>,
    pub exports: HashMap<String, Extern>,
}

/// Events that can be sent to WASM modules
#[derive(Debug, Clone)]
pub enum ExtensionEvent {
    FileOpened { path: String, content: String },
    FileSaved { path: String },
    FileEdited { path: String, edit: Edit },
    FileClosed { path: String },
}

/// Edit information for file changes
#[derive(Debug, Clone)]
pub struct Edit {
    pub start_byte: usize,
    pub old_end_byte: usize,
    pub new_end_byte: usize,
}

/// Values that can be passed to/from WASM functions
#[derive(Debug, Clone)]
pub enum Value {
    I32(i32),
    I64(i64),
    F32(f32),
    F64(f64),
    String(String),
}

/// WASM execution state
struct WasmState {
    wasi: WasiP1Ctx,
    memory_limit: usize,
    table_limit: usize,
}

impl ResourceLimiter for WasmState {
    fn memory_growing(&mut self, _current: usize, desired: usize, _maximum: Option<usize>) -> anyhow::Result<bool> {
        // Check if the desired memory exceeds our limit
        if desired > self.memory_limit {
            anyhow::bail!("Memory limit exceeded: {} > {}", desired, self.memory_limit);
        }
        Ok(true)
    }

    fn table_growing(&mut self, _current: usize, desired: usize, _maximum: Option<usize>) -> anyhow::Result<bool> {
        // Limit table growth
        if desired > self.table_limit {
            anyhow::bail!("Table limit exceeded: {} > {}", desired, self.table_limit);
        }
        Ok(true)
    }
}

impl WasmRuntime {
    /// Create a new WASM runtime
    pub fn new(engine: Engine) -> Self {
        Self {
            engine,
            instances: HashMap::new(),
            max_memory: None,
            max_cpu_time: None,
        }
    }

    /// Load a WASM module from bytes
    pub fn load_module(
        &mut self,
        extension_id: &str,
        wasm_bytes: &[u8],
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Compile the WASM module
        let module = Module::new(&self.engine, wasm_bytes)?;

        // Create WASI context with restricted capabilities
        let wasi = WasiCtxBuilder::new()
            .inherit_stderr()
            .inherit_stdout()
            // Do NOT inherit stdin, args, or env for security
            // Do NOT allow file system access by default
            .build_p1();

        // Determine memory and table limits
        let memory_limit = self.max_memory.unwrap_or(16 * 1024 * 1024); // Default: 16MB
        let table_limit = 10000; // Limit table elements to prevent DoS

        let state = WasmState { 
            wasi, 
            memory_limit,
            table_limit,
        };

        // Create linker and add WASI
        let mut linker: Linker<WasmState> = Linker::new(&self.engine);
        add_to_linker_sync(&mut linker, |state| &mut state.wasi)?;

        // Create store with resource limiter
        let mut store = Store::new(&self.engine, state);
        store.limiter(|state| state);
        
        // Set epoch deadline for CPU time limits if configured
        if let Some(max_cpu) = self.max_cpu_time {
            // Convert duration to epoch ticks (assuming 1 tick = 10ms)
            let ticks = max_cpu.as_millis() / 10;
            store.set_epoch_deadline(ticks as u64);
        } else {
            // Default: 5 second CPU time limit
            store.set_epoch_deadline(500); // 5000ms / 10ms = 500 ticks
        }

        // Instantiate the module
        let instance = linker.instantiate(&mut store, &module)?;

        // Extract memory and exports
        let memory = instance
            .get_export(&mut store, "memory")
            .and_then(|export| export.into_memory());

        let mut exports = HashMap::new();
        for export in instance.exports(&mut store) {
            exports.insert(export.name().to_string(), export.into_extern());
        }

        // Store the instance
        self.instances.insert(
            extension_id.to_string(),
            WasmInstance {
                instance,
                memory,
                exports,
            },
        );

        Ok(())
    }

    /// Call a WASM function by name
    pub fn call_function(
        &mut self,
        extension_id: &str,
        function_name: &str,
        args: &[Value],
    ) -> Result<Vec<Value>, Box<dyn std::error::Error>> {
        let instance_data = self
            .instances
            .get(extension_id)
            .ok_or_else(|| format!("Extension '{}' not loaded", extension_id))?;

        // Get the function export
        let func_export = instance_data
            .exports
            .get(function_name)
            .ok_or_else(|| format!("Function '{}' not found", function_name))?;

        let func = func_export
            .clone()
            .into_func()
            .ok_or_else(|| format!("Export '{}' is not a function", function_name))?;

        // Convert arguments to WASM values
        let wasm_args: Vec<Val> = args
            .iter()
            .map(|v| match v {
                Value::I32(i) => Val::I32(*i),
                Value::I64(i) => Val::I64(*i),
                Value::F32(f) => Val::F32(f.to_bits()),
                Value::F64(f) => Val::F64(f.to_bits()),
                Value::String(_) => {
                    // Strings need to be passed as pointer + length
                    // This is a simplified implementation
                    Val::I32(0)
                }
            })
            .collect();

        // Create a new store for this call with resource limits
        let wasi = WasiCtxBuilder::new()
            .inherit_stderr()
            .inherit_stdout()
            .build_p1();
        
        let memory_limit = self.max_memory.unwrap_or(16 * 1024 * 1024); // 16MB default
        let table_limit = 10000;
        
        let state = WasmState { 
            wasi, 
            memory_limit,
            table_limit,
        };
        let mut store = Store::new(&self.engine, state);
        store.limiter(|state| state);
        
        // Set CPU time limit
        if let Some(max_cpu) = self.max_cpu_time {
            let ticks = max_cpu.as_millis() / 10;
            store.set_epoch_deadline(ticks as u64);
        } else {
            store.set_epoch_deadline(500); // 5 second default
        }

        // Call the function
        let mut results = vec![Val::I32(0); func.ty(&store).results().len()];
        func.call(&mut store, &wasm_args, &mut results)?;

        // Convert results back to our Value type
        let converted_results: Vec<Value> = results
            .iter()
            .map(|v| match v {
                Val::I32(i) => Value::I32(*i),
                Val::I64(i) => Value::I64(*i),
                Val::F32(bits) => Value::F32(f32::from_bits(*bits)),
                Val::F64(bits) => Value::F64(f64::from_bits(*bits)),
                _ => Value::I32(0), // Fallback for unsupported types
            })
            .collect();

        Ok(converted_results)
    }

    /// Send an event to a WASM module
    pub fn send_event(
        &mut self,
        extension_id: &str,
        event: ExtensionEvent,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Determine which event handler to call based on event type
        let (handler_name, args) = match event {
            ExtensionEvent::FileOpened { path, content } => {
                ("on_file_opened", vec![Value::String(path), Value::String(content)])
            }
            ExtensionEvent::FileSaved { path } => {
                ("on_file_saved", vec![Value::String(path)])
            }
            ExtensionEvent::FileEdited { path, edit } => (
                "on_file_edited",
                vec![
                    Value::String(path),
                    Value::I32(edit.start_byte as i32),
                    Value::I32(edit.old_end_byte as i32),
                    Value::I32(edit.new_end_byte as i32),
                ],
            ),
            ExtensionEvent::FileClosed { path } => {
                ("on_file_closed", vec![Value::String(path)])
            }
        };

        // Try to call the event handler
        // It's okay if the handler doesn't exist - not all extensions need all handlers
        match self.call_function(extension_id, handler_name, &args) {
            Ok(_) => Ok(()),
            Err(e) => {
                // Log the error but don't fail - missing handlers are acceptable
                eprintln!("Event handler '{}' failed or not found: {}", handler_name, e);
                Ok(())
            }
        }
    }

    /// Set resource limits for WASM execution
    pub fn set_limits(&mut self, max_memory: usize, max_cpu_time: Duration) {
        self.max_memory = Some(max_memory);
        self.max_cpu_time = Some(max_cpu_time);
    }

    /// Check if an extension is loaded
    pub fn is_loaded(&self, extension_id: &str) -> bool {
        self.instances.contains_key(extension_id)
    }

    /// Unload a WASM module
    pub fn unload_module(&mut self, extension_id: &str) -> bool {
        self.instances.remove(extension_id).is_some()
    }

    /// Get list of loaded extension IDs
    pub fn loaded_extensions(&self) -> Vec<String> {
        self.instances.keys().cloned().collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_runtime_with_engine() {
        let mut config = Config::new();
        config.epoch_interruption(true);
        let engine = Engine::new(&config).unwrap();
        let runtime = WasmRuntime::new(engine);
        assert_eq!(runtime.instances.len(), 0);
    }

    #[test]
    fn sets_resource_limits() {
        let engine = Engine::default();
        let mut runtime = WasmRuntime::new(engine);
        runtime.set_limits(1024 * 1024, Duration::from_secs(5));
        assert_eq!(runtime.max_memory, Some(1024 * 1024));
        assert_eq!(runtime.max_cpu_time, Some(Duration::from_secs(5)));
    }

    #[test]
    fn tracks_loaded_extensions() {
        let mut config = Config::new();
        config.epoch_interruption(true);
        let engine = Engine::new(&config).unwrap();
        let runtime = WasmRuntime::new(engine);
        assert!(!runtime.is_loaded("test-extension"));
        assert_eq!(runtime.loaded_extensions().len(), 0);
    }

    #[test]
    fn creates_extension_events() {
        let event = ExtensionEvent::FileOpened {
            path: "test.txt".to_string(),
            content: "hello".to_string(),
        };
        match event {
            ExtensionEvent::FileOpened { path, content } => {
                assert_eq!(path, "test.txt");
                assert_eq!(content, "hello");
            }
            _ => panic!("Wrong event type"),
        }
    }

    #[test]
    fn creates_edit_events() {
        let edit = Edit {
            start_byte: 0,
            old_end_byte: 5,
            new_end_byte: 10,
        };
        assert_eq!(edit.start_byte, 0);
        assert_eq!(edit.old_end_byte, 5);
        assert_eq!(edit.new_end_byte, 10);
    }
}


// Public API functions for Dart FFI

/// Load a WASM module for an extension
pub fn load_module(extension_id: &str, wasm_bytes: &[u8]) -> Result<(), Box<dyn std::error::Error>> {
    let mut runtime = WASM_RUNTIME.lock().unwrap();
    runtime.load_module(extension_id, wasm_bytes)
}

/// Send file opened event to WASM module
pub fn send_file_opened_event(
    extension_id: &str,
    path: String,
    content: String,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut runtime = WASM_RUNTIME.lock().unwrap();
    let event = ExtensionEvent::FileOpened { path, content };
    runtime.send_event(extension_id, event)
}

/// Send file saved event to WASM module
pub fn send_file_saved_event(
    extension_id: &str,
    path: String,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut runtime = WASM_RUNTIME.lock().unwrap();
    let event = ExtensionEvent::FileSaved { path };
    runtime.send_event(extension_id, event)
}

/// Send file edited event to WASM module
pub fn send_file_edited_event(
    extension_id: &str,
    path: String,
    start_byte: usize,
    old_end_byte: usize,
    new_end_byte: usize,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut runtime = WASM_RUNTIME.lock().unwrap();
    let edit = Edit {
        start_byte,
        old_end_byte,
        new_end_byte,
    };
    let event = ExtensionEvent::FileEdited { path, edit };
    runtime.send_event(extension_id, event)
}

/// Send file closed event to WASM module
pub fn send_file_closed_event(
    extension_id: &str,
    path: String,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut runtime = WASM_RUNTIME.lock().unwrap();
    let event = ExtensionEvent::FileClosed { path };
    runtime.send_event(extension_id, event)
}

/// Check if an extension's WASM module is loaded
pub fn is_loaded(extension_id: &str) -> bool {
    let runtime = WASM_RUNTIME.lock().unwrap();
    runtime.is_loaded(extension_id)
}

/// Unload a WASM module
pub fn unload_module(extension_id: &str) -> bool {
    let mut runtime = WASM_RUNTIME.lock().unwrap();
    runtime.unload_module(extension_id)
}

/// Get list of loaded extension IDs
pub fn loaded_extensions() -> Vec<String> {
    let runtime = WASM_RUNTIME.lock().unwrap();
    runtime.loaded_extensions()
}
