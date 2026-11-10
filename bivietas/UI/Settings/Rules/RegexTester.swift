import SwiftUI

/// Live check for a regex condition: paste a URL, see whether the pattern matches and what it matched.
/// The sample is unwrapped first, exactly like routing does, so the result can't disagree with real links.
struct RegexTester: View {
    let pattern: String
    @State var sample = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Test").foregroundStyle(.secondary)
                TextField("Test URL", text: $sample, prompt: Text("Paste a link to try the pattern"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
            }
            if let result {
                Label(result.matched ? "Matches" : "No match",
                      systemImage: result.matched ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(result.matched ? Color.green : Color.secondary)
                    .font(.caption.weight(.medium))
                Text(result.highlighted)
                    .font(.caption.monospaced())
                    .lineLimit(4)
                    .textSelection(.enabled)
                if result.unwrapped {
                    Text("Tested against the real destination inside the redirect, like routing does.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// nil while there's nothing to report: no sample, or the pattern itself is invalid (flagged by the editor).
    private var result: (matched: Bool, highlighted: AttributedString, unwrapped: Bool)? {
        let trimmed = sample.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !pattern.isEmpty, (try? Regex(pattern)) != nil,
              let url = URL(string: trimmed) else { return nil }
        let tested = URLUnwrapper.unwrap(url)
        let text = tested.absoluteString
        let range = RuleEngine.regexMatch(pattern, in: text)

        var highlighted = AttributedString(text)
        highlighted.foregroundColor = .secondary
        if let range, let lower = AttributedString.Index(range.lowerBound, within: highlighted),
           let upper = AttributedString.Index(range.upperBound, within: highlighted) {
            highlighted[lower..<upper].foregroundColor = .primary
            highlighted[lower..<upper].backgroundColor = .green.opacity(0.3)
        }
        return (range != nil, highlighted, tested != url)
    }
}

#Preview("Regex tester") {
    Form {
        RegexTester(pattern: "/jira/[A-Z]+-\\d+",
                    sample: "https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fcorp.atlassian.net%2Fjira%2FPROJ-42")
        RegexTester(pattern: "/wiki/", sample: "https://corp.atlassian.net/jira/PROJ-42")
    }
    .formStyle(.grouped)
    .frame(width: 380, height: 300)
}
