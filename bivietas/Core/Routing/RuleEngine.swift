import Foundation

enum RuleEngine {
    /// Ordered rules, first match wins. A rule without conditions never matches,
    /// so a freshly added blank rule can't swallow every link.
    static func firstMatch(_ url: URL, source: String?, rules: [Rule]) -> Rule? {
        rules.first { rule in
            rule.enabled && !rule.conditions.isEmpty && rule.conditions.allSatisfy { $0.matches(url, source: source) }
        }
    }

    /// First match of `pattern` in `text`; nil if it doesn't match or isn't a valid regex.
    /// An empty pattern never matches (it would otherwise match every link).
    static func regexMatch(_ pattern: String, in text: String) -> Range<String.Index>? {
        guard !pattern.isEmpty, let regex = try? Regex(pattern) else { return nil }
        return text.firstMatch(of: regex)?.range
    }
}

extension Condition {
    func matches(_ url: URL, source: String?) -> Bool {
        let host = url.host()?.lowercased() ?? ""
        switch self {
        case .hostEquals(let h):
            return !host.isEmpty && host == h.trimmingCharacters(in: .whitespaces).lowercased()
        case .hostSuffix(let s):
            return hostHasSuffix(host, s)
        case .urlRegex(let pattern):
            return RuleEngine.regexMatch(pattern, in: url.absoluteString) != nil
        case .sourceApp(let bundleID):
            return source?.caseInsensitiveCompare(bundleID) == .orderedSame
        }
    }
}

/// Case-insensitive suffix match on label boundaries: "example.com" matches
/// "example.com" and "a.example.com", but not "badexample.com".
func hostHasSuffix(_ host: String, _ suffix: String) -> Bool {
    let host = host.lowercased()
    var s = suffix.trimmingCharacters(in: .whitespaces).lowercased()
    while s.hasPrefix(".") { s.removeFirst() }
    return !s.isEmpty && (host == s || host.hasSuffix("." + s))
}
