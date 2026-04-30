import SwiftUI

struct EventListView: View {
    @EnvironmentObject private var store: EventStore
    @EnvironmentObject private var recordingEngine: RecordingEngine
    @EnvironmentObject private var playbackEngine: PlaybackEngine
    @EnvironmentObject private var schedulerEngine: SchedulerEngine

    @State private var selection = Set<UUID>()
    @State private var showAddSheet = false
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            shortcutHintBar
            PermissionBannerView()

            if store.events.isEmpty {
                emptyState
            } else {
                List(selection: $selection) {
                    ForEach($store.events) { $event in
                        EventRowView(event: $event)
                            .tag(event.id)
                    }
                    .onMove { from, to in store.moveEvents(fromOffsets: from, toOffset: to) }
                    .onDelete { idxs in store.deleteEvent(at: idxs) }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            StatusBarView()
        }
        .toolbar(content: toolbarContent)
        .navigationTitle("事件列表")
        .sheet(isPresented: $showAddSheet) {
            AddEventSheet()
                .environmentObject(store)
        }
        .confirmationDialog("清空所有事件？", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("清空", role: .destructive) { store.clearAll() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作不可撤销，所有录制的事件将被删除。")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("尚无事件")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("点击\"录制\"开始捕获鼠标点击，\n或点击\"+\"手动添加单个事件。")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.tertiary)
            Button {
                showAddSheet = true
            } label: {
                Label("手动添加事件", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Shortcut hint bar

    private var shortcutHintBar: some View {
        HStack(spacing: 0) {
            hintItem(
                key: "⌘R",
                label: "开始录制",
                active: !store.isRecording && !store.isPlaying
            )
            hintSeparator
            hintItem(
                key: "⇧⌘R",
                label: "停止录制",
                active: store.isRecording
            )
            hintSeparator
            hintItem(
                key: "⌘P",
                label: "回放",
                active: !store.isPlaying && !store.isRecording && !store.events.isEmpty
            )
            hintSeparator
            hintItem(
                key: "⇧⌘P",
                label: "停止回放",
                active: store.isPlaying
            )
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func hintItem(key: String, label: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    (active ? Color.accentColor : Color.secondary).opacity(active ? 0.15 : 0.08),
                    in: RoundedRectangle(cornerRadius: 4)
                )
                .foregroundStyle(active ? Color.accentColor : .secondary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(active ? Color.primary : Color.secondary)
        }
        .padding(.trailing, 14)
        .animation(.easeInOut(duration: 0.2), value: active)
    }

    private var hintSeparator: some View {
        Text("·")
            .font(.system(size: 11))
            .foregroundStyle(.quaternary)
            .padding(.trailing, 14)
    }

    // MARK: - Coordinate picker

    private func pickNewCoordinates() {
        guard !selection.isEmpty else { return }
        MousePositionPicker.shared.show { pickedX, pickedY in
            // Apply the new coordinate to every selected event
            for id in selection {
                if var event = store.events.first(where: { $0.id == id }) {
                    event.x = pickedX
                    event.y = pickedY
                    store.updateEvent(event)
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if store.isRecording {
                Button(action: { recordingEngine.stopRecording() }) {
                    Label("停止录制", systemImage: "stop.circle.fill")
                }
            } else {
                Button(action: { recordingEngine.startRecording() }) {
                    Label("开始录制", systemImage: "record.circle")
                }
                .disabled(store.isPlaying)
            }

            if store.isPlaying {
                Button(action: { playbackEngine.stopPlayback() }) {
                    Label("停止回放", systemImage: "stop.fill")
                }
            } else {
                Button(action: { playbackEngine.startPlayback() }) {
                    Label("回放", systemImage: "play.fill")
                }
                .disabled(store.isRecording || store.events.isEmpty)
            }

            Button(action: { showAddSheet = true }) {
                Label("添加", systemImage: "plus")
            }

            Button(action: { pickNewCoordinates() }) {
                Label("修改坐标", systemImage: "cursorarrow.and.square.on.square.dashed")
            }
            .disabled(selection.isEmpty || store.isRecording || store.isPlaying)
            .help("用拾取器为所选事件设置新坐标")

            Button(role: .destructive, action: {
                store.deleteEvents(ids: selection)
                selection.removeAll()
            }) {
                Label("删除", systemImage: "trash")
            }
            .disabled(selection.isEmpty)

            Menu {
                Button(action: { ImportExportService.export(store.events) }) {
                    Label("导出…", systemImage: "square.and.arrow.up")
                }
                .disabled(store.events.isEmpty)

                Button(action: { ImportExportService.import(into: store) }) {
                    Label("导入…", systemImage: "square.and.arrow.down")
                }

                Divider()

                Button(role: .destructive, action: { showClearConfirm = true }) {
                    Label("清空全部", systemImage: "trash.fill")
                }
                .disabled(store.events.isEmpty)
            } label: {
                Label("更多", systemImage: "ellipsis.circle")
            }
        }
    }
}
