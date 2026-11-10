import Foundation

/// One routed link. Kept in memory only; full URLs are never written to disk.
struct LogEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let url: URL
    let source: String?   // bundle ID of the app the link came from
    let rule: String?     // matched rule name, or a note like "(picker)"; nil = fallback
    let target: Target?   // nil = not opened (picker dismissed)
    var destination: URL? // unwrapped target when `url` is a redirect wrapper

    var host: String { (destination ?? url).host() ?? url.lastPathComponent }
}
