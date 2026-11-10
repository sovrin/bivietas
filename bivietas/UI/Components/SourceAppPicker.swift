import SwiftUI

/// Pop-up menu of running and installed apps showing icon + name; stores the bundle ID.
struct SourceAppPicker: View {
    @Binding var bundleID: String
    var noneTitle: String?

    var body: some View {
        Menu {
            if let noneTitle {
                Button(noneTitle) { bundleID = "" }
                Divider()
            }
            Section("Running") { ForEach(AppChoice.running) { item($0) } }
            Section("Applications") { ForEach(AppChoice.installed) { item($0) } }
        } label: {
            Label {
                Text(bundleID.isEmpty ? (noneTitle ?? "Choose App…") : AppInfo.name(bundleID))
            } icon: {
                Image(nsImage: bundleID.isEmpty ? NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)! : AppInfo.icon(bundleID))
            }
        }
        .fixedSize()
    }

    private func item(_ app: AppChoice) -> some View {
        Button { bundleID = app.id } label: {
            Label { Text(app.name) } icon: { Image(nsImage: AppInfo.icon(app.id)) }
        }
    }
}
