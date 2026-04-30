import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject private var store: EventStore
    @EnvironmentObject private var schedulerEngine: SchedulerEngine
    @State private var countdown: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 10) {
            statusIndicator
            Spacer()
            Text("\(store.events.count) 个事件")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .onReceive(timer) { _ in
            countdown = schedulerEngine.secondsRemaining
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if store.isRecording {
            Label("录制中…", systemImage: "circle.fill")
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.red)
                .font(.caption.weight(.medium))
        } else if store.isPlaying {
            Label("回放中…", systemImage: "play.circle.fill")
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.green)
                .font(.caption.weight(.medium))
        } else if store.isScheduled {
            Label(
                "定时运行 · \(formattedCountdown(countdown))",
                systemImage: "clock.fill"
            )
            .foregroundStyle(.orange)
            .font(.caption.weight(.medium))
        } else {
            Text("就绪")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedCountdown(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}
