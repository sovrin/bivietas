import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    // WillFinish, not DidFinish: the link that cold-launched us arrives in between.
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleGetURL(_:reply:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: string) else { return }
        let pid = event.attributeDescriptor(forKeyword: keySenderPIDAttr)?.int32Value
        let source = pid.flatMap { NSRunningApplication(processIdentifier: $0)?.bundleIdentifier }
        model.handle(url, source: source)
    }

    // .html files opened from Finder; also catches web URLs should the Apple Event handler ever be bypassed.
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { model.handle($0, source: nil) }
    }
}
