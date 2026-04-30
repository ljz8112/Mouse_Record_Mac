import SwiftUI

@main
struct MouseRecorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.store)
                .environmentObject(appDelegate.recordingEngine)
                .environmentObject(appDelegate.playbackEngine)
                .environmentObject(appDelegate.schedulerEngine)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 960, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("事件") {
                Button("开始录制") {
                    appDelegate.recordingEngine.startRecording()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(appDelegate.store.isRecording || appDelegate.store.isPlaying)

                Button("停止录制") {
                    appDelegate.recordingEngine.stopRecording()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!appDelegate.store.isRecording)

                Divider()

                Button("开始回放") {
                    appDelegate.playbackEngine.startPlayback()
                }
                .keyboardShortcut("p", modifiers: [.command])
                .disabled(appDelegate.store.isRecording || appDelegate.store.events.isEmpty || appDelegate.store.isPlaying)

                Button("停止回放") {
                    appDelegate.playbackEngine.stopPlayback()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!appDelegate.store.isPlaying)

                Divider()

                Button("导入事件…") {
                    ImportExportService.import(into: appDelegate.store)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("导出事件…") {
                    ImportExportService.export(appDelegate.store.events)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(appDelegate.store.events.isEmpty)
            }
        }
    }
}
