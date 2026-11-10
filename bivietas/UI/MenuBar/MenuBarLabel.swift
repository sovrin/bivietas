import SwiftUI

/// Menu bar icon: a hollow signpost while routing is paused.
struct MenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Image(model.paused ? "MenuBarIconPaused" : "MenuBarIcon")
            .accessibilityLabel(model.paused ? "bivietas, paused" : "bivietas")
    }
}
