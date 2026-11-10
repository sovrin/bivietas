import SwiftUI

/// Icon of the app with this bundle ID (or a link glyph when unknown).
struct AppIcon: View {
    let bundleID: String?
    var size: CGFloat = 16

    var body: some View {
        Image(nsImage: AppInfo.icon(bundleID))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .foregroundStyle(.secondary)
    }
}
