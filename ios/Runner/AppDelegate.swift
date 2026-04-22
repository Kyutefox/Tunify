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
        let bundledEnv = Self.loadBundledRuntimeEnv()
        Self.applyBundledRuntimeEnv(bundledEnv)
        let dbPath = Self.backendDatabasePath(env: bundledEnv)
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

  private static func backendDatabasePath(env: [String: String]) -> String {
    let baseDir =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    let filename = env["BUNDLED_DB_FILENAME"] ?? "tunify.db"
    return baseDir.appendingPathComponent(filename).path
  }

  private static func ensureParentDirectory(path: String) {
    let parent = URL(fileURLWithPath: path).deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
  }

  private static func loadBundledRuntimeEnv() -> [String: String] {
    guard let envPath = Bundle.main.path(
      forResource: "runtime",
      ofType: "env",
      inDirectory: "Frameworks/App.framework/flutter_assets/assets/bundled_backend"
    ) else {
      return [:]
    }
    guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else {
      return [:]
    }
    var out: [String: String] = [:]
    for line in content.components(separatedBy: .newlines) {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty || trimmed.hasPrefix("#") {
        continue
      }
      guard let idx = trimmed.firstIndex(of: "=") else {
        continue
      }
      let key = String(trimmed[..<idx]).trimmingCharacters(in: .whitespaces)
      let value = String(trimmed[trimmed.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
      if !key.isEmpty {
        out[key] = value
      }
    }
    return out
  }

  private static func applyBundledRuntimeEnv(_ env: [String: String]) {
    let defaults: [String: String] = [
      "APP_RUNTIME_KIND": "bundled",
      "APP_HOST": "127.0.0.1",
      "APP_PORT": "8080",
      "APP_HOME_PROVIDER": "youtube",
      "APP_GATEWAY_ARCH_MODE": "local_youtube",
      "APP_GATEWAY_STATE_PATH": ".gateway_runtime.json"
    ]
    for (key, value) in defaults.merging(env, uniquingKeysWith: { _, new in new }) {
      setenv(key, value, 1)
    }
  }
}
