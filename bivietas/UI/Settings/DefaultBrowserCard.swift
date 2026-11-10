import SwiftUI

/// Sidebar footer: quiet when all is well, an actionable warning when it isn't.
struct DefaultBrowserCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.isDefaultBrowser {
            Label("Default browser", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.multicolor)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Label("Not the default browser", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .symbolRenderingMode(.multicolor)
                Button("Make Default") { Task { await model.makeDefaultBrowser() } }
                    .controlSize(.small)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
