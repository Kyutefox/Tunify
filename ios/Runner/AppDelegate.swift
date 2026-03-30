import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine: FlutterEngine = {
    let engine = FlutterEngine(name: "tunify_engine")
    engine.run()
    GeneratedPluginRegistrant.register(with: engine)
    return engine
  }()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Flutter engine early for CarPlay access
    _ = flutterEngine
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
