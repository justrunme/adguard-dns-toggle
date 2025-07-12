import Cocoa

class OnboardingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 460),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = NSLocalizedString("Добро пожаловать!", comment: "Onboarding title")
        window.level = .floating
        window.isMovableByWindowBackground = false
        window.center()
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 20
        contentView.layer?.masksToBounds = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.98).cgColor
        setupHeader(contentView: contentView)
        setupContent(contentView: contentView)
        setupButton(contentView: contentView)
    }
    
    private func setupHeader(contentView: NSView) {
        let width: CGFloat = 480
        let height: CGFloat = 460
        let avatarSize: CGFloat = 80
        let avatarView = NSView(frame: NSRect(x: (width - avatarSize)/2, y: height - 120, width: avatarSize, height: avatarSize))
        avatarView.wantsLayer = true
        let gradient = CAGradientLayer()
        gradient.frame = avatarView.bounds
        gradient.colors = [NSColor.systemGreen.cgColor, NSColor.systemTeal.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = avatarSize/2
        avatarView.layer?.addSublayer(gradient)
        avatarView.layer?.cornerRadius = avatarSize/2
        avatarView.layer?.shadowColor = NSColor.black.cgColor
        avatarView.layer?.shadowOpacity = 0.2
        avatarView.layer?.shadowRadius = 10
        avatarView.layer?.shadowOffset = CGSize(width: 0, height: 3)
        contentView.addSubview(avatarView)
        let icon = NSImageView(image: NSImage(systemSymbolName: "shield.lefthalf.fill", accessibilityDescription: nil) ?? NSImage())
        icon.frame = NSRect(x: (avatarSize-48)/2, y: (avatarSize-48)/2, width: 48, height: 48)
        icon.contentTintColor = .white
        avatarView.addSubview(icon)
        let titleLabel = NSTextField(labelWithString: NSLocalizedString("AdGuard DNS Toggle", comment: "Onboarding app name"))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: height - 160, width: width - 40, height: 30)
        contentView.addSubview(titleLabel)
        let subtitleLabel = NSTextField(labelWithString: NSLocalizedString("Добро пожаловать!", comment: "Onboarding subtitle"))
        subtitleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.frame = NSRect(x: 20, y: height - 185, width: width - 40, height: 20)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupContent(contentView: NSView) {
        let width: CGFloat = 480
        let height: CGFloat = 460
        let features = [
            (icon: "shield.checkered", title: NSLocalizedString("Защита одним кликом", comment: "Feature 1"), desc: NSLocalizedString("Включайте и выключайте AdGuard DNS защиту мгновенно", comment: "Feature 1 desc")),
            (icon: "chart.line.uptrend.xyaxis", title: NSLocalizedString("Мониторинг в реальном времени", comment: "Feature 2"), desc: NSLocalizedString("Следите за статусом, задержкой и использованием ресурсов", comment: "Feature 2 desc")),
            (icon: "gear", title: NSLocalizedString("Гибкие настройки", comment: "Feature 3"), desc: NSLocalizedString("Настраивайте DNS серверы, уведомления и автозапуск", comment: "Feature 3 desc"))
        ]
        let cardHeight: CGFloat = 120
        let cardWidth: CGFloat = width - 80
        let startY = height - 250
        for (index, feature) in features.enumerated() {
            let card = createFeatureCard(
                icon: feature.icon,
                title: feature.title,
                description: feature.desc,
                frame: NSRect(x: 40, y: startY - CGFloat(index * 130), width: cardWidth, height: cardHeight)
            )
            contentView.addSubview(card)
        }
    }
    
    private func createFeatureCard(icon: String, title: String, description: String, frame: NSRect) -> NSView {
        let card = NSView(frame: frame)
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6).cgColor
        card.layer?.cornerRadius = 12
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
        let iconView = NSImageView(image: NSImage(systemSymbolName: icon, accessibilityDescription: nil) ?? NSImage())
        iconView.frame = NSRect(x: 16, y: frame.height-44, width: 24, height: 24)
        iconView.contentTintColor = .systemBlue
        card.addSubview(iconView)
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 56, y: frame.height-36, width: frame.width - 72, height: 18)
        card.addSubview(titleLabel)
        let descLabel = NSTextField(wrappingLabelWithString: description)
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = NSColor.secondaryLabelColor
        descLabel.frame = NSRect(x: 56, y: 12, width: frame.width - 72, height: frame.height-48)
        descLabel.lineBreakMode = .byWordWrapping
        card.addSubview(descLabel)
        return card
    }
    
    private func setupButton(contentView: NSView) {
        let width: CGFloat = 480
        let button = NSButton(title: NSLocalizedString("Начать", comment: "Onboarding start button"), target: self, action: #selector(closeOnboarding))
        button.frame = NSRect(x: (width - 120)/2, y: 30, width: 120, height: 40)
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        button.wantsLayer = true
        button.layer?.cornerRadius = 20
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        button.contentTintColor = .white
        contentView.addSubview(button)
    }
    
    @objc private func closeOnboarding() {
        window?.close()
        UserDefaults.standard.set(true, forKey: "onboarding_shown")
        UserDefaults.standard.synchronize()
    }
} 