import SwiftUI

@main
struct bivietasApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent().environment(delegate.model)
        } label: {
            MenuBarLabel().environment(delegate.model)
        }
        .menuBarExtraStyle(.window)

        Window("bivietas", id: "config") {
            ConfiguratorView().environment(delegate.model)
        }
        .defaultLaunchBehavior(.suppressed)
    }
}
