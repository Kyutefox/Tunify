import Flutter
import UIKit
import Foundation

@_silgen_name("tunify_backend_start")
private func tunify_backend_start(_ databasePath: UnsafePointer<CChar>) -> Int32

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
    GeneratedPluginRegistrant.register(with: self)

    DispatchQueue.global(qos: .userInitiated).async {
      if !Self.hasStartedBundledBackend {
        let dbPath = Self.backendDatabasePath()
        Self.ensureParentDirectory(path: dbPath)
        let startCode = dbPath.withCString { cPath in
          tunify_backend_start(cPath)
        }
        if startCode == 0 || startCode == 1 {
          Self.hasStartedBundledBackend = true
        }
      }
    }
    // Initialize Flutter engine early for CarPlay access
    _ = flutterEngine
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private static var hasStartedBundledBackend = false

  private static func backendDatabasePath() -> String {
    let baseDir =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    return baseDir.appendingPathComponent("tunify.db").path
  }

  private static func ensureParentDirectory(path: String) {
    let parent = URL(fileURLWithPath: path).deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
  }
}
