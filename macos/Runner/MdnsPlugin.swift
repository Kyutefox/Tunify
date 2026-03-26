import Cocoa
import FlutterMacOS

/// Native implementation of the `chromecast_dlna_finder/mdns` MethodChannel.
///
/// `chromecast_dlna_finder` v1.5.1 has no bundled macOS/iOS native plugin.
/// Its `AppleMdnsDiscoveryImpl` calls `MethodChannel('chromecast_dlna_finder/mdns')`
/// with method `browse` on Apple platforms, expecting a JSON-encoded list of
/// discovered devices back. Without this implementation the call throws
/// `MissingPluginException(No implementation found for method browse on
/// channel chromecast_dlna_finder/mdns)`.
///
/// This plugin satisfies that contract using `NetServiceBrowser` (Bonjour).
/// It is registered in `MainFlutterWindow.swift`.
class MdnsPlugin: NSObject, FlutterPlugin {

    // MARK: - Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "chromecast_dlna_finder/mdns",
            binaryMessenger: registrar.messenger
        )
        let instance = MdnsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - FlutterPlugin

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "browse":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected a Map argument with 'types' and 'timeoutMs'",
                    details: nil
                ))
                return
            }
            let types      = args["types"]     as? [String] ?? MdnsBrowser.defaultTypes
            let timeoutMs  = args["timeoutMs"] as? Int      ?? 5000
            let timeout    = TimeInterval(timeoutMs) / 1000.0

            MdnsBrowser.browse(types: types, timeout: timeout) { devices in
                do {
                    let data  = try JSONSerialization.data(withJSONObject: devices)
                    let json  = String(data: data, encoding: .utf8) ?? "[]"
                    result(json)
                } catch {
                    result(FlutterError(
                        code: "SERIALIZATION_ERROR",
                        message: "Failed to serialise discovered devices: \(error)",
                        details: nil
                    ))
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - MdnsBrowser

/// Runs one or more `NetServiceBrowser` instances in parallel (one per service
/// type) and aggregates all discovered `NetService` entries within `timeout`
/// seconds into a single JSON-ready list that mirrors the shape expected by
/// `AppleMdnsDiscoveryImpl._toDiscoveredDevice`:
///
/// ```json
/// [
///   { "name": "Living Room TV", "host": "192.168.1.5", "port": 8009, "type": "_googlecast._tcp" },
///   ...
/// ]
/// ```
private class MdnsBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {

    static let defaultTypes: [String] = [
        "_googlecast._tcp",
        "_airplay._tcp",
        "_raop._tcp",
        "_chromecast._tcp",
        "_http._tcp",
    ]

    // MARK: State

    private var browsers:         [NetServiceBrowser] = []
    private var pendingServices:  [NetService] = []
    private var resolvedDevices:  [[String: Any]] = []
    private var completion:       (([[String: Any]]) -> Void)?
    private var timer:            Timer?
    private var remainingTypes:   Int = 0
    private var lock =            NSLock()

    // MARK: Public entry point

    /// Browses for every service type in `types` simultaneously and calls
    /// `completion` exactly once after `timeout` seconds (or earlier if all
    /// browsers have stopped and all pending resolves have finished).
    static func browse(
        types: [String],
        timeout: TimeInterval,
        completion: @escaping ([[String: Any]]) -> Void
    ) {
        guard !types.isEmpty else {
            completion([])
            return
        }
        let browser = MdnsBrowser()
        browser.start(types: types, timeout: timeout, completion: completion)
        // Retain the browser until it calls finish() on itself.
        objc_setAssociatedObject(
            browser, &AssociatedKey.retained, browser,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: Private

    private func start(
        types: [String],
        timeout: TimeInterval,
        completion: @escaping ([[String: Any]]) -> Void
    ) {
        self.completion   = completion
        self.remainingTypes = types.count

        for type in types {
            let b = NetServiceBrowser()
            b.delegate = self
            browsers.append(b)
            // NetServiceBrowser must run on a run loop that is pumped.
            // The main run loop is always available on macOS.
            b.searchForServices(ofType: type, inDomain: "local.")
        }

        timer = Timer.scheduledTimer(
            withTimeInterval: timeout,
            repeats: false
        ) { [weak self] _ in
            self?.finish()
        }
    }

    private func finish() {
        lock.lock()
        defer { lock.unlock() }

        guard completion != nil else { return }   // already finished

        timer?.invalidate()
        timer = nil

        for b in browsers { b.stop() }
        browsers.removeAll()

        // Stop any in-flight resolves.
        for svc in pendingServices { svc.stop() }
        pendingServices.removeAll()

        let devices = resolvedDevices
        let cb = completion
        completion = nil

        DispatchQueue.main.async {
            cb?(devices)
        }

        // Release the self-retain so ARC can collect us.
        objc_setAssociatedObject(
            self, &AssociatedKey.retained, nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: - NetServiceBrowserDelegate

    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        lock.lock()
        pendingServices.append(service)
        lock.unlock()

        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        lock.lock()
        remainingTypes -= 1
        let done = remainingTypes <= 0 && pendingServices.isEmpty
        lock.unlock()

        if done { finish() }
    }

    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String: NSNumber]
    ) {
        lock.lock()
        remainingTypes -= 1
        let done = remainingTypes <= 0 && pendingServices.isEmpty
        lock.unlock()

        if done { finish() }
    }

    // MARK: - NetServiceDelegate

    func netServiceDidResolveAddress(_ service: NetService) {
        let host = resolvedHost(from: service)
        let port = service.port
        let name = service.name
        let type = service.type
            .replacingOccurrences(of: ".local.", with: "")
            .replacingOccurrences(of: "local.", with: "")

        let entry: [String: Any] = [
            "name": name,
            "host": host ?? service.hostName ?? "",
            "port": port > 0 ? port : 0,
            "type": type,
        ]

        lock.lock()
        resolvedDevices.append(entry)
        pendingServices.removeAll { $0 === service }
        let browsersGone = remainingTypes <= 0
        let pending      = pendingServices.count
        lock.unlock()

        service.stop()
        if browsersGone && pending == 0 { finish() }
    }

    func netService(_ service: NetService, didNotResolve errorDict: [String: NSNumber]) {
        lock.lock()
        pendingServices.removeAll { $0 === service }
        let browsersGone = remainingTypes <= 0
        let pending      = pendingServices.count
        lock.unlock()

        service.stop()
        if browsersGone && pending == 0 { finish() }
    }

    // MARK: - Helpers

    /// Extracts the first IPv4 address from `service.addresses`.
    private func resolvedHost(from service: NetService) -> String? {
        guard let addresses = service.addresses else { return nil }
        for data in addresses {
            var storage = sockaddr_storage()
            (data as NSData).getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)

            if storage.ss_family == UInt8(AF_INET) {
                var addr4 = withUnsafeBytes(of: storage) { ptr in
                    ptr.load(as: sockaddr_in.self)
                }
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                inet_ntop(AF_INET, &addr4.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN))
                return String(cString: buffer)
            }
        }
        // Fall back to IPv6 if no IPv4 address was found.
        for data in addresses {
            var storage = sockaddr_storage()
            (data as NSData).getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)

            if storage.ss_family == UInt8(AF_INET6) {
                var addr6 = withUnsafeBytes(of: storage) { ptr in
                    ptr.load(as: sockaddr_in6.self)
                }
                var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                inet_ntop(AF_INET6, &addr6.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN))
                return String(cString: buffer)
            }
        }
        return nil
    }
}

// MARK: - Associated object key

private enum AssociatedKey {
    static var retained: UInt8 = 0
}
