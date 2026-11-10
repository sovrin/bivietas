import SwiftUI

/// Ordered rule list (first match wins) with an inspector for the selected rule.
struct RulesPane: View {
    @Environment(AppModel.self) private var model
    @State var selection: Rule.ID?

    var body: some View {
        @Bindable var model = model
        List(selection: $selection) {
            if model.config.rules.contains(where: { !model.hasProfile($0.target) }) {
                Label("Some rules point to a browser profile that no longer exists. Their links open in your default profile until you pick a new one.",
                      systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.callout)
                    .selectionDisabled()
            }
            Section {
                ForEach($model.config.rules) { $rule in
                    RuleRow(rule: $rule).tag(rule.id)
                }
                .onMove { model.config.rules.move(fromOffsets: $0, toOffset: $1) }
            } header: {
                Text("Checked top to bottom — the first match wins. Drag to reorder.")
            }
            Section {
                FallbackRow().selectionDisabled()
            }
        }
        .onDeleteCommand(perform: deleteSelected)
        .inspector(isPresented: Binding(get: { selection != nil }, set: { if !$0 { selection = nil } })) {
            Group {
                if let id = selection, model.config.rules.contains(where: { $0.id == id }) {
                    RuleEditor(rule: ruleBinding(id), delete: deleteSelected)
                }
            }
            .inspectorColumnWidth(min: 320, ideal: 360, max: 480)
        }
        .navigationTitle("Rules")
        .toolbar {
            ToolbarItemGroup {
                Button(action: addRule) { Label("Add Rule", systemImage: "plus") }
                    .help("Add Rule")
                Button(action: deleteSelected) { Label("Delete Rule", systemImage: "minus") }
                    .help("Delete Rule")
                    .disabled(selection == nil)
            }
        }
    }

    private func addRule() {
        let rule = Rule(name: "New Rule", conditions: [.hostSuffix("")], target: model.config.defaultTarget)
        model.config.rules.append(rule)
        selection = rule.id
    }

    private func deleteSelected() {
        guard let id = selection else { return }
        selection = nil
        model.config.rules.removeAll { $0.id == id }
    }

    // Looks the rule up by id, so a deleted rule can't crash a stale index binding.
    private func ruleBinding(_ id: Rule.ID) -> Binding<Rule> {
        Binding(
            get: { model.config.rules.first { $0.id == id } ?? Rule(id: id, name: "", conditions: [], target: model.config.defaultTarget) },
            set: { new in
                if let i = model.config.rules.firstIndex(where: { $0.id == id }) { model.config.rules[i] = new }
            })
    }
}

#Preview("Rules") {
    let model = AppModel.preview()
    return RulesPane(selection: model.config.rules.first?.id)
        .environment(model)
        .frame(width: 900, height: 560)
}
