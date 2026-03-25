import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    
    self.minSize = NSSize(width: 1024, height: 700)
    
    if self.frame.width < 1024 || self.frame.height < 700 {
      let newFrame = NSRect(
        x: self.frame.origin.x,
        y: self.frame.origin.y,
        width: 1024,
        height: 700
      )
      self.setFrame(newFrame, display: true, animate: true)
    } else {
      self.setFrame(windowFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
