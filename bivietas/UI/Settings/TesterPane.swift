import SwiftUI

/// Dry-run a link: shows the real destination, matched rule and profile without opening anything.
struct TesterPane: View {
    @Environment(AppModel.self) private var model
    @State var text = ""
    @State var source = ""

    var body: some View {
        Form {
            Section {
                TextField("Link", text: $text, prompt: Text("Paste a link, e.g. a SafeLinks URL from Outlook"))
                LabeledContent("Clicked in") {
                    SourceAppPicker(bundleID: $source, noneTitle: "Any App")
                }
            } footer: {
                Text("Nothing opens until you press Open — this just shows where the link would go.")
                    .foregroundStyle(.secondary)
            }
            if let url = URL(string: text.trimmingCharacters(in: .whitespaces)),
               ["http", "https"].contains(url.scheme?.lowercased()), url.host() != nil {
                result(for: url)
            } else if !text.isEmpty {
                Section {
                    Label("That’s not a web link. Links need to start with http:// or https://.", systemImage: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Tester")
    }

    @ViewBuilder private func result(for url: URL) -> some View {
        let sourceID = source.isEmpty ? nil : source
        let route = model.route(url, source: sourceID)
        Section("Result") {
            if route.destination != url {
                LabeledContent("Real destination") {
                    Text(route.destination.absoluteString)
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .multilineTextAlignment(.trailing)
                }
            }
            switch route.decision {
            case .open(let target, let rule):
                LabeledContent("Matched rule") {
                    Text(rule ?? "None — handled by “Everything else”").foregroundStyle(rule == nil ? .secondary : .primary)
                }
                LabeledContent("Opens in") { ProfileChip(target: target) }
            case .ask:
                LabeledContent("Matched rule") { Text("None — handled by “Everything else”").foregroundStyle(.secondary) }
                LabeledContent("Opens in") { ProfileChip(target: nil, label: "Ask", systemImage: "questionmark") }
            }
        }
        Section {
            Button("Open Link") { model.handle(url, source: sourceID) }
        }
    }
}

#Preview("Tester") {
    TesterPane(text: "https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fgithub.com%2Fapple", source: "com.tinyspeck.slackmacgap")
        .environment(AppModel.preview())
        .frame(width: 640, height: 520)
}
