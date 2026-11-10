import Foundation

/// Asks the user which profile an unmatched link should open in.
protocol ProfileChooser {
    /// `completion(nil, _)` means the user dismissed the chooser; `remember` asks for a new rule.
    func choose(host: String, profiles: [Profile], defaultTarget: Target, completion: @escaping (Profile?, _ remember: Bool) -> Void)
}
