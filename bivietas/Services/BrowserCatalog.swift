import AppKit

/// Every browser bivietas knows how to drive. Adding a Chromium or Firefox fork is one line.
/// Not here: Safari (no way to open a link in a given profile), Arc (ignores --profile-directory).
enum BrowserCatalog {
    private static let support = URL.homeDirectory.appending(path: "Library/Application Support")

    static let all: [any Browser] = [
        chromium("com.vivaldi.Vivaldi", "Vivaldi", "Vivaldi"),
        chromium("com.google.Chrome", "Google Chrome", "Google/Chrome"),
        chromium("com.brave.Browser", "Brave", "BraveSoftware/Brave-Browser"),
        chromium("com.microsoft.edgemac", "Microsoft Edge", "Microsoft Edge"),
        chromium("org.chromium.Chromium", "Chromium", "Chromium"),
        FirefoxBrowser(id: "org.mozilla.firefox", name: "Firefox", profilesIni: support.appending(path: "Firefox/profiles.ini")),
    ]

    static var installed: [any Browser] {
        all.filter { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.id) != nil }
    }

    private static func chromium(_ id: String, _ name: String, _ dataDir: String) -> ChromiumBrowser {
        ChromiumBrowser(id: id, name: name, localState: support.appending(path: "\(dataDir)/Local State"))
    }
}
