import Cocoa

class PreferencesWindowController: NSWindowController {
    private var launchAtLoginCheckbox: NSButton!
    private var languagePopup: NSPopUpButton!
    private var notificationsCheckbox: NSButton!
    private var connectionMonitoringCheckbox: NSButton!
    private var soundNotificationsCheckbox: NSButton!
    private var dnsServerPopup: NSPopUpButton!
    private var portTextField: NSTextField!
    private var customDnsTextField: NSTextField!
    private var autoSwitchNetworkCheckbox: NSButton!
    private var resetButton: NSButton!
    private var applyButton: NSButton!
    private var cancelButton: NSButton!
    
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = NSLocalizedString("Настройки", comment: "Preferences window title")
        window.level = .floating
        self.init(window: window)
        setupUI()
        centerWindow()
    }
    
    private func centerWindow() {
        guard let window = self.window else { return }
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let mainWindow = appDelegate.window,
           mainWindow.isVisible {
            let mainFrame = mainWindow.frame
            let prefsFrame = window.frame
            let newX = mainFrame.midX - prefsFrame.width / 2
            let newY = mainFrame.midY - prefsFrame.height / 2
            window.setFrameOrigin(NSPoint(x: newX, y: newY))
        } else {
            let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
            let windowFrame = window.frame
            let newX = screenFrame.midX - windowFrame.width / 2
            let newY = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: newX, y: newY))
        }
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.98).cgColor
        
        // --- DNS настройки ---
        let dnsIcon = NSImageView(image: NSImage(systemSymbolName: "network", accessibilityDescription: nil) ?? NSImage())
        dnsIcon.frame = NSRect(x: 20, y: 480, width: 20, height: 20)
        dnsIcon.contentTintColor = .systemBlue
        contentView.addSubview(dnsIcon)
        let dnsLabel = NSTextField(labelWithString: NSLocalizedString("DNS настройки", comment: "Preferences section: DNS Settings"))
        dnsLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        dnsLabel.frame = NSRect(x: 48, y: 480, width: 200, height: 20)
        contentView.addSubview(dnsLabel)
        
        // DNS серверы AdGuard
        let dnsServerLabel = NSTextField(labelWithString: NSLocalizedString("DNS серверы AdGuard:", comment: "AdGuard DNS servers"))
        dnsServerLabel.font = NSFont.systemFont(ofSize: 12)
        dnsServerLabel.frame = NSRect(x: 48, y: 435, width: 150, height: 18)
        contentView.addSubview(dnsServerLabel)
        
        dnsServerPopup = NSPopUpButton(frame: NSRect(x: 48, y: 410, width: 200, height: 26))
        dnsServerPopup.addItems(withTitles: [
            NSLocalizedString("Default (176.103.130.130)", comment: "Default DNS"),
            NSLocalizedString("Family (176.103.130.132)", comment: "Family DNS"),
            NSLocalizedString("Non-filtering (176.103.130.131)", comment: "Non-filtering DNS"),
            NSLocalizedString("Пользовательские", comment: "Custom DNS")
        ])
        let currentDns = PreferencesWindowController.getCurrentDnsServer()
        dnsServerPopup.selectItem(at: currentDns)
        dnsServerPopup.target = self
        dnsServerPopup.action = #selector(dnsServerChanged)
        contentView.addSubview(dnsServerPopup)
        
        // Порт
        let portLabel = NSTextField(labelWithString: NSLocalizedString("Порт dnsproxy:", comment: "dnsproxy port"))
        portLabel.font = NSFont.systemFont(ofSize: 12)
        portLabel.frame = NSRect(x: 48, y: 385, width: 120, height: 18)
        contentView.addSubview(portLabel)
        
        portTextField = NSTextField(frame: NSRect(x: 48, y: 360, width: 80, height: 24))
        portTextField.stringValue = PreferencesWindowController.getDnsProxyPort()
        portTextField.font = NSFont.systemFont(ofSize: 12)
        contentView.addSubview(portTextField)
        
        // Пользовательские DNS
        let customDnsLabel = NSTextField(labelWithString: NSLocalizedString("Пользовательские DNS (через запятую):", comment: "Custom DNS servers"))
        customDnsLabel.font = NSFont.systemFont(ofSize: 12)
        customDnsLabel.frame = NSRect(x: 48, y: 335, width: 250, height: 18)
        contentView.addSubview(customDnsLabel)
        
        customDnsTextField = NSTextField(frame: NSRect(x: 48, y: 310, width: 360, height: 24))
        customDnsTextField.stringValue = PreferencesWindowController.getCustomDnsServers()
        customDnsTextField.font = NSFont.systemFont(ofSize: 12)
        customDnsTextField.placeholderString = "8.8.8.8, 1.1.1.1"
        contentView.addSubview(customDnsTextField)
        
        // Автопереключение при смене сети
        autoSwitchNetworkCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Автоматически переключать при смене сети", comment: "Auto switch on network change"), target: self, action: #selector(toggleAutoSwitchNetwork))
        autoSwitchNetworkCheckbox.frame = NSRect(x: 48, y: 280, width: 360, height: 24)
        autoSwitchNetworkCheckbox.state = PreferencesWindowController.isAutoSwitchNetworkEnabled() ? .on : .off
        contentView.addSubview(autoSwitchNetworkCheckbox)
        
        // --- Общие ---
        let generalIcon = NSImageView(image: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) ?? NSImage())
        generalIcon.frame = NSRect(x: 20, y: 240, width: 20, height: 20)
        generalIcon.contentTintColor = .systemGray
        contentView.addSubview(generalIcon)
        let generalLabel = NSTextField(labelWithString: NSLocalizedString("Общие", comment: "Preferences section: General"))
        generalLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        generalLabel.frame = NSRect(x: 48, y: 240, width: 200, height: 20)
        contentView.addSubview(generalLabel)
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Запускать при входе в систему", comment: "Launch at login checkbox"), target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.frame = NSRect(x: 48, y: 215, width: 360, height: 24)
        launchAtLoginCheckbox.state = PreferencesWindowController.isLaunchAtLoginEnabled() ? .on : .off
        contentView.addSubview(launchAtLoginCheckbox)
        
        // --- Уведомления ---
        let notifIcon = NSImageView(image: NSImage(systemSymbolName: "bell", accessibilityDescription: nil) ?? NSImage())
        notifIcon.frame = NSRect(x: 20, y: 175, width: 20, height: 20)
        notifIcon.contentTintColor = .systemGray
        contentView.addSubview(notifIcon)
        let notifLabel = NSTextField(labelWithString: NSLocalizedString("Уведомления", comment: "Preferences section: Notifications"))
        notifLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        notifLabel.frame = NSRect(x: 48, y: 175, width: 200, height: 20)
        contentView.addSubview(notifLabel)
        notificationsCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Показывать уведомления о статусе защиты", comment: "Show protection status notifications"), target: self, action: #selector(toggleNotifications))
        notificationsCheckbox.frame = NSRect(x: 48, y: 150, width: 360, height: 24)
        notificationsCheckbox.state = PreferencesWindowController.areNotificationsEnabled() ? .on : .off
        contentView.addSubview(notificationsCheckbox)
        soundNotificationsCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Звуковые уведомления", comment: "Sound notifications"), target: self, action: #selector(toggleSoundNotifications))
        soundNotificationsCheckbox.frame = NSRect(x: 48, y: 125, width: 360, height: 24)
        soundNotificationsCheckbox.state = PreferencesWindowController.areSoundNotificationsEnabled() ? .on : .off
        contentView.addSubview(soundNotificationsCheckbox)
        connectionMonitoringCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Мониторинг соединения с AdGuard DNS", comment: "Connection monitoring"), target: self, action: #selector(toggleConnectionMonitoring))
        connectionMonitoringCheckbox.frame = NSRect(x: 48, y: 100, width: 360, height: 24)
        connectionMonitoringCheckbox.state = PreferencesWindowController.isConnectionMonitoringEnabled() ? .on : .off
        contentView.addSubview(connectionMonitoringCheckbox)
        
        // --- Язык ---
        let langIcon = NSImageView(image: NSImage(systemSymbolName: "globe", accessibilityDescription: nil) ?? NSImage())
        langIcon.frame = NSRect(x: 20, y: 55, width: 20, height: 20)
        langIcon.contentTintColor = .systemGray
        contentView.addSubview(langIcon)
        let langLabel = NSTextField(labelWithString: NSLocalizedString("Язык интерфейса", comment: "Preferences section: Language"))
        langLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        langLabel.frame = NSRect(x: 48, y: 55, width: 200, height: 20)
        contentView.addSubview(langLabel)
        languagePopup = NSPopUpButton(frame: NSRect(x: 48, y: 25, width: 120, height: 26))
        languagePopup.addItems(withTitles: [NSLocalizedString("Системный", comment: "System language"), "Русский", "English", "Deutsch"])
        let currentLang = PreferencesWindowController.getCurrentLanguage()
        switch currentLang {
        case "ru": languagePopup.selectItem(at: 1)
        case "en": languagePopup.selectItem(at: 2)
        case "de": languagePopup.selectItem(at: 3)
        default: languagePopup.selectItem(at: 0)
        }
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        contentView.addSubview(languagePopup)

        // --- Разделитель ---
        let sep = NSBox(frame: NSRect(x: 0, y: 56, width: 460, height: 1))
        sep.boxType = .separator
        contentView.addSubview(sep)

        // --- Кнопка "По умолчанию" справа внизу ---
        let buttonWidth: CGFloat = 120
        let buttonHeight: CGFloat = 32
        let buttonX = contentView.frame.width - buttonWidth - 20
        let buttonY: CGFloat = 20
        resetButton = NSButton(title: NSLocalizedString("По умолчанию", comment: "Reset to defaults button"), target: self, action: #selector(resetToDefaults))
        resetButton.frame = NSRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        resetButton.bezelStyle = .rounded
        contentView.addSubview(resetButton)
    }
    
    @objc private func toggleLaunchAtLogin() {
        let enabled = (launchAtLoginCheckbox.state == .on)
        PreferencesWindowController.setLaunchAtLogin(enabled)
    }
    
    @objc private func toggleNotifications() {
        let enabled = (notificationsCheckbox.state == .on)
        PreferencesWindowController.setNotificationsEnabled(enabled)
    }
    
    @objc private func toggleSoundNotifications() {
        let enabled = (soundNotificationsCheckbox.state == .on)
        PreferencesWindowController.setSoundNotificationsEnabled(enabled)
    }
    
    @objc private func toggleConnectionMonitoring() {
        let enabled = (connectionMonitoringCheckbox.state == .on)
        PreferencesWindowController.setConnectionMonitoringEnabled(enabled)
        
        if enabled {
            ConnectionMonitor.shared.startMonitoring()
        } else {
            ConnectionMonitor.shared.stopMonitoring()
        }
    }
    
    @objc private func toggleAutoSwitchNetwork() {
        let enabled = (autoSwitchNetworkCheckbox.state == .on)
        PreferencesWindowController.setAutoSwitchNetworkEnabled(enabled)
    }
    
    @objc private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Сбросить настройки", comment: "Reset settings alert title")
        alert.informativeText = NSLocalizedString("Все настройки будут сброшены к значениям по умолчанию. Продолжить?", comment: "Reset settings alert message")
        alert.addButton(withTitle: NSLocalizedString("Сбросить", comment: "Reset button"))
        alert.addButton(withTitle: NSLocalizedString("Отмена", comment: "Cancel button"))
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Сброс всех настроек к значениям по умолчанию
            resetAllSettingsToDefaults()
            updateUIFromDefaults()
            
            let successAlert = NSAlert()
            successAlert.messageText = NSLocalizedString("Настройки сброшены", comment: "Settings reset success")
            successAlert.informativeText = NSLocalizedString("Все настройки восстановлены к значениям по умолчанию.", comment: "Settings reset success message")
            successAlert.runModal()
        }
    }
    
    private func resetAllSettingsToDefaults() {
        // Сброс всех настроек к значениям по умолчанию
        UserDefaults.standard.removeObject(forKey: "dns_server_type")
        UserDefaults.standard.removeObject(forKey: "dnsproxy_port")
        UserDefaults.standard.removeObject(forKey: "custom_dns_servers")
        UserDefaults.standard.removeObject(forKey: "auto_switch_network")
        UserDefaults.standard.removeObject(forKey: "sound_notifications_enabled")
        UserDefaults.standard.removeObject(forKey: "notifications_enabled")
        UserDefaults.standard.removeObject(forKey: "connection_monitoring_enabled")
        UserDefaults.standard.removeObject(forKey: "ad_block_notifications_enabled")
        UserDefaults.standard.synchronize()
        
        // Отключение автозапуска
        PreferencesWindowController.setLaunchAtLogin(false)
        
        // Сброс языка к системному
        PreferencesWindowController.setLanguage(nil)
    }
    
    private func updateUIFromDefaults() {
        // Обновляем UI после сброса настроек
        dnsServerPopup.selectItem(at: 0) // Default
        portTextField.stringValue = "53535"
        customDnsTextField.stringValue = ""
        autoSwitchNetworkCheckbox.state = .off
        soundNotificationsCheckbox.state = .off
        notificationsCheckbox.state = .off
        connectionMonitoringCheckbox.state = .off
        launchAtLoginCheckbox.state = .off
        languagePopup.selectItem(at: 0) // System
    }
    
    @objc private func dnsServerChanged() {
        let selectedIndex = dnsServerPopup.indexOfSelectedItem
        PreferencesWindowController.setCurrentDnsServer(selectedIndex)
        
        // Если выбраны пользовательские DNS, активируем поле ввода
        customDnsTextField.isEnabled = (selectedIndex == 3)
    }
    
    @objc private func languageChanged() {
        let idx = languagePopup.indexOfSelectedItem
        let lang: String?
        switch idx {
        case 1: lang = "ru"
        case 2: lang = "en"
        case 3: lang = "de"
        default: lang = nil // системный
        }
        PreferencesWindowController.setLanguage(lang)
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Требуется перезапуск", comment: "Restart required")
        alert.informativeText = NSLocalizedString("Для применения языка перезапустите приложение.", comment: "Restart to apply language")
        alert.runModal()
    }
    
    // MARK: - DNS Settings
    static func getCurrentDnsServer() -> Int {
        return UserDefaults.standard.integer(forKey: "dns_server_type")
    }
    
    static func setCurrentDnsServer(_ type: Int) {
        UserDefaults.standard.set(type, forKey: "dns_server_type")
        UserDefaults.standard.synchronize()
    }
    
    static func getDnsProxyPort() -> String {
        return UserDefaults.standard.string(forKey: "dnsproxy_port") ?? "53535"
    }
    
    static func setDnsProxyPort(_ port: String) {
        UserDefaults.standard.set(port, forKey: "dnsproxy_port")
        UserDefaults.standard.synchronize()
    }
    
    static func getCustomDnsServers() -> String {
        return UserDefaults.standard.string(forKey: "custom_dns_servers") ?? ""
    }
    
    static func setCustomDnsServers(_ servers: String) {
        UserDefaults.standard.set(servers, forKey: "custom_dns_servers")
        UserDefaults.standard.synchronize()
    }
    
    static func isAutoSwitchNetworkEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "auto_switch_network")
    }
    
    static func setAutoSwitchNetworkEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "auto_switch_network")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Sound Notifications
    static func areSoundNotificationsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "sound_notifications_enabled")
    }
    
    static func setSoundNotificationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "sound_notifications_enabled")
        UserDefaults.standard.synchronize()
    }
    
    // Быстрая реализация через LaunchAgent (можно заменить на login helper)
    static func isLaunchAtLoginEnabled() -> Bool {
        let fm = FileManager.default
        let agentPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/LaunchAgents/com.adguard.toggle.menu.plist")
        return fm.fileExists(atPath: agentPath)
    }
    static func setLaunchAtLogin(_ enabled: Bool) {
        let agentPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/LaunchAgents/com.adguard.toggle.menu.plist")
        let appPath = Bundle.main.bundlePath + "/Contents/MacOS/AdGuard DNS Toggle"
        let plist: [String: Any] = [
            "Label": "com.adguard.toggle.menu",
            "ProgramArguments": [appPath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        if enabled {
            let dict = plist as NSDictionary
            dict.write(toFile: agentPath, atomically: true)
            _ = shell(["launchctl", "load", agentPath])
        } else {
            _ = shell(["launchctl", "unload", agentPath])
            try? FileManager.default.removeItem(atPath: agentPath)
        }
    }
    static func getCurrentLanguage() -> String? {
        let langs = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
        guard let lang = langs?.first else { return nil }
        if lang.hasPrefix("ru") { return "ru" }
        if lang.hasPrefix("en") { return "en" }
        if lang.hasPrefix("de") { return "de" }
        return nil
    }
    static func setLanguage(_ lang: String?) {
        if let lang = lang {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Notification Settings
    static func areNotificationsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "notifications_enabled")
    }
    
    static func setNotificationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "notifications_enabled")
        UserDefaults.standard.synchronize()
    }
    
    static func isConnectionMonitoringEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "connection_monitoring_enabled")
    }
    
    static func setConnectionMonitoringEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "connection_monitoring_enabled")
        UserDefaults.standard.synchronize()
    }
}

// Вспомогательная функция для shell-команд
@discardableResult
func shell(_ args: [String]) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", args.joined(separator: " ")]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
} 