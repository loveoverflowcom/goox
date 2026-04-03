import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    
    // Set background color BEFORE setting contentViewController
    // Using calibratedRed for proper color rendering
    self.backgroundColor = NSColor(
      calibratedRed: 30.0 / 255.0,  // 0x1E = 30
      green: 30.0 / 255.0,           // 0x1E = 30
      blue: 30.0 / 255.0,            // 0x1E = 30
      alpha: 1.0
    )
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
