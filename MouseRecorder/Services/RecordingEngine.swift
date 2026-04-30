import Foundation
import CoreGraphics
import AppKit

final class RecordingEngine: ObservableObject {
    weak var store: EventStore?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?
    private var tapThread: Thread?
    private var lastEventTime: Date = Date()

    // C-compatible callback — must be top-level or static
    private static let tapCallback: CGEventTapCallBack = { _, type, event, refcon -> Unmanaged<CGEvent>? in
        guard let refcon else { return Unmanaged.passUnretained(event) }
        let engine = Unmanaged<RecordingEngine>.fromOpaque(refcon).takeUnretainedValue()
        engine.handleCGEvent(type: type, event: event)
        return Unmanaged.passUnretained(event)
    }

    func startRecording() {
        guard !isRunning else { return }

        let eventMask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue)  |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: RecordingEngine.tapCallback,
            userInfo: selfPtr
        ) else {
            NotificationCenter.default.post(name: .accessibilityPermissionRequired, object: nil)
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        lastEventTime = Date()

        tapThread = Thread { [weak self] in
            guard let self else { return }
            let rl = CFRunLoopGetCurrent()!
            self.tapRunLoop = rl
            CFRunLoopAddSource(rl, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        tapThread?.name = "com.mouserecorder.eventTapThread"
        tapThread?.qualityOfService = .userInteractive
        tapThread?.start()

        DispatchQueue.main.async { self.store?.isRecording = true }
    }

    func stopRecording() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let rl = tapRunLoop {
            CFRunLoopStop(rl)
        }
        eventTap = nil
        runLoopSource = nil
        tapRunLoop = nil
        tapThread = nil
        DispatchQueue.main.async { self.store?.isRecording = false }
    }

    var isRunning: Bool { eventTap != nil }

    // MARK: - App-window click filter

    /// Returns true if `cgPoint` (CGEvent/top-left-origin coords) lands inside
    /// any visible window that belongs to this process.  Runs a quick sync hop
    /// to the main thread to read NSApp.windows safely.
    private func isClickInsideAppWindow(_ cgPoint: CGPoint) -> Bool {
        var inside = false
        DispatchQueue.main.sync {
            // Primary screen height is the key to flip the Y axis.
            // NSWindow.frame uses bottom-left origin; CGEvent uses top-left origin.
            let primaryH = NSScreen.screens.first?.frame.height ?? 0
            let nsPoint  = CGPoint(x: cgPoint.x, y: primaryH - cgPoint.y)
            inside = NSApp.windows.contains { w in
                w.isVisible && !w.isMiniaturized && w.frame.contains(nsPoint)
            }
        }
        return inside
    }

    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        let button: MouseButton
        switch type {
        case .leftMouseDown:  button = .left
        case .rightMouseDown: button = .right
        case .otherMouseDown: button = .middle
        default: return
        }

        let loc = event.location

        // Ignore clicks that land on our own UI (e.g. the Stop-Recording button).
        // We must check *before* updating lastEventTime so the delay counter
        // for the next real event stays correct.
        guard !isClickInsideAppWindow(loc) else { return }

        let now = Date()
        let delay = now.timeIntervalSince(lastEventTime)
        lastEventTime = now

        let eventCount = (store?.events.count ?? 0) + 1
        let clickEvent = MouseClickEvent(
            name: "\(button.displayName) Click \(eventCount)",
            x: loc.x,
            y: loc.y,
            button: button,
            delayBeforeFire: delay,
            timestamp: now
        )

        DispatchQueue.main.async { [weak self] in
            self?.store?.addEvent(clickEvent)
        }
    }
}

extension Notification.Name {
    static let accessibilityPermissionRequired = Notification.Name("accessibilityPermissionRequired")
}
