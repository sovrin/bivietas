import SwiftUI

struct GeneralPane: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Default Browser") {
                HStack(spacing: 10) {
                    Image(systemName: model.isDefaultBrowser ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(model.isDefaultBrowser ? "bivietas is your default browser" : "bivietas isn’t your default browser")
                        Text(model.isDefaultBrowser ? "Links from every app are routed by your rules." : "Until it is, links bypass your rules.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !model.isDefaultBrowser {
                        Button("Make Default") { Task { await model.makeDefaultBrowser() } }
                    }
                }
            }

            Section {
                ProfilePicker(title: "Default profile", selection: $model.config.defaultTarget)
                Picker("Links that match no rule", selection: $model.config.fallback) {
                    Text("Open in default profile").tag(Fallback.defaultProfile)
                    Text("Ask each time").tag(Fallback.picker)
                }
                Toggle("Pause routing", isOn: $model.paused)
            } header: {
                Text("Routing")
            } footer: {
                Text(model.config.fallback == .picker
                     ? "A small chooser appears by the pointer. Press 1–\(min(max(model.profiles.count, 1), 9)) to pick, Return for the default profile, Esc to cancel."
                     : "Pausing sends every link to the default profile until you resume.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Open the real destination", isOn: $model.config.openUnwrapped)
            } header: {
                Text("Redirect Links")
            } footer: {
                Text("Rules always match the real destination inside Outlook SafeLinks, Google and Slack redirects. Turn this on to also skip the redirect when opening — sign-in flows that rely on it may break.")
                    .foregroundStyle(.secondary)
            }

            Section {
                if model.browsers.isEmpty {
                    Text("No supported browser found.").foregroundStyle(.orange)
                }
                ForEach(model.browsers, id: \.id) { browser in
                    let profiles = model.profiles(of: browser)
                    LabeledContent {
                        if profiles.isEmpty {
                            Text("Open \(browser.name) once to create a profile").foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 4) { ForEach(profiles) { ProfileChip(target: $0.target) } }
                        }
                    } label: {
                        Label { Text(browser.name) } icon: { AppIcon(bundleID: browser.id, size: 18) }
                    }
                }
            } header: {
                Text("Browsers")
            } footer: {
                Text("Installed Chromium browsers (Vivaldi, Chrome, Brave, Edge) and Firefox appear here. Safari can’t open links in a chosen profile, so it isn’t supported.")
                    .foregroundStyle(.secondary)
            }

            Section("System") {
                Toggle("Open at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        do { try LoginItem.setEnabled(on) }
                        catch {
                            model.saveError = error.localizedDescription
                            launchAtLogin = LoginItem.isEnabled
                        }
                    }
                LabeledContent("Rules file") {
                    Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([model.configFileURL]) }
                }
            }

            if let error = model.saveError {
                Section {
                    Label(error, systemImage: "xmark.octagon.fill")
                        .symbolRenderingMode(.multicolor)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

#Preview("General") {
    GeneralPane()
        .environment(AppModel.preview())
        .frame(width: 640, height: 760)
}
