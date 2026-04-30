import Foundation
import CoreGraphics
import AppKit

final class PlaybackEngine: ObservableObject {
    weak var store: EventStore?
    private var playbackTask: Task<Void, Never>?

    /// Index of the event currently being fired (-1 = not playing).
    @Published var currentEventIndex: Int = -1

    func startPlayback() {
        guard let store, !store.events.isEmpty, !store.isPlaying else { return }
        store.isPlaying = true
        currentEventIndex = -1

        playbackTask = Task { [weak self, weak store] in
            guard let store else { return }
            let events = store.events

            for (index, event) in events.enumerated() {
                guard !Task.isCancelled else { break }

                // Publish current index on main thread
                let i = index
                DispatchQueue.main.async { self?.currentEventIndex = i }

                if event.delayBeforeFire > 0 {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(event.delayBeforeFire * 1_000_000_000))
                    } catch {
                        break
                    }
                }

                guard !Task.isCancelled else { break }
                self?.postClick(event: event)
            }

            await MainActor.run {
                store.isPlaying = false
                self?.currentEventIndex = -1
            }
        }
    }

    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        store?.isPlaying = false
        currentEventIndex = -1
    }

    private func postClick(event: MouseClickEvent) {
        let point = event.cgPoint
        let button = event.button

        if let downEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: button.downType,
            mouseCursorPosition: point,
            mouseButton: button.cgMouseButton
        ) {
            downEvent.post(tap: .cghidEventTap)
        }

        // Synthetic down-to-up gap (≈50 ms — realistic click duration)
        Thread.sleep(forTimeInterval: 0.05)

        if let upEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: button.upType,
            mouseCursorPosition: point,
            mouseButton: button.cgMouseButton
        ) {
            upEvent.post(tap: .cghidEventTap)
        }
    }
}
