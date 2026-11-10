import SwiftUI

/// Content of `PickerPanel`: numbered profiles plus "always use this" for the host.
struct PickerView: View {
    let host: String
    let profiles: [Profile]
    let defaultTarget: Target
    @Bindable var state: PickerState
    let pick: (Profile) -> Void

    private var spansBrowsers: Bool { Set(profiles.map(\.browserID)).count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Open link in…")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
            ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                Button { pick(profile) } label: {
                    HStack(spacing: 8) {
                        Circle().fill(ProfilePalette.color(for: profile.target, in: profiles)).frame(width: 8, height: 8)
                        if spansBrowsers { AppIcon(bundleID: profile.browserID, size: 14) }
                        Text(profile.name)
                        Spacer()
                        if profile.target == defaultTarget { Image(systemName: "return").foregroundStyle(.tertiary) }
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .buttonStyle(HoverButtonStyle())
            }
            Divider().padding(.vertical, 4)
            Toggle("Always use this for \(host)", isOn: $state.remember)
                .font(.caption)
                .padding(.horizontal, 8)
        }
        .padding(8)
        .frame(width: 280)
    }
}

#Preview("Picker") {
    PickerView(host: "news.ycombinator.com",
               profiles: [Profile(target: .legacy("Default"), name: "Work"), Profile(target: .legacy("Profile 1"), name: "Private"),
                          Profile(target: Target(browserID: "com.google.Chrome", profileID: "Profile 1"), name: "Private")],
               defaultTarget: .legacy("Profile 1"), state: PickerState()) { _ in }
}
