import Foundation

/// Profiles of a Chromium-based browser, from its `Local State` file.
enum ChromiumProfiles {
    static func load(from localState: URL, browserID: String) -> [Profile] {
        (try? parse(Data(contentsOf: localState), browserID: browserID)) ?? []
    }

    static func parse(_ data: Data, browserID: String) throws -> [Profile] {
        struct LocalState: Decodable {
            struct Info: Decodable { let name: String? }
            struct Profiles: Decodable { let info_cache: [String: Info] }
            let profile: Profiles
        }
        return try JSONDecoder().decode(LocalState.self, from: data).profile.info_cache
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { Profile(target: Target(browserID: browserID, profileID: $0.key), name: $0.value.name ?? $0.key) }
    }
}
