import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = EventStore()
    let recordingEngine = RecordingEngine()
    let playbackEngine = PlaybackEngine()
    let schedulerEngine = SchedulerEngine()

    // Mini-mode window management
    private var savedWindowFrame: NSRect?
    private var cancellables = Set<AnyCancellable>()

    // Mini window dimensions.
    // Height = MiniRecordingView.contentHeight + title-bar height (~28 pt).
    private let miniSize = CGSize(
        width:  MiniRecordingView.contentWidth,
        height: MiniRecordingView.contentHeight + 28
    )

    override init() {
        super.init()
        recordingEngine.store = store
        playbackEngine.store = store
        schedulerEngine.store = store
        schedulerEngine.playbackEngine = playbackEngine
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Accessibility permission on first launch
        if !AccessibilityPermissionService.isGranted() {
            AccessibilityPermissionService.requestPermission()
        }

        NotificationCenter.default.addObserver(
            forName: .accessibilityPermissionRequired,
            object: nil,
            queue: .main
        ) { [weak self] _ in _ = self }

        // Observe recording & playback state → enter / exit mini-mode
        store.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recording in
                if recording { self?.enterMiniMode(animated: true) }
                else         { self?.exitMiniModeIfIdle() }
            }
            .store(in: &cancellables)

        // Playback: shrink instantly so no click can land in the full-size window
        store.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                if playing { self?.enterMiniMode(animated: false) }
                else       { self?.exitMiniModeIfIdle() }
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        schedulerEngine.cancelSchedule()
        recordingEngine.stopRecording()
        playbackEngine.stopPlayback()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - Mini-mode

    private var mainWindow: NSWindow? {
        NSApp.windows.first { $0.isVisible && !($0 is NSPanel) }
    }

    private func enterMiniMode(animated: Bool) {
        guard let win = mainWindow else { return }

        // Save the current frame so we can restore it later
        savedWindowFrame = win.frame

        // Switch SwiftUI content to mini view BEFORE the window moves,
        // so the NavigationSplitView never appears inside a tiny frame.
        store.isMiniMode = true

        // Float above everything while active
        win.level = .floating
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.styleMask.remove(.resizable)

        // Compute target: top-right corner of the current screen
        let screen = win.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let visibleFrame = screen.visibleFrame
        let origin = CGPoint(
            x: visibleFrame.maxX - miniSize.width - 20,
            y: visibleFrame.maxY - miniSize.height - 20
        )
        let targetFrame = NSRect(origin: origin, size: miniSize)

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                win.animator().setFrame(targetFrame, display: true)
            }
        } else {
            // Instant reposition — no delay, no risk of stray clicks on the large window
            win.setFrame(targetFrame, display: true, animate: false)
        }
    }

    private func exitMiniModeIfIdle() {
        // Only restore when neither recording nor playing is active
        guard !store.isRecording, !store.isPlaying else { return }
        guard let win = mainWindow, let frame = savedWindowFrame else { return }

        // Restore window chrome
        win.level = .normal
        win.collectionBehavior = [.managed]
        win.styleMask.insert(.resizable)

        // Switch content to full view first, then animate the window expanding.
        store.isMiniMode = false
        savedWindowFrame = nil

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            win.animator().setFrame(frame, display: true)
        }
    }
}
