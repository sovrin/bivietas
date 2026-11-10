import AppKit

/// Bundle ID → display name and icon, cached.
enum AppInfo {
    private static var cache: [String: (name: String, icon: NSImage)] = [:]

    static func name(_ bundleID: String?) -> String {
        guard let bundleID else { return "Unknown source" }
        return info(bundleID)?.name ?? bundleID
    }

    static func isInstalled(_ bundleID: String) -> Bool { info(bundleID) != nil }

    static func icon(_ bundleID: String?) -> NSImage {
        bundleID.flatMap { info($0)?.icon }
            ?? NSImage(systemSymbolName: bundleID == nil ? "link.circle.fill" : "app.dashed", accessibilityDescription: nil)!
    }

    /// Sized copy, for native menus that would otherwise draw the icon at full size.
    static func icon(_ bundleID: String?, size: CGFloat) -> NSImage {
        let image = icon(bundleID).copy() as! NSImage
        image.size = NSSize(width: size, height: size)
        return image
    }

    private static func info(_ bundleID: String) -> (name: String, icon: NSImage)? {
        if let hit = cache[bundleID] { return hit }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let value = (name: url.deletingPathExtension().lastPathComponent, icon: NSWorkspace.shared.icon(forFile: url.path))
        cache[bundleID] = value
        return value
    }
}

/// An app the user can pick as a link source.
struct AppChoice: Identifiable {
    let id: String // bundle ID
    let name: String

    static var running: [AppChoice] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .compactMap { app in app.bundleIdentifier.map { AppChoice(id: $0, name: app.localizedName ?? $0) } }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // Scanned once; /Applications rarely changes while the app runs.
    static let installed: [AppChoice] = {
        let dirs = ["/Applications", "/Applications/Utilities", "/System/Applications", "/System/Applications/Utilities",
                    URL.homeDirectory.appending(path: "Applications").path]
        var seen = Set<String>()
        return dirs.flatMap { dir in
            ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? [])
                .filter { $0.hasSuffix(".app") }
                .compactMap { file -> AppChoice? in
                    let url = URL(fileURLWithPath: dir).appending(path: file)
                    guard let id = Bundle(url: url)?.bundleIdentifier, seen.insert(id).inserted else { return nil }
                    return AppChoice(id: id, name: url.deletingPathExtension().lastPathComponent)
                }
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()
}
