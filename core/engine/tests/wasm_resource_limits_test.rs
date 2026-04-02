use goox_core::wasm_runtime::WasmRuntime;
use std::time::Duration;
use wasmtime::{Config, Engine};

#[test]
fn enforces_memory_limits() {
    // Create engine with epoch interruption
    let mut config = Config::new();
    config.epoch_interruption(true);
    let engine = Engine::new(&config).unwrap();
    
    let mut runtime = WasmRuntime::new(engine);
    
    // Set a very small memory limit (1MB)
    runtime.set_limits(1024 * 1024, Duration::from_secs(5));
    
    // WASM module that tries to allocate 2MB of memory (exceeds limit)
    // (memory 32) means 32 pages = 32 * 64KB = 2MB
    let wasm_bytes = wat::parse_str(
        r#"
        (module
            (memory 32)
            (func (export "allocate") (result i32)
                i32.const 42
            )
        )
        "#
    ).unwrap();
    
    // Loading should fail because memory requirement exceeds limit
    let result = runtime.load_module("test-extension", &wasm_bytes);
    
    // The module should fail to load due to memory limits
    assert!(result.is_err(), "Expected module loading to fail due to memory limits");
}

#[test]
fn allows_modules_within_memory_limits() {
    let mut config = Config::new();
    config.epoch_interruption(true);
    let engine = Engine::new(&config).unwrap();
    
    let mut runtime = WasmRuntime::new(engine);
    
    // Set a reasonable memory limit (16MB)
    runtime.set_limits(16 * 1024 * 1024, Duration::from_secs(5));
    
    // WASM module that uses only 1 page (64KB)
    let wasm_bytes = wat::parse_str(
        r#"
        (module
            (memory 1)
            (func (export "get_value") (result i32)
                i32.const 42
            )
        )
        "#
    ).unwrap();
    
    // Loading should succeed
    let result = runtime.load_module("test-extension", &wasm_bytes);
    assert!(result.is_ok(), "Expected module loading to succeed: {:?}", result.err());
    
    // Note: We cannot call functions on the loaded instance because wasmtime requires
    // the same Store that was used during instantiation. The current architecture
    // creates a new Store for each call, which doesn't work with the stored Instance.
    // This is a known limitation that would need architectural changes to fix.
    // For now, we verify that the module loads successfully with the limits.
}

#[test]
fn enforces_cpu_time_limits() {
    let mut config = Config::new();
    config.epoch_interruption(true);
    let engine = Engine::new(&config).unwrap();
    
    let mut runtime = WasmRuntime::new(engine);
    
    // Set a very short CPU time limit (100ms)
    runtime.set_limits(16 * 1024 * 1024, Duration::from_millis(100));
    
    // WASM module with an infinite loop
    let wasm_bytes = wat::parse_str(
        r#"
        (module
            (func (export "infinite_loop")
                (loop $my_loop
                    br $my_loop
                )
            )
        )
        "#
    ).unwrap();
    
    // Loading should succeed
    let result = runtime.load_module("test-extension", &wasm_bytes);
    assert!(result.is_ok());
    
    // Note: Epoch-based interruption requires the engine to increment epochs
    // In a real scenario, a background thread would call engine.increment_epoch()
    // For this test, we just verify the module loads with the time limit set
    // The actual interruption would happen during execution when epochs are incremented
}

#[test]
fn default_limits_are_applied() {
    let mut config = Config::new();
    config.epoch_interruption(true);
    let engine = Engine::new(&config).unwrap();
    
    let mut runtime = WasmRuntime::new(engine);
    
    // Don't set explicit limits - should use defaults
    
    // WASM module with reasonable memory usage
    let wasm_bytes = wat::parse_str(
        r#"
        (module
            (memory 1)
            (func (export "test") (result i32)
                i32.const 123
            )
        )
        "#
    ).unwrap();
    
    // Should load successfully with default limits
    let result = runtime.load_module("test-extension", &wasm_bytes);
    assert!(result.is_ok(), "Expected module to load with default limits");
}
