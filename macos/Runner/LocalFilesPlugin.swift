import Cocoa
import FlutterMacOS

/// Native macOS implementation of the `com.kyutefox.tunify/local_files` MethodChannel.
///
/// Provides three methods to Dart:
///
/// • `pickMusicFolder`       — opens NSOpenPanel as a sheet on the Flutter window.
///                             Saves a security-scoped bookmark in UserDefaults so
///                             the folder stays accessible across restarts.
///                             Returns the POSIX path String, or nil if cancelled.
///
/// • `getSavedMusicFolder`   — resolves the saved bookmark and returns the path,
///                             or nil if none saved / bookmark is stale.
///
/// • `clearSavedMusicFolder` — removes the saved bookmark.
///
/// Registered in MainFlutterWindow.swift via
///   LocalFilesPlugin.register(with: flutterViewController)
class LocalFilesPlugin: NSObject, FlutterPlugin {

    // MARK: - Constants

    private static let channelName = "com.kyutefox.tunify/local_files"
    private static let bookmarkKey = "tunify.musicFolderBookmark"

    // MARK: - State

    /// Stored at registration time. We resolve .view.window lazily on first
    /// use because the window is nil during awakeFromNib (not yet shown).
    private weak var flutterViewController: FlutterViewController?

    /// Tracks the currently accessed security-scoped URL so we can call
    /// stopAccessingSecurityScopedResource when the folder is cleared.
    private var accessedURL: URL?

    // MARK: - Registration

    /// Call this from MainFlutterWindow.awakeFromNib, passing the FlutterViewController.
    static func register(with viewController: FlutterViewController) {
        let registrar = viewController.registrar(forPlugin: "LocalFilesPlugin")
        let channel   = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger
        )
        let instance = LocalFilesPlugin()
        // Store the view controller; we'll resolve .view.window lazily on first
        // use so we always get the fully-shown window, not the nil from awakeFromNib.
        instance.flutterViewController = viewController
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// FlutterPlugin conformance — called by the framework when registered via
    /// the standard registrar path (required by the protocol, not used here).
    static func register(with registrar: any FlutterPluginRegistrar) {
        // Intentional no-op: use register(with: FlutterViewController) instead.
    }

    // MARK: - FlutterPlugin

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "pickMusicFolder":
            pickMusicFolder(result: result)

        case "getSavedMusicFolder":
            result(resolveSavedBookmark())

        case "clearSavedMusicFolder":
            accessedURL?.stopAccessingSecurityScopedResource()
            accessedURL = nil
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Pick folder

    private func pickMusicFolder(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { result(nil); return }

            // Resolve the window lazily: the view controller's view.window is
            // guaranteed to be non-nil once the app is running and the user
            // has tapped a button. Fall back to any visible non-panel window.
            let window: NSWindow? =
                self.flutterViewController?.view.window
                ?? NSApp.windows.first(where: { $0.isVisible && !($0 is NSPanel) })

            let panel                     = NSOpenPanel()
            panel.title                   = "Choose Music Folder"
            panel.message                 = "Select the folder that contains your music files."
            panel.prompt                  = "Choose"
            panel.canChooseFiles          = false
            panel.canChooseDirectories    = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories    = false

            NSLog("[LocalFilesPlugin] pickMusicFolder — window=%@",
                  window?.description ?? "nil (will runModal)")

            if let window = window {
                panel.beginSheetModal(for: window) { response in
                    NSLog("[LocalFilesPlugin] sheet response=%ld url=%@",
                          response.rawValue, panel.url?.path ?? "nil")
                    if response == .OK, let url = panel.url {
                        self.saveBookmarkAndReturn(url: url, result: result)
                    } else {
                        result(nil)
                    }
                }
            } else {
                // Absolute last resort — no window found.
                NSLog("[LocalFilesPlugin] no window found, using runModal()")
                let response = panel.runModal()
                NSLog("[LocalFilesPlugin] runModal response=%ld url=%@",
                      response.rawValue, panel.url?.path ?? "nil")
                if response == .OK, let url = panel.url {
                    self.saveBookmarkAndReturn(url: url, result: result)
                } else {
                    result(nil)
                }
            }
        }
    }

    // MARK: - Bookmark helpers

    private func saveBookmarkAndReturn(url: URL, result: @escaping FlutterResult) {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
            NSLog("[LocalFilesPlugin] bookmark saved for %@", url.path)
        } catch {
            NSLog("[LocalFilesPlugin] bookmark creation failed for %@: %@",
                  url.path, error.localizedDescription)
            // Still return the path — works this session even without a bookmark.
        }

        // NSOpenPanel already grants access for this session; start the
        // security-scoped resource so the Dart-side Directory scan can read it.
        accessedURL?.stopAccessingSecurityScopedResource()
        if url.startAccessingSecurityScopedResource() {
            accessedURL = url
        } else {
            accessedURL = nil
            NSLog("[LocalFilesPlugin] startAccessingSecurityScopedResource failed after pick for %@", url.path)
        }

        result(url.path)
    }

    // MARK: - Resolve saved bookmark

    private func resolveSavedBookmark() -> String? {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                if let fresh = try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    UserDefaults.standard.set(fresh, forKey: Self.bookmarkKey)
                    NSLog("[LocalFilesPlugin] stale bookmark refreshed for %@", url.path)
                }
            }

            // Stop any previously accessed resource before starting a new one.
            accessedURL?.stopAccessingSecurityScopedResource()
            accessedURL = nil

            guard url.startAccessingSecurityScopedResource() else {
                NSLog("[LocalFilesPlugin] startAccessingSecurityScopedResource failed for %@", url.path)
                return nil
            }
            accessedURL = url

            NSLog("[LocalFilesPlugin] restored folder access: %@", url.path)
            return url.path

        } catch {
            NSLog("[LocalFilesPlugin] failed to resolve bookmark: %@",
                  error.localizedDescription)
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            return nil
        }
    }
}
