import Cocoa

class ModernButton: NSButton {
    private let gradient = CAGradientLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }

    init(frame: NSRect, title: String) {
        super.init(frame: frame)
        self.title = title
        commonInit()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func commonInit() {
        wantsLayer = true
        isBordered = false
        font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        contentTintColor = .white
        setButtonType(.momentaryPushIn)
        layer?.cornerRadius = 22
        layer?.masksToBounds = true

        gradient.colors = [NSColor.systemGreen.cgColor, NSColor.systemTeal.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = bounds
        gradient.cornerRadius = 22
        layer?.insertSublayer(gradient, at: 0)

        layer?.shadowOpacity = 0.2
        layer?.shadowRadius = 4
        layer?.shadowOffset = CGSize(width: 0, height: 2)

        let tracking = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
        addTrackingArea(tracking)
    }

    override func layout() {
        super.layout()
        gradient.frame = bounds
    }

    func updateGradient(colors: [CGColor]) {
        gradient.colors = colors
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 0.8
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1.0
        }
    }
}