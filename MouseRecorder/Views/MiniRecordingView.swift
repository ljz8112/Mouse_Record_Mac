import SwiftUI

struct MiniRecordingView: View {
    @EnvironmentObject private var store: EventStore
    @EnvironmentObject private var recordingEngine: RecordingEngine

    @State private var pulse = false

    // Keep these in sync with AppDelegate.miniSize minus the title-bar height (~28 pt).
    // Window = 300 × 230  →  content area ≈ 300 × 202
    static let contentWidth:  CGFloat = 300
    static let contentHeight: CGFloat = 202

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────
            HStack(spacing: 7) {
                Circle()
                    .fill(.red)
                    .frame(width: 9, height: 9)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0.55 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                        value: pulse
                    )
                    .onAppear { pulse = true }

                Text("录制中")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(store.events.count) 个事件")
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: store.events.count)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // ── Event list ────────────────────────────────────────
            // Fixed-height zone so the stop button never gets pushed out.
            Group {
                if store.events.isEmpty {
                    Text("等待第一次点击…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(store.events.suffix(5).reversed()) { event in
                                miniEventRow(event)
                            }
                        }
                    }
                }
            }
            .frame(height: 114)   // ~4 rows × 28 pt + a little breathing room

            Divider()

            // ── Stop button ───────────────────────────────────────
            Button(action: { recordingEngine.stopRecording() }) {
                Label("停止录制", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.regular)
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: Self.contentWidth, height: Self.contentHeight)
    }

    // MARK: - Row

    private func miniEventRow(_ event: MouseClickEvent) -> some View {
        HStack(spacing: 6) {
            Image(systemName: event.button.symbolName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Text(event.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(String(format: "(%.0f, %.0f)", event.x, event.y))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .frame(height: 26)
    }
}
