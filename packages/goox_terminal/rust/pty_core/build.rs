// Build script for pty_core
// This script is run before compiling the Rust code

fn main() {
    // Tell Cargo to rerun this build script if build.rs changes
    println!("cargo:rerun-if-changed=build.rs");

    // Platform-specific build configuration
    #[cfg(target_os = "macos")]
    {
        println!("cargo:rustc-link-lib=framework=CoreFoundation");
    }

    #[cfg(target_os = "windows")]
    {
        println!("cargo:rustc-link-lib=user32");
    }
}
