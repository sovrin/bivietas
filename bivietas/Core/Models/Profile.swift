import Foundation

struct Profile: Identifiable, Hashable {
    let target: Target
    let name: String // display name, e.g. "Private"

    var id: Target { target }
    var browserID: String { target.browserID }
}
