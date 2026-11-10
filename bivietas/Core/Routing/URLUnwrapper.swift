import Foundation

/// A redirect wrapper: links on `host` (or a subdomain) carry the real URL in query `param`.
struct UnwrapRule: Codable, Equatable {
    var host: String
    var param: String
    var path: String? = nil
}

enum URLUnwrapper {
    static let builtIn = [
        UnwrapRule(host: "safelinks.protection.outlook.com", param: "url"),
        UnwrapRule(host: "google.com", param: "q", path: "/url"),
        UnwrapRule(host: "google.com", param: "url", path: "/url"),
        UnwrapRule(host: "slack-redir.net", param: "url", path: "/link"),
    ]

    static func unwrap(_ url: URL, extra: [UnwrapRule] = []) -> URL {
        var current = url
        for _ in 0..<3 {
            guard let next = unwrapOnce(current, rules: builtIn + extra) else { break }
            current = next
        }
        return current
    }

    private static func unwrapOnce(_ url: URL, rules: [UnwrapRule]) -> URL? {
        guard let host = url.host(),
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return nil }
        for rule in rules where hostHasSuffix(host, rule.host) && (rule.path == nil || url.path() == rule.path) {
            guard let value = items.first(where: { $0.name == rule.param })?.value,
                  let inner = URL(string: value),
                  ["http", "https"].contains(inner.scheme?.lowercased()),
                  inner.host() != nil else { continue }
            return inner
        }
        return nil
    }
}
