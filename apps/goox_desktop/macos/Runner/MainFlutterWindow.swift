import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.backgroundColor = NSColor(
      calibratedRed: 44.0 / 255.0,
      green: 106.0 / 255.0,
      blue: 132.0 / 255.0,
      alpha: 1.0
    )
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
