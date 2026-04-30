import Foundation
import Combine

final class EventStore: ObservableObject {
    @Published var events: [MouseClickEvent] = []
    @Published var isRecording: Bool = false
    /// Drives the mini/full view switch — set true before shrinking,
    /// set false only after the expand animation finishes.
    @Published var isMiniMode: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isScheduled: Bool = false
    @Published var scheduledRunDate: Date = Calendar.current.date(
        byAdding: .minute, value: 5, to: Date()
    ) ?? Date().addingTimeInterval(300)

    // MARK: - CRUD

    func addEvent(_ event: MouseClickEvent) {
        events.append(event)
    }

    func deleteEvents(ids: Set<UUID>) {
        events.removeAll { ids.contains($0.id) }
    }

    func deleteEvent(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
    }

    func moveEvents(fromOffsets: IndexSet, toOffset: Int) {
        events.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func updateEvent(_ event: MouseClickEvent) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
    }

    func clearAll() {
        events.removeAll()
    }
}
