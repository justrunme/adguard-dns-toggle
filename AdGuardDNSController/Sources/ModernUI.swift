import Cocoa

// MARK: - Modern Card View
class ModernCardView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        let gradient = NSGradient(colors: [NSColor.windowBackgroundColor.withAlphaComponent(0.85), NSColor.controlBackgroundColor.withAlphaComponent(0.7)])
        gradient?.draw(in: path, angle: 90)
        NSColor.separatorColor.withAlphaComponent(0.15).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
}

// MARK: - Info Card
class InfoCard: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private let iconView = NSImageView()
    private var iconColor: NSColor = .secondaryLabelColor
    private var sparklineView: SparklineView?
    
    init(title: String, value: String, icon: NSImage?, iconColor: NSColor = .secondaryLabelColor, showSparkline: Bool = false) {
        super.init(frame: .zero)
        self.iconColor = iconColor
        let localizedTitle = NSLocalizedString(title, comment: "InfoCard title")
        let localizedValue = NSLocalizedString(value, comment: "InfoCard value")
        setupUI(title: localizedTitle, value: localizedValue, icon: icon, showSparkline: showSparkline)
        switch title {
        case "DNS серверы": self.toolTip = NSLocalizedString("Текущие DNS-серверы, используемые системой.", comment: "Tooltip: DNS servers")
        case "Интерфейс": self.toolTip = NSLocalizedString("Активный сетевой интерфейс, через который идёт интернет.", comment: "Tooltip: Interface")
        case "Время работы": self.toolTip = NSLocalizedString("Сколько времени работает DNS-демон.", comment: "Tooltip: Uptime")
        case "Память": self.toolTip = NSLocalizedString("Использование памяти процессом dnsproxy.", comment: "Tooltip: Memory")
        case "Задержка": self.toolTip = NSLocalizedString("Время отклика до серверов AdGuard DNS.", comment: "Tooltip: Latency")
        case "Версия": self.toolTip = NSLocalizedString("Версия приложения.", comment: "Tooltip: Version")
        default: break
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI(title: String, value: String, icon: NSImage?, showSparkline: Bool) {
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.7).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.08
        layer?.shadowRadius = 6
        layer?.shadowOffset = CGSize(width: 0, height: 2)
        
        // Icon
        if let icon = icon {
            iconView.image = icon
            iconView.frame = NSRect(x: 12, y: 12, width: 24, height: 24)
            iconView.contentTintColor = iconColor
            addSubview(iconView)
        }
        
        // Title
        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.frame = NSRect(x: icon != nil ? 44 : 12, y: 24, width: 120, height: 14)
        addSubview(titleLabel)
        
        // Value
        valueLabel.stringValue = value
        valueLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = NSColor.labelColor
        valueLabel.frame = NSRect(x: icon != nil ? 44 : 12, y: 6, width: 120, height: 18)
        addSubview(valueLabel)
        
        // Sparkline
        if showSparkline {
            let spark = SparklineView(frame: NSRect(x: (icon != nil ? 44 : 12) + 80, y: 8, width: 60, height: 16))
            addSubview(spark)
            sparklineView = spark
        }
    }
    
    func updateValue(_ value: String) {
        let localizedValue = NSLocalizedString(value, comment: "InfoCard value update")
        if valueLabel.stringValue != localizedValue {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                valueLabel.animator().alphaValue = 0.0
            }, completionHandler: {
                self.valueLabel.stringValue = localizedValue
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.18
                    self.valueLabel.animator().alphaValue = 1.0
                })
            })
        } else {
            valueLabel.stringValue = localizedValue
        }
    }
    
    func updateSparkline(_ values: [Double]) {
        sparklineView?.update(values: values)
    }
}

// MARK: - Sparkline View
class SparklineView: NSView {
    private var values: [Double] = []
    
    func update(values: [Double]) {
        self.values = values
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard values.count > 1 else { return }
        let path = NSBezierPath()
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = maxValue - minValue == 0 ? 1 : maxValue - minValue
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) / CGFloat(values.count - 1) * bounds.width
            let y = (CGFloat(v - minValue) / CGFloat(range)) * (bounds.height - 2) + 1
            if i == 0 {
                path.move(to: NSPoint(x: x, y: y))
            } else {
                path.line(to: NSPoint(x: x, y: y))
            }
        }
        NSColor.systemGreen.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
}

