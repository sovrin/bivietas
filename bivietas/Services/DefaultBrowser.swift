import AppKit

enum DefaultBrowser {
    static var isCurrentApp: Bool {
        let app = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!)
        return app.flatMap { Bundle(url: $0)?.bundleIdentifier } == Bundle.main.bundleIdentifier
    }

    /// macOS asks the user to confirm; https follows http.
    static func makeCurrentApp() async throws {
        try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http")
    }
}
