import Paritas
import SwiftUI

/// Menu bar panel, built from the shared Paritas components.
struct MenuContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model
        MenuPanel {
            // Navy like the app icon's background.
            PanelHeader("bivietas", status: status, icon: Image("MenuBarIcon"),
                        colors: [Color(red: 0.27, green: 0.33, blue: 0.55), Color(red: 0.11, green: 0.14, blue: 0.27)]) {
                Toggle("Routing", isOn: Binding(get: { !model.paused }, set: { model.paused = !$0 }))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                    .help(model.paused ? "Resume routing" : "Pause routing — send every link to the default profile")
            }
            if !model.isDefaultBrowser {
                WarningCard("Not the default browser", message: "Links won’t reach bivietas yet.") {
                    Button("Make Default") { Task { await model.makeDefaultBrowser() } }
                }
            }
            PanelDivider()
            PanelSection("Recent") {
                if model.activity.entries.isEmpty {
                    EmptyState("No links yet", systemImage: "link",
                               hint: Text("Links you click in other apps show up here."))
                } else {
                    ForEach(model.activity.entries.prefix(8)) { RecentRow(entry: $0) }
                        .padding(.horizontal, PanelMetrics.rowInset)
                }
            }
            PanelDivider()
            PanelFooter(appName: "bivietas", showsLaunchAtLogin: false) { openWindow(id: "config") }
        }
    }

    private var status: String {
        let fallback = model.profileName(model.config.defaultTarget)
        if model.paused { return "Paused · everything opens in \(fallback)" }
        let count = model.config.rules.filter(\.enabled).count
        return "\(count) active \(count == 1 ? "rule" : "rules") · otherwise \(model.config.fallback == .picker ? "ask" : fallback)"
    }
}

#Preview("Menu panel") {
    let model = AppModel.preview()
    let first = model.profiles.first?.target, last = model.profiles.last?.target
    model.activity.record(LogEntry(url: URL(string: "https://wiki.example.com/onboarding")!, source: "com.apple.mail", rule: nil, target: nil))
    model.activity.record(LogEntry(url: URL(string: "https://www.google.com/url?q=https%3A%2F%2Fnews.ycombinator.com")!, source: nil, rule: nil,
                                   target: last, destination: URL(string: "https://news.ycombinator.com")))
    model.activity.record(LogEntry(url: URL(string: "https://github.com/apple/swift")!, source: "com.tinyspeck.slackmacgap", rule: "Slack", target: first))
    return MenuContent().environment(model)
}