// MARK: - Status Card (Animated)
class StatusCard: NSView {
    private let statusIndicator = PulsingStatusIndicator()
    private let statusLabel = NSTextField(labelWithString: "")
    private let detailsLabel = NSTextField(labelWithString: "")
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.9).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.10
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: 2)
        
        // Status indicator
        statusIndicator.frame = NSRect(x: 20, y: 18, width: 24, height: 24)
        addSubview(statusIndicator)
        
        // Status label
        statusLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        statusLabel.frame = NSRect(x: 54, y: 26, width: 220, height: 22)
        addSubview(statusLabel)
        
        // Details label
        detailsLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        detailsLabel.textColor = NSColor.secondaryLabelColor
        detailsLabel.frame = NSRect(x: 54, y: 8, width: 220, height: 16)
        addSubview(detailsLabel)
    }
    
    func updateStatus(isActive: Bool, details: String = "") {
        statusIndicator.setActive(isActive)
        statusLabel.stringValue = isActive ? NSLocalizedString("AdGuard DNS активен", comment: "Status active") : NSLocalizedString("AdGuard DNS неактивен", comment: "Status inactive")
        statusLabel.textColor = isActive ? NSColor.systemGreen : NSColor.systemRed
        detailsLabel.stringValue = NSLocalizedString(details, comment: "Status details")
    }
}

// MARK: - Pulsing Status Indicator
class PulsingStatusIndicator: NSView {
    private var isActive: Bool = false
    private var pulseLayer: CAShapeLayer = CAShapeLayer()
    private var animation: CABasicAnimation?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        pulseLayer.path = CGPath(ellipseIn: bounds, transform: nil)
        pulseLayer.fillColor = NSColor.systemGreen.cgColor
        layer?.addSublayer(pulseLayer)
    }
    
    func setActive(_ active: Bool) {
        isActive = active
        pulseLayer.fillColor = (active ? NSColor.systemGreen : NSColor.systemRed).cgColor
        animatePulse(active: active)
    }
    
    private func animatePulse(active: Bool) {
        pulseLayer.removeAllAnimations()
        if active {
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.0
            pulse.toValue = 1.18
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulseLayer.add(pulse, forKey: "pulse")
        }
    }
}

// MARK: - Modern Toggle Button (Animated)
class ModernToggleButton: NSButton {
    private var isActive: Bool = false
    private var gradientLayer: CAGradientLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        wantsLayer = true
        layer?.cornerRadius = 22
        layer?.masksToBounds = true
        
        // Gradient background
        gradientLayer = CAGradientLayer()
        gradientLayer?.frame = bounds
        gradientLayer?.cornerRadius = 22
        gradientLayer?.colors = [NSColor.systemOrange.cgColor, NSColor.systemRed.cgColor]
        gradientLayer?.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer?.endPoint = CGPoint(x: 1, y: 1)
        layer?.addSublayer(gradientLayer!)
        
        // Button style
        isBordered = false
        font = NSFont.systemFont(ofSize: 17, weight: .bold)
        contentTintColor = NSColor.white
        
        // Shadow
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: 2)
        layer?.shadowOpacity = 0.18
        layer?.shadowRadius = 8
    }
    
    override func layout() {
        super.layout()
        gradientLayer?.frame = bounds
    }
    
    func updateState(isActive: Bool) {
        self.isActive = isActive
        let colors = isActive ?
            [NSColor.systemRed.cgColor, NSColor.systemOrange.cgColor] :
            [NSColor.systemGreen.cgColor, NSColor.systemTeal.cgColor]
        gradientLayer?.colors = colors
        title = isActive ? NSLocalizedString("Выключить защиту", comment: "Toggle button disable") : NSLocalizedString("Включить защиту", comment: "Toggle button enable")
        contentTintColor = NSColor.white
        // Scale анимация
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            self.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 1.08, y: 1.08))
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                self.animator().layer?.setAffineTransform(.identity)
            }
        }
    }
    
    func setLoading(_ loading: Bool) {
        isEnabled = !loading
        if loading {
            title = isActive ? NSLocalizedString("Выключение...", comment: "Toggle button disabling") : NSLocalizedString("Включение...", comment: "Toggle button enabling")
            animatePulse()
        } else {
            layer?.removeAllAnimations()
        }
    }
    
    private func animatePulse() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.08
        pulse.duration = 0.18
        pulse.autoreverses = true
        pulse.repeatCount = 2
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer?.add(pulse, forKey: "pulse")
    }
} 