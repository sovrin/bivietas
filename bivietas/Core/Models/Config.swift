import Foundation

struct Config: Codable, Equatable {
    var rules: [Rule]
    var defaultTarget: Target
    var fallback: Fallback = .defaultProfile
    var openUnwrapped = false          // false: match on unwrapped URL, but open the original
    var unwrapRules: [UnwrapRule] = [] // user-defined redirect wrappers, on top of the built-in ones
}

/// What happens to links no rule matches.
enum Fallback: String, Codable, CaseIterable {
    case defaultProfile, picker
}

extension Config {
    /// First-run defaults: work chat/mail apps → "Work", everything else → "Private".
    static func seed(profiles: [Profile]) -> Config {
        func target(_ name: String) -> Target {
            profiles.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.target
                ?? profiles.first?.target ?? .legacy("Default")
        }
        let work = target("Work")
        return Config(
            rules: [
                Rule(name: "Slack", conditions: [.sourceApp(bundleID: "com.tinyspeck.slackmacgap")], target: work),
                Rule(name: "Microsoft Outlook", conditions: [.sourceApp(bundleID: "com.microsoft.Outlook")], target: work),
                Rule(name: "Microsoft Teams", conditions: [.sourceApp(bundleID: "com.microsoft.teams2")], target: work),
                Rule(name: "Company domain (edit me)", enabled: false, conditions: [.hostSuffix("example.com")], target: work),
            ],
            defaultTarget: target("Private")
        )
    }

    private enum LegacyKeys: String, CodingKey { case defaultProfileID }

    /// Tolerant decoding: older configs (Vivaldi-only, fewer fields) load instead of being set aside.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rules = try c.decodeIfPresent([Rule].self, forKey: .rules) ?? []
        defaultTarget = try c.decodeIfPresent(Target.self, forKey: .defaultTarget)
            ?? .legacy(decoder.container(keyedBy: LegacyKeys.self).decode(String.self, forKey: .defaultProfileID))
        fallback = try c.decodeIfPresent(Fallback.self, forKey: .fallback) ?? .defaultProfile
        openUnwrapped = try c.decodeIfPresent(Bool.self, forKey: .openUnwrapped) ?? false
        unwrapRules = try c.decodeIfPresent([UnwrapRule].self, forKey: .unwrapRules) ?? []
    }
}
