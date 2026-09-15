import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Set minimum window size to prevent UI overflow
    self.minSize = NSSize(width: 960, height: 600)

    var windowFrame = self.frame
    let defaultWidth: CGFloat = max(windowFrame.size.width, 1080)
    let defaultHeight: CGFloat = max(windowFrame.size.height, 700)
    windowFrame.size = NSSize(width: defaultWidth, height: defaultHeight)
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
