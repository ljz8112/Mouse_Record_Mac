import SwiftUI

struct SchedulerView: View {
    @EnvironmentObject private var store: EventStore
    @EnvironmentObject private var schedulerEngine: SchedulerEngine

    // ── Time input state (text is the single source of truth) ────
    @State private var hourText:   String = "00"
    @State private var minuteText: String = "00"
    @State private var secondText: String = "00"

    // ── Millisecond offset ────────────────────────────────────────
    @State private var offsetMs: Int = 0

    // ── Focus tracking – used to normalize (zero-pad) on blur ────
    private enum FieldFocus: Hashable { case hour, minute, second }
    @FocusState private var fieldFocus: FieldFocus?

    // ── Countdown ─────────────────────────────────────────────────
    @State private var countdown: TimeInterval = 0
    private let countdownTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // ── Derived values (always fresh from text, no Int state) ─────
    private var parsedHour:   Int { clamped(Int(hourText)   ?? 0, 0...23) }
    private var parsedMinute: Int { clamped(Int(minuteText) ?? 0, 0...59) }
    private var parsedSecond: Int { clamped(Int(secondText) ?? 0, 0...59) }

    private func clamped(_ v: Int, _ r: ClosedRange<Int>) -> Int { min(max(v, r.lowerBound), r.upperBound) }

