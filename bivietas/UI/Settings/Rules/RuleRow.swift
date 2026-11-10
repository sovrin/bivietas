import SwiftUI

struct RuleRow: View {
    @Binding var rule: Rule

    var body: some View {
        HStack(spacing: 10) {
            DragHandle()
            Toggle("Enabled", isOn: $rule.enabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            icon.frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name.isEmpty ? "Untitled Rule" : rule.name).fontWeight(.medium)
                HStack(spacing: 4) {
                    if rule.hasProblem {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                    Text(rule.summary).lineLimit(1).truncationMode(.tail)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Image(systemName: "arrow.right").font(.caption).foregroundStyle(.tertiary)
            ProfileChip(target: rule.target)
        }
        .padding(.vertical, 4)
        .opacity(rule.enabled ? 1 : 0.5)
    }

    @ViewBuilder private var icon: some View {
        if case .sourceApp(let id) = rule.conditions.first, !id.isEmpty {
            AppIcon(bundleID: id, size: 22)
        } else {
            Image(systemName: rule.conditions.first?.kind == .urlRegex ? "text.magnifyingglass" : "globe")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}
