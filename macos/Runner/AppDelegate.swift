import Cocoa
import FlutterMacOS
import native_splash_screen_macos

// Simple configuration provider
class SimpleSplashConfig: NativeSplashScreenConfigurationProvider {
    var windowWidth: Int { 500 }
    var windowHeight: Int { 300 }
    var windowTitle: String { "Goox" }
    var withAnimation: Bool { true }
    
    var imageFileName: String {
        #if DEBUG
        return "splash_screen_debug.png"
        #elseif PROFILE
        return "splash_screen_profile.png"
        #else
        return "splash_screen_release.png"
        #endif
    }
    
    var imageWidth: Int { 200 }
    var imageHeight: Int { 200 }
}

@main
class AppDelegate: FlutterAppDelegate {
  override init() {
    super.init()
    
    // Initialize splash screen configuration BEFORE app finishes launching
    // This ensures the splash screen is ready to be shown immediately
    NativeSplashScreen.configurationProvider = SimpleSplashConfig()
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Show splash screen BEFORE the main window is created
    // This is the earliest point in the app lifecycle where we can display UI
    NativeSplashScreen.show()
    
    // Hide the main window initially so splash screen is visible
    // The main window is created from MainMenu.xib before this method is called
    if let window = mainFlutterWindow {
      window.alphaValue = 0.0
    }
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Ensure main window has proper background color to match splash
    if let window = mainFlutterWindow {
      window.backgroundColor = NSColor(
        calibratedRed: 30.0 / 255.0,  // #1E1E1E
        green: 30.0 / 255.0,
        blue: 30.0 / 255.0,
        alpha: 1.0
      )
      
      // Delay showing the main window to ensure splash is visible first
      // The splash window has .floating level, so it will stay on top
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // Fade in the main window behind the splash
        NSAnimationContext.runAnimationGroup({ context in
          context.duration = 0.3
          window.animator().alphaValue = 1.0
        }, completionHandler: nil)
      }
    }
  }
}
