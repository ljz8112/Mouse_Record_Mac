import Foundation
import AppKit
import UniformTypeIdentifiers

enum ImportExportService {

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func export(_ events: [MouseClickEvent]) {
        guard let data = try? encoder.encode(events) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MouseRecorderEvents.json"
        panel.title = "Export Mouse Events"
        panel.message = "Choose where to save your event list."
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func `import`(into store: EventStore) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import Mouse Events"
        panel.message = "Select a MouseRecorder JSON file."

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url),
              let imported = try? decoder.decode([MouseClickEvent].self, from: data)
        else {
            showImportError()
            return
        }

        // Re-mint UUIDs to avoid collisions with existing events
        let fresh = imported.map { event -> MouseClickEvent in
            var e = event
            e.id = UUID()
            return e
        }
        store.events.append(contentsOf: fresh)
    }

    private static func showImportError() {
        let alert = NSAlert()
        alert.messageText = "Import Failed"
        alert.informativeText = "The selected file is not a valid MouseRecorder events file."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
