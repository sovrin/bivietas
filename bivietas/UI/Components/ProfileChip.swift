import SwiftUI

/// Capsule tag naming a profile in its color, with the browser's icon once several browsers are in play.
/// `label`/`systemImage` override the text and leading glyph.
struct ProfileChip: View {
    @Environment(AppModel.self) private var model
    let target: Target?
    var label: String?
    var systemImage: String?

    var body: some View {
        let color = model.color(for: target)
        let missing = label == nil && target != nil && !model.hasProfile(target)
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).imageScale(.small)
            } else if let target, model.spansBrowsers {
                AppIcon(bundleID: target.browserID, size: 12)
            } else {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            Text(label ?? model.profileName(target))
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(missing ? Color.orange : Color.primary)
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background(color.opacity(0.18), in: Capsule())
        .fixedSize()
        .help(target.map(model.fullName) ?? "")
    }
}
