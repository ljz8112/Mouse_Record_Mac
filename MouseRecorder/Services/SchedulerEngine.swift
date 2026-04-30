import Foundation

final class SchedulerEngine: ObservableObject {
    weak var store: EventStore?
    weak var playbackEngine: PlaybackEngine?
    private var schedulerTimer: Timer?

    func scheduleRun(at date: Date) {
        cancelSchedule()
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        store?.isScheduled = true
        store?.scheduledRunDate = date

        schedulerTimer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.store?.isScheduled = false
            self?.playbackEngine?.startPlayback()
        }
        RunLoop.main.add(schedulerTimer!, forMode: .common)
    }

    func cancelSchedule() {
        schedulerTimer?.invalidate()
        schedulerTimer = nil
        store?.isScheduled = false
    }

    var secondsRemaining: TimeInterval {
        guard let store, store.isScheduled else { return 0 }
        return max(0, store.scheduledRunDate.timeIntervalSinceNow)
    }
}
