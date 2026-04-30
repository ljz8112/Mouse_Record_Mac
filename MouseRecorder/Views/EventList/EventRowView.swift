import SwiftUI

struct EventRowView: View {
    @Binding var event: MouseClickEvent
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 0) {
            // Index color strip
            RoundedRectangle(cornerRadius: 3)
                .fill(buttonColor)
                .frame(width: 4)
                .padding(.trailing, 10)

            // Name
            TextField("事件名称", text: $event.name)
                .textFieldStyle(.plain)
                .font(.body.weight(.medium))
                .frame(minWidth: 130, idealWidth: 160)

            Divider().frame(height: 18).padding(.horizontal, 8)

            // Button type
            Picker("", selection: $event.button) {
                ForEach(MouseButton.allCases) { btn in
                    Label(btn.displayName, systemImage: btn.symbolName).tag(btn)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 100)

            Divider().frame(height: 18).padding(.horizontal, 8)

            // Coordinates
            HStack(spacing: 4) {
                Text("X")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
                TextField("0", value: $event.x, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 68)
                Text("Y")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
                TextField("0", value: $event.y, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 68)
            }

            Divider().frame(height: 18).padding(.horizontal, 8)

            // Delay
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("0", value: $event.delayBeforeFire, format: .number.precision(.fractionLength(2)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                Text("秒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 5)
    }

    private var buttonColor: Color {
        switch event.button {
        case .left:   return .accentColor
        case .right:  return .orange
        case .middle: return .purple
        }
    }
}
