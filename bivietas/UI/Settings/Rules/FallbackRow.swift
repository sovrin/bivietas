import SwiftUI

/// The implicit last rule: what happens to links nothing else matched. Fixed in place, so no handle.
struct FallbackRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let asks = model.config.fallback == .picker
        HStack(spacing: 10) {
            Color.clear.frame(width: DragHandle.width + 10 + 36, height: 1) // handle + spacing + mini switch
            Image(systemName: "ellipsis.circle").font(.title3).foregroundStyle(.secondary).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Everything else").fontWeight(.medium)
                Text(asks ? "Ask which profile to use each time" : "Opens in your default profile")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Image(systemName: "arrow.right").font(.caption).foregroundStyle(.tertiary)
            if asks {
                ProfileChip(target: nil, label: "Ask", systemImage: "questionmark")
            } else {
                ProfileChip(target: model.config.defaultTarget)
            }
        }
        .padding(.vertical, 4)
    }
}
