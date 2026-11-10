import AppKit
import Observation

/// App state and coordination. Decisions live in `RoutingPolicy`; side effects in the injected services.
@Observable final class AppModel {
    var config: Config {
        didSet { if config != oldValue { save() } }
    }
    var profiles: [Profile] // of every installed browser, in catalog order
    var activity = ActivityLog()
    var paused = false
    var saveError: String?
    private(set) var isDefaultBrowser = false

    let browsers: [any Browser] // installed ones
    private let store: ConfigStore
    private let chooser: any ProfileChooser
    private let reportFailure: @MainActor (URL, Error) -> Void

    init(store: ConfigStore = ConfigStore(),
         browsers: [any Browser] = BrowserCatalog.installed,
         chooser: any ProfileChooser = PanelProfileChooser(),
         reportFailure: (@MainActor (URL, Error) -> Void)? = nil) {
        self.store = store
        self.browsers = browsers
        self.chooser = chooser
        // Defaulted here, not in the signature: default arguments are evaluated off the main actor.
        self.reportFailure = reportFailure ?? { LaunchFailureAlert.present(url: $0, error: $1) }
        let profiles = browsers.flatMap { $0.profiles() }
        self.profiles = profiles
        do {
            config = try store.load() ?? .seed(profiles: profiles)
        } catch {
            store.backUpUnreadable()
            config = .seed(profiles: profiles)
        }
        save()
        store.watch { [weak self] in
            guard let self, let disk = try? store.load(), disk != config else { return }
            config = disk
        }
        refreshDefaultBrowser()
        // The menu panel and settings window become key when shown: a cheap moment to re-check status.
        NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshDefaultBrowser() }
        }
    }

    // MARK: Routing

    func route(_ url: URL, source: String?) -> Route {
        RoutingPolicy.route(url, source: source, config: config, paused: paused, canAsk: !profiles.isEmpty)
    }

    func handle(_ url: URL, source: String?) {
        guard RoutingPolicy.accepts(url) else { return }
        let route = route(url, source: source)
        switch route.decision {
        case .open(let target, let rule):
            open(route.target, in: target, source: source, rule: rule, destination: route.destination)
        case .ask:
            chooser.choose(host: route.destination.host() ?? "", profiles: profiles, defaultTarget: config.defaultTarget) { [self] picked, remember in
                guard let picked else {
                    return activity.record(LogEntry(url: route.target, source: source, rule: "(picker dismissed)",
                                                    target: nil, destination: route.destination))
                }
                if remember, let host = route.destination.host() {
                    config.rules.append(.remembering(host: host, target: picked.target))
                }
                open(route.target, in: picked.target, source: source, rule: "(picker)", destination: route.destination)
            }
        }
    }

    func open(_ url: URL, in target: Target, source: String? = nil, rule: String? = nil, destination: URL? = nil) {
        let target = RoutingPolicy.safeTarget(target, known: profiles, fallback: config.defaultTarget)
        activity.record(LogEntry(url: url, source: source, rule: rule, target: target, destination: destination))
        guard let app = browser(target.browserID) else {
            return reportFailure(url, AppLauncher.NotInstalled(name: browserName(target.browserID)))
        }
        app.open(url, profile: target.profileID) { [reportFailure] error in
            reportFailure(url, error)
        }
    }

    func reopen(_ entry: LogEntry, in target: Target) {
        open(entry.url, in: target, source: entry.source, rule: "(reopened)", destination: entry.destination)
    }

    // MARK: Profiles

    func reloadProfiles() { profiles = browsers.flatMap { $0.profiles() } }

    func profiles(of browser: any Browser) -> [Profile] { profiles.filter { $0.browserID == browser.id } }

    func hasProfile(_ target: Target?) -> Bool { profiles.contains { $0.target == target } }

    func profileName(_ target: Target?) -> String {
        guard let target else { return "—" }
        return profiles.first { $0.target == target }?.name ?? "⚠︎ \(target.profileID)"
    }

    /// "Private (Vivaldi)" — for menus that mix browsers.
    func fullName(_ target: Target) -> String { "\(profileName(target)) (\(browserName(target.browserID)))" }

    // MARK: Browsers

    func browser(_ id: String) -> (any Browser)? { browsers.first { $0.id == id } }

    func browserName(_ id: String) -> String {
        browser(id)?.name ?? BrowserCatalog.all.first { $0.id == id }?.name ?? AppInfo.name(id)
    }

    /// Browser icons on profile tags only help once profiles come from more than one browser.
    var spansBrowsers: Bool { Set(profiles.map(\.browserID)).count > 1 }

    // MARK: System

    var configFileURL: URL { store.url }

    func refreshDefaultBrowser() {
        let value = DefaultBrowser.isCurrentApp
        if value != isDefaultBrowser { isDefaultBrowser = value }
    }

    func makeDefaultBrowser() async {
        do { try await DefaultBrowser.makeCurrentApp() }
        catch { saveError = "Could not set default browser: \(error.localizedDescription)" }
        refreshDefaultBrowser()
    }

    private func save() {
        do { try store.save(config); saveError = nil }
        catch { saveError = "Could not save config: \(error.localizedDescription)" }
    }
}

// Not behind #if DEBUG: #Preview bodies are compiled in Release (Archive) too, and would fail without it.
extension AppModel {
    /// Previews use a throwaway config file so they never touch the real one.
    static func preview() -> AppModel {
        AppModel(store: ConfigStore(url: FileManager.default.temporaryDirectory.appending(path: "bivietas-preview/config.json")))
    }
}
