import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController

    let minWidth: CGFloat  = 1280
    let minHeight: CGFloat = 800

    self.minSize = NSSize(width: minWidth, height: minHeight)

    if self.frame.width < minWidth || self.frame.height < minHeight {
      let newFrame = NSRect(
        x: self.frame.origin.x,
        y: self.frame.origin.y,
        width: max(self.frame.width, minWidth),
        height: max(self.frame.height, minHeight)
      )
      self.setFrame(newFrame, display: true, animate: true)
    } else {
      self.setFrame(windowFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    MdnsPlugin.register(with: flutterViewController.registrar(forPlugin: "MdnsPlugin"))
    LocalFilesPlugin.register(with: flutterViewController)

    super.awakeFromNib()
  }
}
