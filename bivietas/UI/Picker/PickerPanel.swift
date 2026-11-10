import AppKit
import SwiftUI

/// `ProfileChooser` backed by a floating panel near the pointer.
struct PanelProfileChooser: ProfileChooser {
    func choose(host: String, profiles: [Profile], defaultTarget: Target, completion: @escaping (Profile?, Bool) -> Void) {
        PickerPanel.show(host: host, profiles: profiles, defaultTarget: defaultTarget, onPick: completion)
    }
}

/// Floating chooser for unmatched links. Keys: 1…9, Return = default, Esc = dismiss.
final class PickerPanel: NSPanel {
    private static var visible: Set<PickerPanel> = [] // keeps panels alive; several links may be pending
    private let profiles: [Profile]
    private let defaultTarget: Target
    private let state = PickerState()
    private var onPick: ((Profile?, Bool) -> Void)?

    static func show(host: String, profiles: [Profile], defaultTarget: Target, onPick: @escaping (Profile?, Bool) -> Void) {
        let panel = PickerPanel(host: host, profiles: profiles, defaultTarget: defaultTarget, onPick: onPick)
        visible.insert(panel)
        panel.setFrameTopLeftPoint(NSEvent.mouseLocation)
        panel.makeKeyAndOrderFront(nil)
    }

    private init(host: String, profiles: [Profile], defaultTarget: Target, onPick: @escaping (Profile?, Bool) -> Void) {
        self.profiles = profiles
        self.defaultTarget = defaultTarget
        self.onPick = onPick
        super.init(contentRect: .zero, styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
                   backing: .buffered, defer: false)
        title = host
        level = .floating
        isReleasedWhenClosed = false
        let view = NSHostingView(rootView: PickerView(host: host, profiles: profiles, defaultTarget: defaultTarget, state: state) { [weak self] in
            self?.finish($0)
        })
        contentView = view
        setContentSize(view.fittingSize)
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: finish(nil)
        case 36, 76: finish(profiles.first { $0.target == defaultTarget } ?? profiles.first)
        default:
            if let n = Int(event.charactersIgnoringModifiers ?? ""), profiles.indices.contains(n - 1) {
                finish(profiles[n - 1])
            } else {
                super.keyDown(with: event)
            }
        }
    }

    override func cancelOperation(_ sender: Any?) { finish(nil) }
    override func close() { finish(nil) }

    private func finish(_ profile: Profile?) {
        guard let onPick else { return }
        self.onPick = nil
        orderOut(nil)
        Self.visible.remove(self)
        onPick(profile, state.remember)
    }
}

@Observable final class PickerState {
    var remember = false
}
