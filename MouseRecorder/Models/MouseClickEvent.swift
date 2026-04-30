import Foundation
import CoreGraphics

struct MouseClickEvent: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var x: Double
    var y: Double
    var button: MouseButton
    var delayBeforeFire: TimeInterval
    var timestamp: Date

    init(
        id: UUID = UUID(),
        name: String,
        x: Double,
        y: Double,
        button: MouseButton,
        delayBeforeFire: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.button = button
        self.delayBeforeFire = delayBeforeFire
        self.timestamp = timestamp
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }

    var delayDescription: String {
        if delayBeforeFire < 0.001 { return "0 s" }
        return String(format: "%.2f s", delayBeforeFire)
    }
}
