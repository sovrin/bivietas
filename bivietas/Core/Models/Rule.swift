import Foundation

struct Rule: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var enabled = true
    var conditions: [Condition] // all must match (AND)
    var target: Target
}

extension Rule {
    /// The rule the picker's "Always use this for <host>" checkbox adds.
    static func remembering(host: String, target: Target) -> Rule {
        Rule(name: host, conditions: [.hostSuffix(host)], target: target)
    }

    private enum LegacyKeys: String, CodingKey { case profileID }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        conditions = try c.decode([Condition].self, forKey: .conditions)
        target = try c.decodeIfPresent(Target.self, forKey: .target)
            ?? .legacy(decoder.container(keyedBy: LegacyKeys.self).decode(String.self, forKey: .profileID))
    }
}
