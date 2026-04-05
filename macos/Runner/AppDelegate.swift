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
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    NativeSplashScreen.configurationProvider = SimpleSplashConfig()
    NativeSplashScreen.show()
  }
}
