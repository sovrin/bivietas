import SwiftUI

/// Picks a target: every profile of every installed browser, grouped by browser.
struct ProfilePicker: View {
    @Environment(AppModel.self) private var model
    let title: String
    @Binding var selection: Target

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(model.browsers, id: \.id) { browser in
                let profiles = model.profiles(of: browser)
                if !profiles.isEmpty {
                    Section(browser.name) {
                        ForEach(profiles) { profile in
                            // Browser icon when several browsers are in play, so a closed picker isn't ambiguous.
                            Label { Text(profile.name) } icon: {
                                Image(nsImage: model.spansBrowsers ? AppInfo.icon(browser.id, size: 16) : ProfilePalette.dot(model.color(for: profile.target)))
                            }
                            .tag(profile.target)
                        }
                    }
                }
            }
            if !model.hasProfile(selection) {
                Text("Missing: \(selection.profileID) (\(model.browserName(selection.browserID)))").tag(selection)
            }
        }
    }
}
