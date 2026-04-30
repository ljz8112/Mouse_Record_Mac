import CoreGraphics

enum MouseButton: String, Codable, CaseIterable, Identifiable {
    case left   = "Left"
    case right  = "Right"
    case middle = "Middle"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var downType: CGEventType {
        switch self {
        case .left:   return .leftMouseDown
        case .right:  return .rightMouseDown
        case .middle: return .otherMouseDown
        }
    }

    var upType: CGEventType {
        switch self {
        case .left:   return .leftMouseUp
        case .right:  return .rightMouseUp
        case .middle: return .otherMouseUp
        }
    }

    var cgMouseButton: CGMouseButton {
        switch self {
        case .left:   return .left
        case .right:  return .right
        case .middle: return .center
        }
    }

    var symbolName: String {
        switch self {
        case .left:   return "cursorarrow.click"
        case .right:  return "cursorarrow.click.2"
        case .middle: return "cursorarrow.click.badge.clock"
        }
    }
}
