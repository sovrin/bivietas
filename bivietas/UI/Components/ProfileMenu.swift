import SwiftUI

/// Menu items for every profile except `excluding`, grouped by browser when there are several.
struct ProfileMenuItems: View {
    @Environment(AppModel.self) private var model
    var excluding: Target?
    let action: (Target) -> Void

    var body: some View {
        ForEach(model.browsers, id: \.id) { browser in
            let profiles = model.profiles(of: browser).filter { $0.target != excluding }
            if !profiles.isEmpty {
                Section(model.spansBrowsers ? browser.name : "") {
                    ForEach(profiles) { profile in
                        Button(profile.name) { action(profile.target) }
                    }
                }
            }
        }
    }
}
