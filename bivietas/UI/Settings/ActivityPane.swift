import SwiftUI

/// Table of routed links (in memory only), with reopen and copy.
struct ActivityPane: View {
    @Environment(AppModel.self) private var model
    @State private var selection = Set<LogEntry.ID>()

    var body: some View {
        Table(model.activity.entries, selection: $selection) {
            TableColumn("Link") { entry in
                HStack(spacing: 8) {
                    AppIcon(bundleID: entry.source)
                    Text(entry.host).lineLimit(1).truncationMode(.middle)
                }
            }
            TableColumn("From") { Text(AppInfo.name($0.source)) }
            TableColumn("Rule") { Text($0.rule ?? "Everything else").foregroundStyle($0.rule == nil ? .secondary : .primary) }
            TableColumn("Profile") { ProfileChip(target: $0.target, label: $0.target == nil ? "Dismissed" : nil) }
                .width(min: 80, ideal: 100)
            TableColumn("Time") { Text($0.date, style: .time).foregroundStyle(.secondary).monospacedDigit() }
                .width(70)
        }
        .contextMenu(forSelectionType: LogEntry.ID.self) { ids in
            let entries = model.activity.entries.filter { ids.contains($0.id) }
            Menu("Open in") {
                ProfileMenuItems { target in entries.forEach { model.reopen($0, in: target) } }
            }
            Divider()
            Button("Copy Link") { Pasteboard.copy(entries.map(\.url.absoluteString).joined(separator: "\n")) }
        }
        .overlay {
            if model.activity.entries.isEmpty {
                ContentUnavailableView("No Activity Yet", systemImage: "clock.arrow.circlepath",
                                       description: Text("Links bivietas routes appear here.\nThey’re kept in memory only and cleared when you quit."))
            }
        }
        .navigationTitle("Activity")
    }
}
