import AppKit
import ApplicationServices

enum AccessibilityPermissionService {

    static func isGranted() -> Bool {
        AXIsProcessTrustedWithOptions(nil)
    }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
