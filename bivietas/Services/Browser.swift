import Foundation

/// A browser bivietas routes links into. Everything browser-specific lives behind this.
protocol Browser {
    var id: String { get }   // bundle ID
    var name: String { get }
    func profiles() -> [Profile]
    /// Must target the browser explicitly — never the system default browser (that's us).
    func open(_ url: URL, profile: String, onError: @escaping (Error) -> Void)
}
