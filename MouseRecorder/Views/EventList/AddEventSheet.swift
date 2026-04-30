import SwiftUI
import AppKit

struct AddEventSheet: View {
    @EnvironmentObject private var store: EventStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "新建点击"
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var button: MouseButton = .left
    @State private var delay: TimeInterval = 0.5

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text("添加鼠标事件")
                    .font(.headline)
                Spacer()
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 16)

            Divider()

            Form {
                Section {
                    LabeledContent("事件名称") {
                        TextField("例如：点击登录按钮", text: $name)
                    }
                    LabeledContent("鼠标按键") {
                        Picker("", selection: $button) {
                            ForEach(MouseButton.allCases) { btn in
                                Label(btn.displayName, systemImage: btn.symbolName).tag(btn)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 260)
                    }
                } header: {
                    Text("基本信息")
                }

                Section {
                    LabeledContent("X 坐标") {
                        TextField(value: $x, format: .number.precision(.fractionLength(1))) {
                            EmptyView()
                        }
                        .frame(width: 90)
                    }
                    LabeledContent("Y 坐标") {
                        TextField(value: $y, format: .number.precision(.fractionLength(1))) {
                            EmptyView()
                        }
                        .frame(width: 90)
                    }
                    LabeledContent("") {
                        Button {
                            pickMousePosition()
                        } label: {
                            Label("拾取鼠标位置…", systemImage: "cursorarrow.and.square.on.square.dashed")
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("屏幕坐标")
                } footer: {
                    Text("坐标系以屏幕左上角为原点，X 向右，Y 向下。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent("触发前等待") {
                        HStack(spacing: 6) {
                            TextField(value: $delay, format: .number.precision(.fractionLength(2))) {
                                EmptyView()
                            }
                            .frame(width: 72)
                            Text("秒")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("时序")
                } footer: {
                    Text("在执行本事件之前等待的时间（0 = 立即执行）。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Footer buttons
            HStack {
                Button("取消", role: .cancel) { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("添加事件") {
                    addEvent()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(20)
        }
        .frame(width: 420, height: 520)
    }

    private func pickMousePosition() {
        // Dismiss the sheet first so the overlay can cover the full screen,
        // then show the interactive picker; coordinates are fed back via the callback.
        // We keep the callback alive by capturing self weakly.
        MousePositionPicker.shared.show { [self] pickedX, pickedY in
            self.x = pickedX
            self.y = pickedY
        }
    }

    private func addEvent() {
        let event = MouseClickEvent(
            name: name.trimmingCharacters(in: .whitespaces),
            x: x,
            y: y,
            button: button,
            delayBeforeFire: max(0, delay),
            timestamp: Date()
        )
        store.addEvent(event)
        dismiss()
    }
}
