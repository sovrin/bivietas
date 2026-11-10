import Foundation

/// Profiles of a Firefox-based browser, from its `profiles.ini`. Firefox addresses profiles by name (`-P <name>`).
enum FirefoxProfiles {
    static func load(from profilesIni: URL, browserID: String) -> [Profile] {
        (try? String(contentsOf: profilesIni, encoding: .utf8)).map { parse($0, browserID: browserID) } ?? []
    }

    static func parse(_ ini: String, browserID: String) -> [Profile] {
        var names: [String] = []
        var inProfileSection = false
        for line in ini.split(whereSeparator: \.isNewline).map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.hasPrefix("[") {
                inProfileSection = line.hasPrefix("[Profile")
            } else if inProfileSection, line.hasPrefix("Name=") {
                names.append(String(line.dropFirst("Name=".count)))
            }
        }
        return names.map { Profile(target: Target(browserID: browserID, profileID: $0), name: $0) }
    }
}
