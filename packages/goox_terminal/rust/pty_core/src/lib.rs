// PTY Core - Rust implementation for PTY terminal operations
// This module provides the core functionality for creating and managing
// pseudo-terminal sessions across different platforms.

use flutter_rust_bridge::frb;

/// Initialize the PTY core library
/// 
/// This function should be called once when the application starts.
/// It sets up logging and initializes any global state.
#[frb(init)]
pub fn init_pty_core() {
    // Initialize logging (can be configured later)
    #[cfg(debug_assertions)]
    {
        // In debug mode, we might want to enable logging
        // env_logger::init();
    }
    
    println!("PTY Core initialized");
}

/// Simple test function to verify FFI bridge is working
/// 
/// Returns a greeting message with the provided name.
#[frb]
pub fn greet(name: String) -> String {
    format!("Hello, {} from Rust PTY Core!", name)
}

/// Get the version of the PTY core library
#[frb]
pub fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet() {
        let result = greet("World".to_string());
        assert_eq!(result, "Hello, World from Rust PTY Core!");
    }

    #[test]
    fn test_version() {
        let version = get_version();
        assert!(!version.is_empty());
    }
}
