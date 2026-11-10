import Foundation

// Human-readable text for rules and conditions, used by the rule list and editor.

extension Rule {
    var summary: String {
        guard !conditions.isEmpty else { return "No conditions — never matches" }
        let text = conditions.map(\.summary).joined(separator: " and ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    var hasProblem: Bool { conditions.isEmpty || conditions.contains { $0.problem != nil } }
}

extension Condition {
    var summary: String {
        switch self {
        case .hostEquals(let host): "host is \(host.isEmpty ? "…" : host)"
        case .hostSuffix(let suffix): "host ends with \(suffix.isEmpty ? "…" : suffix)"
        case .urlRegex(let pattern): "URL matches \(pattern.isEmpty ? "…" : pattern)"
        case .sourceApp(let id): "opened from \(id.isEmpty ? "…" : AppInfo.isInstalled(id) ? AppInfo.name(id) : "\(id) (not installed)")"
        }
    }

    /// Inline validation message, nil when the condition is usable.
    var problem: String? {
        if value.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter a value — empty conditions never match." }
        if case .urlRegex(let pattern) = self, (try? Regex(pattern)) == nil { return "Not a valid regular expression." }
        return nil
    }
}

extension Condition.Kind {
    var label: String {
        switch self {
        case .hostEquals: "Host is"
        case .hostSuffix: "Host ends with"
        case .urlRegex: "URL matches regex"
        case .sourceApp: "Opened from app"
        }
    }

    var fieldLabel: String {
        switch self {
        case .hostEquals, .hostSuffix: "Host"
        case .urlRegex: "Pattern"
        case .sourceApp: "Bundle ID"
        }
    }

    var placeholder: String {
        switch self {
        case .hostEquals: "github.com"
        case .hostSuffix: "corp.example.com"
        case .urlRegex: "^https://.*/jira/"
        case .sourceApp: "com.tinyspeck.slackmacgap"
        }
    }

    var hint: String {
        switch self {
        case .hostEquals: "Exact host only — www.github.com would not match github.com."
        case .hostSuffix: "Matches the domain and all its subdomains."
        case .urlRegex: "Tested against the full URL after unwrapping redirects."
        case .sourceApp: "The app you clicked the link in."
        }
    }
}
