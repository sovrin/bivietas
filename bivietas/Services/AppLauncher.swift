import AppKit

/// Starts an app with command-line arguments, whether or not it is already running.
enum AppLauncher {
    struct NotInstalled: LocalizedError {
        let name: String
        var errorDescription: String? { "\(name) isn’t installed." }
    }

    static func open(bundleID: String, name: String, arguments: [String], onError: @escaping (Error) -> Void) {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
              let executable = Bundle(url: app)?.executableURL else {
            return onError(NotInstalled(name: name))
        }
        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            // Browsers forward these args to their running instance; openApplication would ignore them.
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments
            do { try process.run() } catch { return onError(error) }
            running.activate()
        } else {
            // Not running: let LaunchServices start it (with args) instead of making it our child process.
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = arguments
            NSWorkspace.shared.openApplication(at: app, configuration: configuration) { _, error in
                if let error { DispatchQueue.main.async { onError(error) } }
            }
        }
    }
}
