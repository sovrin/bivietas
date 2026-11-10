import SwiftUI

struct ConditionEditor: View {
    @Binding var condition: Condition
    let canRemove: Bool
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Picker("Condition", selection: $condition.kind) {
                    ForEach(Condition.Kind.allCases, id: \.self) { Text($0.label) }
                }
                .labelsHidden()
                .fixedSize()
                Spacer()
                if canRemove {
                    Button(action: remove) { Image(systemName: "minus.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.borderless)
                        .help("Remove Condition")
                }
            }
            if condition.kind == .sourceApp {
                SourceAppPicker(bundleID: $condition.value)
            }
            HStack {
                Text(condition.kind.fieldLabel).foregroundStyle(.secondary)
                TextField(condition.kind.fieldLabel, text: $condition.value, prompt: Text(condition.kind.placeholder))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .font(condition.kind == .hostEquals || condition.kind == .hostSuffix ? .body : .body.monospaced())
            }
            Group {
                if let problem = condition.problem {
                    Label(problem, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                } else {
                    Text(condition.kind.hint).foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            if condition.kind == .urlRegex {
                RegexTester(pattern: condition.value)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 2)
    }
}
