import Foundation

/// Vivaldi, Chrome, Brave, Edge, …: profiles come from `Local State`, links open via `--profile-directory`.
struct ChromiumBrowser: Browser {
    let id: String
    let name: String
    let localState: URL

    func profiles() -> [Profile] {
        ChromiumProfiles.load(from: localState, browserID: id)
    }

    func open(_ url: URL, profile: String, onError: @escaping (Error) -> Void) {
        AppLauncher.open(bundleID: id, name: name, arguments: ["--profile-directory=\(profile)", url.absoluteString], onError: onError)
    }
}
