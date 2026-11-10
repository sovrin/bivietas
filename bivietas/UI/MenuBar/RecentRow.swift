import SwiftUI

/// One recent link: source app, host, when, and the profile it went to.
/// Hovering swaps the profile tag for "reopen elsewhere": a direct button with one alternative, a menu with several.
struct RecentRow: View {
    @Environment(AppModel.self) private var model
    let entry: LogEntry
    @State private var hovering = false

    var body: some View {
        let others = model.profiles.filter { $0.target != entry.target }
        HStack(spacing: 9) {
            AppIcon(bundleID: entry.source, size: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.host)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(AppInfo.name(entry.source)) · \(entry.date.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if hovering && !others.isEmpty {
                reopen(others).transition(.opacity)
            } else {
                ProfileChip(target: entry.target, label: entry.target == nil ? "Dismissed" : nil)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.07 : 0)))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
        .contextMenu {
            Menu("Open in") {
                ProfileMenuItems(excluding: entry.target) { model.reopen(entry, in: $0) }
            }
            Button("Copy Link") { Pasteboard.copy(entry.url.absoluteString) }
        }
    }

    @ViewBuilder private func reopen(_ others: [Profile]) -> some View {
        if others.count == 1, let only = others.first {
            Button { model.reopen(entry, in: only.target) } label: {
                ProfileChip(target: only.target, systemImage: "arrow.uturn.right")
            }
            .buttonStyle(.plain)
            .help("Open again in \(model.fullName(only.target))")
        } else {
            Menu {
                ProfileMenuItems(excluding: entry.target) { model.reopen(entry, in: $0) }
            } label: {
                ProfileChip(target: nil, label: "Reopen in…", systemImage: "arrow.uturn.right")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }
}
