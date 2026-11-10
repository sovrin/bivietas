import SwiftUI

/// Grip shown on reorderable rows; the whole row drags, the grip makes that discoverable.
struct DragHandle: View {
    static let width: CGFloat = 16

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.callout.weight(.medium))
            .foregroundStyle(.tertiary)
            .frame(width: Self.width, height: 22)
            .contentShape(Rectangle())
            .pointerStyle(.grabIdle)
            .help("Drag to reorder")
            .accessibilityHidden(true)
    }
}
