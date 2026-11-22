import AppKit
import Paritas

/// A link must never be dropped silently: tell the user and offer to copy it.
enum LaunchFailureAlert {
    static func present(url: URL, error: Error) {
        let alert = NSAlert()
        alert.messageText = "Could not open link"
        alert.informativeText = "\(error.localizedDescription)\n\n\(url.absoluteString)"
        alert.addButton(withTitle: "Copy Link")
        alert.addButton(withTitle: "Dismiss")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            Pasteboard.copy(url.absoluteString)
        }
    }
}
