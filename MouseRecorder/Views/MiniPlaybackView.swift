import SwiftUI

struct MiniPlaybackView: View {
    @EnvironmentObject private var store: EventStore
    @EnvironmentObject private var playbackEngine: PlaybackEngine

    @State private var pulse = false

    // Same content size as MiniRecordingView
    static let contentWidth:  CGFloat = MiniRecordingView.contentWidth
    static let contentHeight: CGFloat = MiniRecordingView.contentHeight

    private var total: Int { store.events.count }
    private var current: Int { max(0, playbackEngine.currentEventIndex) }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────
            HStack(spacing: 7) {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(pulse ? 0.45 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                        value: pulse
                    )
                    .onAppear { pulse = true }

                Text("回放中")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(min(current + 1, total)) / \(total)")
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: current)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // ── Progress bar ──────────────────────────────────────
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                    Rectangle()
                        .fill(Color.green.opacity(0.75))
                        .frame(width: total > 0
                               ? geo.size.width * CGFloat(current + 1) / CGFloat(total)
                               : 0)
                        .animation(.easeInOut(duration: 0.2), value: current)
                }
            }
            .frame(height: 3)

            Divider()

            // ── Event list (all events, current highlighted) ──────
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.events.enumerated()), id: \.element.id) { idx, event in
                            playbackRow(event: event, index: idx)
                                .id(idx)
                        }
                    }
                }
                .frame(height: 110)
                .onChange(of: playbackEngine.currentEventIndex) { newIndex in
                    if newIndex >= 0 {
                        withAnimation { proxy.scrollTo(newIndex, anchor: .center) }
                    }
                }
            }

            Divider()

            // ── Stop button ───────────────────────────────────────
            Button(action: { playbackEngine.stopPlayback() }) {
                Label("停止回放", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.regular)
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: Self.contentWidth, height: Self.contentHeight)
    }

    // MARK: - Row

    private func playbackRow(event: MouseClickEvent, index: Int) -> some View {
        let isCurrent = index == playbackEngine.currentEventIndex
        return HStack(spacing: 6) {
            if isCurrent {
                Image(systemName: "play.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
                    .frame(width: 14)
            } else {
                Image(systemName: event.button.symbolName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
            }

            Text(event.name)
                .font(isCurrent ? .caption.weight(.semibold) : .caption)
                .foregroundStyle(isCurrent ? Color.primary : Color.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(String(format: "(%.0f, %.0f)", event.x, event.y))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(isCurrent ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary))
        }
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(isCurrent ? Color.green.opacity(0.1) : Color.clear)
    }
}
