import SwiftUI

/// Inspector form for one rule.
struct RuleEditor: View {
    @Binding var rule: Rule
    let delete: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $rule.name)
                Toggle("Enabled", isOn: $rule.enabled)
                ProfilePicker(title: "Open in", selection: $rule.target)
            }
            Section {
                ForEach(rule.conditions.indices, id: \.self) { i in
                    ConditionEditor(condition: conditionBinding(i), canRemove: rule.conditions.count > 1) {
                        if rule.conditions.indices.contains(i) { rule.conditions.remove(at: i) }
                    }
                }
                Button { rule.conditions.append(.hostSuffix("")) } label: {
                    Label("Add Condition", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            } header: {
                Text("When all of these match")
            } footer: {
                if rule.conditions.isEmpty {
                    Text("A rule without conditions never matches.").foregroundStyle(.orange)
                }
            }
            Section {
                Button("Delete Rule", role: .destructive, action: delete)
            }
        }
        .formStyle(.grouped)
    }

    private func conditionBinding(_ i: Int) -> Binding<Condition> {
        Binding(
            get: { rule.conditions.indices.contains(i) ? rule.conditions[i] : .hostSuffix("") },
            set: { if rule.conditions.indices.contains(i) { rule.conditions[i] = $0 } })
    }
}
