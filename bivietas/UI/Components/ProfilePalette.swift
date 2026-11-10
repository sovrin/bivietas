import AppKit
import SwiftUI

/// Stable per-profile color by profile order; the first two match the app icon's boards.
enum ProfilePalette {
    static let colors: [Color] = [
        Color(red: 0.23, green: 0.55, blue: 0.87), Color(red: 0.93, green: 0.35, blue: 0.27),
        .green, .purple, .yellow, .pink,
    ]

    static func color(for target: Target?, in profiles: [Profile]) -> Color {
        guard let target, let index = profiles.firstIndex(where: { $0.target == target }) else { return .gray }
        return colors[index % colors.count]
    }

    /// Colored dot as a non-template NSImage, so it keeps its color inside native menus.
    static func dot(_ color: Color, size: CGFloat = 8) -> NSImage {
        let nsColor = NSColor(color)
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            nsColor.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
            return true
        }
    }
}

extension AppModel {
    func color(for target: Target?) -> Color { ProfilePalette.color(for: target, in: profiles) }
}
