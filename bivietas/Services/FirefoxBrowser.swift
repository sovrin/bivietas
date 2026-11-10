import Foundation

/// Firefox and its forks: profiles come from `profiles.ini`, links open via `-P <name>`.
struct FirefoxBrowser: Browser {
    let id: String
    let name: String
    let profilesIni: URL

    func profiles() -> [Profile] {
        FirefoxProfiles.load(from: profilesIni, browserID: id)
    }

    func open(_ url: URL, profile: String, onError: @escaping (Error) -> Void) {
        AppLauncher.open(bundleID: id, name: name, arguments: ["-P", profile, url.absoluteString], onError: onError)
    }
}
