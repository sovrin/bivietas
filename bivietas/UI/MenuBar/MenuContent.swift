import SwiftUI

/// Menu bar panel (MenuBarExtra .window style).
struct MenuContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)
            if !model.isDefaultBrowser {
                defaultBrowserWarning
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
            Divider().padding(.horizontal, 10)
            recent
            Divider().padding(.horizontal, 10)
            footer.padding(5)
        }
        .frame(width: 340)
    }

    // MARK: Header

    private var header: some View {
        @Bindable var model = model
        return HStack(spacing: 10) {
            Image(.logo)
                .resizable()
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("bivietas").font(.headline)
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 8)
            Toggle("Routing", isOn: Binding(get: { !model.paused }, set: { model.paused = !$0 }))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .help(model.paused ? "Resume routing" : "Pause routing — send every link to the default profile")
        }
        .animation(.smooth(duration: 0.2), value: model.paused)
    }

    private var status: String {
        let fallback = model.profileName(model.config.defaultTarget)
        if model.paused { return "Paused · everything opens in \(fallback)" }
        let count = model.config.rules.filter(\.enabled).count
        return "\(count) active \(count == 1 ? "rule" : "rules") · otherwise \(model.config.fallback == .picker ? "ask" : fallback)"
    }

    private var defaultBrowserWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 0) {
                Text("Not the default browser").font(.callout.weight(.medium))
                Text("Links won’t reach bivietas yet.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button("Make Default") { Task { await model.makeDefaultBrowser() } }
                .controlSize(.small)
        }
        .padding(8)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: Recent

    private var recent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 4)
            if model.activity.entries.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "link").font(.title3).foregroundStyle(.tertiary)
                    Text("No links yet").font(.callout).foregroundStyle(.secondary)
                    Text("Links you click in other apps show up here.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                ForEach(model.activity.entries.prefix(8)) { RecentRow(entry: $0) }
                    .padding(.horizontal, 5)
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            footerButton("Settings…", systemImage: "gearshape", shortcut: "⌘,") {
                NSApp.activate()
                openWindow(id: "config")
            }
            .keyboardShortcut(",")
            footerButton("Quit bivietas", systemImage: "power", shortcut: "⌘Q") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    private func footerButton(_ title: String, systemImage: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Text(shortcut).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(HoverButtonStyle())
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
