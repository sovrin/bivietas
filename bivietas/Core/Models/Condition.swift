import Foundation

enum Condition: Codable, Equatable {
    case hostEquals(String)            // "github.com"
    case hostSuffix(String)            // "corp.example.com" (also matches apex)
    case urlRegex(String)
    case sourceApp(bundleID: String)   // "com.tinyspeck.slackmacgap"
}

extension Condition {
    enum Kind: String, CaseIterable { case hostEquals, hostSuffix, urlRegex, sourceApp }

    init(_ kind: Kind, _ value: String) {
        switch kind {
        case .hostEquals: self = .hostEquals(value)
        case .hostSuffix: self = .hostSuffix(value)
        case .urlRegex: self = .urlRegex(value)
        case .sourceApp: self = .sourceApp(bundleID: value)
        }
    }

    /// Editing helpers: change the kind and keep the value, or vice versa.
    var kind: Kind {
        get {
            switch self {
            case .hostEquals: .hostEquals
            case .hostSuffix: .hostSuffix
            case .urlRegex: .urlRegex
            case .sourceApp: .sourceApp
            }
        }
        set { self = Condition(newValue, value) }
    }

    var value: String {
        get {
            switch self {
            case .hostEquals(let v), .hostSuffix(let v), .urlRegex(let v), .sourceApp(bundleID: let v): v
            }
        }
        set { self = Condition(kind, newValue) }
    }
}
