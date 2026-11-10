import SwiftUI

/// Settings window: sidebar of panes, System Settings style.
struct ConfiguratorView: View {
    @Environment(AppModel.self) private var model
    @State private var pane: Pane? = .rules

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $pane) { pane in
                Label(pane.title, systemImage: pane.symbol)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
            .safeAreaInset(edge: .bottom) { DefaultBrowserCard().padding(10) }
        } detail: {
            switch pane ?? .rules {
            case .rules: RulesPane()
            case .tester: TesterPane()
            case .activity: ActivityPane()
            case .general: GeneralPane()
            }
        }
        .frame(minWidth: 860, minHeight: 540)
        .onAppear {
            model.reloadProfiles()
            // Show in the Dock and ⌘-Tab while settings are open; back to menu-bar-only afterwards.
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
        }
        .onDisappear { NSApp.setActivationPolicy(.accessory) }
    }
}

enum Pane: String, CaseIterable, Identifiable {
    case rules, tester, activity, general
    var id: Self { self }

    var title: String {
        switch self {
        case .rules: "Rules"
        case .tester: "Tester"
        case .activity: "Activity"
        case .general: "General"
        }
    }

    var symbol: String {
        switch self {
        case .rules: "signpost.right.and.left"
        case .tester: "checkmark.seal"
        case .activity: "clock.arrow.circlepath"
        case .general: "gearshape"
        }
    }
}