    private var targetDate: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour   = parsedHour
        comps.minute = parsedMinute
        comps.second = parsedSecond
        var d = Calendar.current.date(from: comps) ?? Date()
        if d <= Date() { d = Calendar.current.date(byAdding: .day, value: 1, to: d) ?? d }
        return d.addingTimeInterval(Double(offsetMs) / 1000.0)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                scheduleCard
                if store.isScheduled { statusCard }
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("定时运行")
        .onAppear { loadCurrentTime() }
        .onReceive(countdownTimer) { _ in countdown = schedulerEngine.secondsRemaining }
        // Normalize display whenever focus leaves a time field
        .onChange(of: fieldFocus) { focused in
            if focused != .hour   { normalizeText(&hourText,   range: 0...23) }
            if focused != .minute { normalizeText(&minuteText, range: 0...59) }
            if focused != .second { normalizeText(&secondText, range: 0...59) }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.gradient)
                    .frame(width: 52, height: 52)
                Image(systemName: "clock.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("定时运行")
                    .font(.title2.weight(.bold))
                Text("输入本地时间，届时自动回放所有事件。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Schedule card

    private var scheduleCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 20) {

                // ── Digital time input ──────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发时间")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        timeDigitField(text: $hourText,   range: 0...23, focus: .hour)
                        colonSeparator
                        timeDigitField(text: $minuteText, range: 0...59, focus: .minute)
                        colonSeparator
                        timeDigitField(text: $secondText, range: 0...59, focus: .second)

                        Spacer()

                        Button {
                            loadCurrentTime()
                        } label: {
                            Label("当前时间", systemImage: "clock.arrow.circlepath")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(store.isScheduled)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.caption2)
                        Text(targetDateDescription).font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                }

                Divider()

                // ── Millisecond offset ──────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("触发偏移")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        TextField(value: $offsetMs, format: .number) { EmptyView() }
                            .font(.system(.body, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 88)
                            .textFieldStyle(.roundedBorder)
                            .disabled(store.isScheduled)

                        Text("ms").foregroundStyle(.secondary)

                        Stepper("", value: $offsetMs, step: 100)
                            .labelsHidden()
                            .disabled(store.isScheduled)

                        Spacer()

                        Text(offsetLabel)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(offsetBadgeColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(offsetBadgeColor)
                    }

                    Text("正数 = 在设定时间之后延迟触发；负数 = 提前触发；0 = 准时。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // ── Action buttons ──────────────────────────────
                HStack {
                    if store.isScheduled {
                        Button(role: .destructive) {
                            schedulerEngine.cancelSchedule()
                        } label: {
                            Label("取消定时", systemImage: "xmark.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button {
                            // Normalize all fields before scheduling
                            normalizeText(&hourText,   range: 0...23)
                            normalizeText(&minuteText, range: 0...59)
                            normalizeText(&secondText, range: 0...59)
                            schedulerEngine.scheduleRun(at: targetDate)
                        } label: {
                            Label("设置定时运行", systemImage: "clock.badge.checkmark.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.events.isEmpty || store.isPlaying || store.isRecording)
                    }

                    Spacer()

                    if store.events.isEmpty {
                        Label("请先录制或添加事件", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(4)
        } label: {
            Label("定时配置", systemImage: "calendar.badge.clock")
                .font(.headline)
        }
    }

    // MARK: - Status card

    private var statusCard: some View {
        GroupBox {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("已定时")
                        .font(.callout.weight(.semibold))
                    Text("将于 \(store.scheduledRunDate.formatted(date: .abbreviated, time: .standard)) 触发")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if offsetMs != 0 {
                        Text("偏移：\(offsetLabel)")
                            .font(.caption2)
                            .foregroundStyle(offsetBadgeColor)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedCountdown(countdown))
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(.orange)
                    Text("剩余时间")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(4)
        } label: {
            Label("运行状态", systemImage: "timer")
                .font(.headline)
        }
    }

    // MARK: - Time digit field

    private var colonSeparator: some View {
        Text(":")
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }

    private func timeDigitField(
        text: Binding<String>,
        range: ClosedRange<Int>,
        focus: FieldFocus
    ) -> some View {
        VStack(spacing: 2) {
            // Increment
            Button {
                let cur = clamped(Int(text.wrappedValue) ?? range.lowerBound, range)
                let next = cur < range.upperBound ? cur + 1 : range.lowerBound
                text.wrappedValue = String(format: "%02d", next)
            } label: {
                Image(systemName: "chevron.up").font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(store.isScheduled)

            // Text field — commits on Return AND on blur (via @FocusState onChange)
            TextField("", text: text)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                .disabled(store.isScheduled)
                .focused($fieldFocus, equals: focus)
                .onSubmit { normalizeText(&text.wrappedValue, range: range) }
                .onChange(of: text.wrappedValue) { new in
                    // Strip non-digits and cap at 2 chars while typing
                    let digits = new.filter(\.isNumber)
                    if digits != new { text.wrappedValue = String(digits.prefix(2)) }
                }

            // Decrement
            Button {
                let cur = clamped(Int(text.wrappedValue) ?? range.lowerBound, range)
                let prev = cur > range.lowerBound ? cur - 1 : range.upperBound
                text.wrappedValue = String(format: "%02d", prev)
            } label: {
                Image(systemName: "chevron.down").font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(store.isScheduled)
        }
    }

    // MARK: - Helpers

    /// Clamp and zero-pad a text field's string value in place.
    private func normalizeText(_ text: inout String, range: ClosedRange<Int>) {
        let v = clamped(Int(text) ?? range.lowerBound, range)
        text = String(format: "%02d", v)
    }

    /// Overload that accepts a Binding (used from onSubmit).
    private func normalizeText(_ text: Binding<String>, range: ClosedRange<Int>) {
        normalizeText(&text.wrappedValue, range: range)
    }

    private func loadCurrentTime() {
        let now = Date()
        let cal = Calendar.current
        hourText   = String(format: "%02d", cal.component(.hour,   from: now))
        minuteText = String(format: "%02d", cal.component(.minute, from: now))
        secondText = String(format: "%02d", cal.component(.second, from: now))
    }

    private var targetDateDescription: String {
        let cal = Calendar.current
        if cal.isDateInToday(targetDate)    { return "今天" }
        if cal.isDateInTomorrow(targetDate) { return "明天" }
        return targetDate.formatted(date: .complete, time: .omitted)
    }

    private var offsetLabel: String {
        if offsetMs == 0 { return "准时" }
        return offsetMs > 0 ? "延后 \(offsetMs) ms" : "提前 \(-offsetMs) ms"
    }

    private var offsetBadgeColor: Color {
        offsetMs == 0 ? .secondary : (offsetMs > 0 ? .orange : .green)
    }

    private func formattedCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h   = total / 3600
        let m   = (total % 3600) / 60
        let sec = total % 60
        let ms  = Int((seconds - Double(total)) * 10)
        if seconds < 10 { return String(format: "%02d.%d", sec, ms) }
        if h > 0        { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}
