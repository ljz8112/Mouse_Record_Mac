import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case events    = "events"
    case scheduler = "scheduler"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .events:    return "事件列表"
        case .scheduler: return "定时运行"
        }
    }

    var systemImage: String {
        switch self {
        case .events:    return "list.bullet.clipboard"
        case .scheduler: return "clock.badge.checkmark"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: EventStore
    @State private var selectedItem: SidebarItem? = .events

    var body: some View {
        if store.isMiniMode {
            if store.isRecording {
                MiniRecordingView()
            } else {
                MiniPlaybackView()
            }
        } else {
            fullView
        }
    }

    private var fullView: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.label, systemImage: item.systemImage)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 220)
            .navigationTitle("MouseRecorder")
            // Badge on events item showing count
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text("v1.0")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                        Spacer()
                        if store.isRecording {
                            Circle().fill(.red).frame(width: 6, height: 6)
                            Text("录制中").font(.caption2).foregroundStyle(.red)
                        } else if store.isPlaying {
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text("回放中").font(.caption2).foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        } detail: {
            switch selectedItem {
            case .events, nil:
                EventListView()
            case .scheduler:
                SchedulerView()
            }
        }
        .frame(minWidth: 820, minHeight: 520)
    }
}
