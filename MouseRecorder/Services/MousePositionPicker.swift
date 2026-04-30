import AppKit

// MARK: - Controller

final class MousePositionPicker: NSObject {
    static let shared = MousePositionPicker()

    private var overlayWindow: MousePickerWindow?
    private var hiddenWindows: [NSWindow] = []
    var onCoordinatePicked: ((Double, Double) -> Void)?

    func show(onPicked: @escaping (Double, Double) -> Void) {
        guard overlayWindow == nil else { return }
        self.onCoordinatePicked = onPicked

        // Make all titled app windows invisible without removing them from the
        // window hierarchy. Using alphaValue=0 (instead of orderOut) keeps the
        // app active so the picker panel can immediately become key.
        hiddenWindows = NSApp.windows.filter {
            $0.isVisible && !($0 is NSPanel) && $0.styleMask.contains(.titled)
        }
        hiddenWindows.forEach { $0.alphaValue = 0 }

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let window = MousePickerWindow(screen: screen)
        window.pickerDelegate = self
        window.makeKeyAndOrderFront(nil)
        NSCursor.crosshair.push()
        overlayWindow = window
    }

    fileprivate func finish(cgX: Double, cgY: Double) {
        tearDown()
        onCoordinatePicked?(cgX, cgY)
        onCoordinatePicked = nil
    }

    fileprivate func cancel() {
        tearDown()
        onCoordinatePicked = nil
    }

    private func tearDown() {
        NSCursor.pop()
        overlayWindow?.orderOut(nil)
        overlayWindow?.pickerDelegate = nil
        overlayWindow = nil

        // Restore window visibility
        hiddenWindows.forEach { $0.alphaValue = 1 }
        hiddenWindows = []
    }
}

// MARK: - Window

final class MousePickerWindow: NSPanel {
    weak var pickerDelegate: MousePositionPicker?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) - 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        acceptsMouseMovedEvents = true
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = MousePickerView(frame: screen.frame)
        view.pickerDelegate = self
        contentView = view
        makeFirstResponder(view)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func finish(cgX: Double, cgY: Double) { pickerDelegate?.finish(cgX: cgX, cgY: cgY) }
    func cancel() { pickerDelegate?.cancel() }
}

// MARK: - View

final class MousePickerView: NSView {
    weak var pickerDelegate: MousePickerWindow?

    /// Current mouse position in this view's coordinate space (AppKit: bottom-left origin)
    private var mousePos: CGPoint = .zero
    /// CGEvent-space coords (top-left origin) for display
    private var displayX: Double = 0
    private var displayY: Double = 0

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }

    // MARK: Mouse events

    override func mouseMoved(with event: NSEvent) {
        mousePos = convert(event.locationInWindow, from: nil)
        updateDisplayCoords(viewPoint: mousePos)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        // Capture coords — do NOT call super so the click is swallowed
        let vp = convert(event.locationInWindow, from: nil)
        updateDisplayCoords(viewPoint: vp)
        pickerDelegate?.finish(cgX: displayX, cgY: displayY)
    }

    override func rightMouseDown(with event: NSEvent) {
        pickerDelegate?.cancel()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { pickerDelegate?.cancel() } // Esc
    }

    // MARK: Coordinate conversion

    private func updateDisplayCoords(viewPoint: CGPoint) {
        // Convert view-local point → screen point (AppKit, bottom-left origin)
        guard let win = window else { return }
        let screenPt = win.convertToScreen(NSRect(origin: viewPoint, size: .zero)).origin
        // Flip Y to get CGEvent space (top-left origin), using the screen that contains the point
        let screen = NSScreen.screens.first(where: { $0.frame.contains(screenPt) })
                     ?? NSScreen.main
                     ?? NSScreen.screens[0]
        displayX = screenPt.x - screen.frame.minX
        displayY = screen.frame.height - (screenPt.y - screen.frame.minY)
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Semi-transparent overlay
        NSColor(white: 0, alpha: 0.38).setFill()
        dirtyRect.fill()

        drawCrosshair()
        drawCoordinateTooltip()
        drawHint()
    }

    private func drawCrosshair() {
        let path = NSBezierPath()
        path.lineWidth = 0.75

        // Dashed lines in two colours for contrast on any background
        NSColor.white.withAlphaComponent(0.75).setStroke()
        path.removeAllPoints()
        path.move(to: CGPoint(x: 0, y: mousePos.y))
        path.line(to: CGPoint(x: bounds.width, y: mousePos.y))
        path.move(to: CGPoint(x: mousePos.x, y: 0))
        path.line(to: CGPoint(x: mousePos.x, y: bounds.height))
        path.setLineDash([6, 4], count: 2, phase: 0)
        path.stroke()

        // Small solid square at cursor
        let sq: CGFloat = 8
        let origin = CGPoint(x: mousePos.x - sq / 2, y: mousePos.y - sq / 2)
        let dot = NSBezierPath(rect: NSRect(origin: origin, size: CGSize(width: sq, height: sq)))
        NSColor.white.setFill()
        dot.fill()
    }

    private func drawCoordinateTooltip() {
        let text = String(format: "  X: %.0f    Y: %.0f  ", displayX, displayY)
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let size = attrStr.size()
        let padding: CGFloat = 6

        // Position tooltip to the lower-right of cursor, flip if near edge
        var ox = mousePos.x + 18
        var oy = mousePos.y - size.height - 12
        if ox + size.width + padding > bounds.width  { ox = mousePos.x - size.width - padding - 18 }
        if oy < 0 { oy = mousePos.y + 14 }

        let bgRect = NSRect(x: ox - padding, y: oy - padding / 2,
                            width: size.width + padding * 2, height: size.height + padding)
        let bg = NSBezierPath(roundedRect: bgRect, xRadius: 6, yRadius: 6)
        NSColor(white: 0, alpha: 0.72).setFill()
        bg.fill()

        attrStr.draw(at: CGPoint(x: ox, y: oy))
    }

    private func drawHint() {
        let hint = "单击确定位置  ·  右键 / Esc 取消"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.85)
        ]
        let attrStr = NSAttributedString(string: hint, attributes: attrs)
        let sz = attrStr.size()
        let px = (bounds.width - sz.width) / 2
        let py = bounds.height - 52
        let bgRect = NSRect(x: px - 14, y: py - 7, width: sz.width + 28, height: sz.height + 14)
        let bg = NSBezierPath(roundedRect: bgRect, xRadius: 10, yRadius: 10)
        NSColor(white: 0, alpha: 0.55).setFill()
        bg.fill()
        attrStr.draw(at: CGPoint(x: px, y: py))
    }
}
