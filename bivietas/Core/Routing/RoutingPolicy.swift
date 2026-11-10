import Foundation

/// Where a link should go, decided without side effects.
struct Route: Equatable {
    enum Decision: Equatable {
        case open(Target, rule: String?) // rule nil = fallback to the default profile
        case ask
    }

    let target: URL      // what gets opened (original, or unwrapped if configured)
    let destination: URL // the unwrapped URL the rules were matched against
    let decision: Decision
}

enum RoutingPolicy {
    static func accepts(_ url: URL) -> Bool {
        ["http", "https", "file"].contains(url.scheme?.lowercased())
    }

    /// `canAsk` is false when no profiles are known, so the picker would have nothing to offer.
    static func route(_ url: URL, source: String?, config: Config, paused: Bool, canAsk: Bool) -> Route {
        if url.isFileURL || paused {
            let rule = paused ? "(paused)" : nil
            return Route(target: url, destination: url, decision: .open(config.defaultTarget, rule: rule))
        }
        let destination = URLUnwrapper.unwrap(url, extra: config.unwrapRules)
        let decision: Route.Decision =
            if let rule = RuleEngine.firstMatch(destination, source: source, rules: config.rules) {
                .open(rule.target, rule: rule.name)
            } else if config.fallback == .picker && canAsk {
                .ask
            } else {
                .open(config.defaultTarget, rule: nil)
            }
        return Route(target: config.openUnwrapped ? destination : url, destination: destination, decision: decision)
    }

    /// An unknown profile makes browsers create one (Chromium) or show a profile manager (Firefox),
    /// so a target that no longer exists falls back. If nothing is known about its browser, trust it.
    static func safeTarget(_ target: Target, known: [Profile], fallback: Target) -> Target {
        let ofBrowser = known.filter { $0.browserID == target.browserID }
        return ofBrowser.isEmpty || ofBrowser.contains { $0.target == target } ? target : fallback
    }
}
