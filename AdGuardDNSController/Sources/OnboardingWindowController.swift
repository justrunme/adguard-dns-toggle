import Cocoa

class OnboardingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = NSLocalizedString("Добро пожаловать!", comment: "Onboarding title")
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.98).cgColor
        
        // Иконка
        let icon = NSImageView(image: NSImage(systemSymbolName: "shield.lefthalf.fill", accessibilityDescription: nil) ?? NSImage())
        icon.frame = NSRect(x: 186, y: 220, width: 48, height: 48)
        icon.contentTintColor = .systemGreen
        contentView.addSubview(icon)
        
        // Заголовок
        let title = NSTextField(labelWithString: NSLocalizedString("AdGuard DNS Toggle", comment: "Onboarding app name"))
        title.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: 185, width: 420, height: 32)
        contentView.addSubview(title)
        
        // Описание
        let desc = NSTextField(wrappingLabelWithString: NSLocalizedString("• Включайте и выключайте защиту одним кликом.\n• Смотрите статус, диагностику и логи.\n• Настраивайте автозапуск, язык и уведомления.\n\nВсе настройки доступны в меню и окне приложения.", comment: "Onboarding description"))
        desc.font = NSFont.systemFont(ofSize: 15)
        desc.textColor = NSColor.secondaryLabelColor
        desc.alignment = .left
        desc.frame = NSRect(x: 48, y: 80, width: 324, height: 90)
        contentView.addSubview(desc)
        
        // Кнопка "Понятно"
        let button = NSButton(title: NSLocalizedString("Понятно", comment: "Onboarding button"), target: self, action: #selector(closeOnboarding))
        button.frame = NSRect(x: 160, y: 30, width: 100, height: 36)
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        contentView.addSubview(button)
    }
    
    @objc private func closeOnboarding() {
        window?.close()
        UserDefaults.standard.set(true, forKey: "onboarding_shown")
        UserDefaults.standard.synchronize()
    }
} 