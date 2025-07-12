import Cocoa

class StatusIndicator: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = frame.width / 2
        layer?.backgroundColor = NSColor.systemRed.cgColor
        layer?.shadowOpacity = 0.2
        layer?.shadowRadius = 2
        layer?.shadowOffset = CGSize(width: 0, height: 1)
        layer?.shadowColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setColor(_ color: NSColor) {
        layer?.backgroundColor = color.cgColor
    }
}