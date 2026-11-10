import Foundation

/// Where a link opens: one profile of one browser.
struct Target: Codable, Hashable {
    var browserID: String // bundle ID, e.g. "com.vivaldi.Vivaldi"
    var profileID: String // Chromium: profile directory ("Profile 1"); Firefox: profile name

    /// Configs written before multi-browser support only knew Vivaldi.
    static func legacy(_ profileID: String) -> Target {
        Target(browserID: "com.vivaldi.Vivaldi", profileID: profileID)
    }
}
