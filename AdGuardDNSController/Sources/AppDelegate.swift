import Cocoa
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, UNUserNotificationCenterDelegate {
    private let logger = AppLogger.app
    private let uiLogger = AppLogger.ui
    
    // MARK: - UI Components
    var window: NSWindow!
    var statusCard: AnimatedStatusCard!
    var toggleButton: AnimatedToggleButton!
    var infoCards: [InfoCard] = []
    var diagnosticsButton: NSButton!
    var diagnosticsWindow: DiagnosticsWindowController?
    var statusItem: NSStatusItem!
    var preferencesWindow: PreferencesWindowController?
    private var onboardingWindow: NSWindow?
    
    // MARK: - State
    var isAdGuardEnabled = false
    var timer: Timer?
    var infoUpdateTimer: Timer?
    var latencyHistory: [Double] = Array(repeating: 0, count: 10)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        logToFile("App started")
        _ = SystemInfo.runDiagnostics()
        logger.info("Application did finish launching")
        
        // Настройка делегата уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        // Запуск менеджера тем
        ThemeManager.shared.startThemeObserver()
        
        // Запуск менеджера горячих клавиш
        _ = HotKeyManager.shared
        
        setupStatusItem()
        setupUI()
        checkStatus()
        startStatusMonitoring()
        startInfoMonitoring()
        startConnectionMonitoring()
        showOnboardingIfNeeded()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Показываем окно при клике на иконку в Dock
        if !flag {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Показываем окно при активации приложения
        if !window.isVisible {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private func showOnboardingIfNeeded() {
        let shown = UserDefaults.standard.bool(forKey: "onboarding_shown")
        if !shown {
            let hosting = NSHostingController(rootView: OnboardingView())
            onboardingWindow = NSWindow(contentViewController: hosting)
            onboardingWindow?.title = NSLocalizedString("Добро пожаловать!", comment: "Onboarding title")
            onboardingWindow?.styleMask = [.titled, .closable]
            onboardingWindow?.level = .modalPanel
            onboardingWindow?.center()
            onboardingWindow?.ignoresMouseEvents = false
            onboardingWindow?.acceptsMouseMovedEvents = true
            onboardingWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // Скрываем главное окно пока показывается onboarding
            window.orderOut(nil)
        }
    }
    
    private func startStatusMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: Config.ui.timing.statusCheckInterval, repeats: true) { _ in
            self.checkStatus()
        }
        logger.info("Status monitoring started with interval: \(Config.ui.timing.statusCheckInterval)s")
    }
    
    private func startInfoMonitoring() {
        infoUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateInfoCards()
        }
        logger.info("Info monitoring started with interval: 5s")
    }
    
    private func startConnectionMonitoring() {
        if PreferencesWindowController.isConnectionMonitoringEnabled() {
            ConnectionMonitor.shared.startMonitoring()
            logger.info("Connection monitoring started")
        } else {
            logger.info("Connection monitoring disabled in preferences")
        }
    }

    func setupUI() {
        uiLogger.info("Setting up UI")
        let width: CGFloat = 420
        let height: CGFloat = 580
        let screenSize = NSScreen.main!.visibleFrame

        window = NSWindow(
            contentRect: NSRect(x: (screenSize.width-width)/2, y: (screenSize.height-height)/2, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString(Config.app.name, comment: "App name")
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Настраиваем обработчик для красной кнопки
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.target = self
            closeButton.action = #selector(closeWindow)
        }
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        // Скругления для всего окна
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 20
        window.contentView?.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        window.contentView?.layer?.masksToBounds = true

        let container = NSVisualEffectView(frame: window.contentView!.bounds)
        container.autoresizingMask = [.width, .height]
        container.material = .hudWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = 20
        container.layer?.masksToBounds = true
        window.contentView = container

        // Header with icon and title
        setupHeader(container: container, width: width, height: height)
        
        // Status card
        setupStatusCard(container: container, width: width, height: height)
        
        // Info cards
        setupInfoCards(container: container, width: width, height: height)
        
        // Toggle button
        setupToggleButton(container: container, width: width, height: height)
        
        // Добавить иконку диагностики в правый нижний угол
        let diagIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "Диагностика")
        diagnosticsButton = NSButton(image: diagIcon!, target: self, action: #selector(showDiagnostics))
        diagnosticsButton.frame = NSRect(x: window.contentView!.frame.width - 48, y: 20, width: 32, height: 32)
        diagnosticsButton.bezelStyle = .regularSquare
        diagnosticsButton.isBordered = false
        diagnosticsButton.wantsLayer = true
        diagnosticsButton.layer?.cornerRadius = 16
        diagnosticsButton.layer?.backgroundColor = NSColor.clear.cgColor
        diagnosticsButton.contentTintColor = NSColor.systemGray
        diagnosticsButton.alphaValue = 0.7
        diagnosticsButton.toolTip = NSLocalizedString("Показать диагностику", comment: "Diagnostics button tooltip")
        diagnosticsButton.autoresizingMask = [.minXMargin, .maxYMargin]
        window.contentView?.addSubview(diagnosticsButton)
        
        uiLogger.info("UI setup completed")

        // Применяем тему к окну
        ThemeManager.shared.applyTheme(to: window)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.orderFront(nil)
        window.level = .floating
        uiLogger.info("Window should be visible now")
    }
    
    private func setupHeader(container: NSView, width: CGFloat, height: CGFloat) {
        // Круглый аватар с градиентом и тенью
        let avatarSize: CGFloat = 76
        let avatarView = NSView(frame: NSRect(x: (width - avatarSize)/2, y: height - 100, width: avatarSize, height: avatarSize))
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
        avatarView.layer?.shadowOpacity = 0.18
        avatarView.layer?.shadowRadius = 8
        avatarView.layer?.shadowOffset = CGSize(width: 0, height: 2)
        container.addSubview(avatarView)
        
        let iconPath = Bundle.main.path(forResource: "AdGuardIcon", ofType: "icns")
        let icon = NSImage(contentsOfFile: iconPath ?? "") ?? NSImage(named: NSImage.networkName)!
        let iconView = NSImageView(image: icon)
        iconView.frame = NSRect(x: (avatarSize-48)/2, y: (avatarSize-48)/2, width: 48, height: 48)
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 24
        iconView.layer?.masksToBounds = true
        avatarView.addSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: Config.app.name)
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: height - 130, width: width - 40, height: 24)
        container.addSubview(titleLabel)
    }
    
    private func setupStatusCard(container: NSView, width: CGFloat, height: CGFloat) {
        statusCard = AnimatedStatusCard(frame: NSRect(x: 20, y: height - 200, width: width - 40, height: 60))
        container.addSubview(statusCard)
    }
    
    private func setupInfoCards(container: NSView, width: CGFloat, height: CGFloat) {
        let cardWidth: CGFloat = (width - 60) / 2
        let cardHeight: CGFloat = 50
        let startY = height - 280
        infoCards.removeAll()
        
        // DNS Servers
        let dnsCard = InfoCard(
            title: "DNS серверы",
            value: "Загрузка...",
            icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
            iconColor: .systemBlue
        )
        dnsCard.frame = NSRect(x: 20, y: startY, width: cardWidth, height: cardHeight)
        container.addSubview(dnsCard)
        infoCards.append(dnsCard)
        
        // Network Interface
        let networkCard = InfoCard(
            title: "Интерфейс",
            value: "Загрузка...",
            icon: NSImage(systemSymbolName: "wifi", accessibilityDescription: nil),
            iconColor: .systemPurple
        )
        networkCard.frame = NSRect(x: 20 + cardWidth + 20, y: startY, width: cardWidth, height: cardHeight)
        container.addSubview(networkCard)
        infoCards.append(networkCard)
        
        // Uptime
        let uptimeCard = InfoCard(
            title: "Время работы",
            value: "Загрузка...",
            icon: NSImage(systemSymbolName: "clock", accessibilityDescription: nil),
            iconColor: .systemOrange
        )
        uptimeCard.frame = NSRect(x: 20, y: startY - 70, width: cardWidth, height: cardHeight)
        container.addSubview(uptimeCard)
        infoCards.append(uptimeCard)
        
        // Memory Usage
        let memoryCard = InfoCard(
            title: "Память",
            value: "Загрузка...",
            icon: NSImage(systemSymbolName: "memorychip", accessibilityDescription: nil),
            iconColor: .systemBlue
        )
        memoryCard.frame = NSRect(x: 20 + cardWidth + 20, y: startY - 70, width: cardWidth, height: cardHeight)
        container.addSubview(memoryCard)
        infoCards.append(memoryCard)
        
        // Latency (с мини-графиком)
        let latencyCard = InfoCard(
            title: "Задержка",
            value: "Загрузка...",
            icon: NSImage(systemSymbolName: "speedometer", accessibilityDescription: nil),
            iconColor: .systemGreen,
            showSparkline: true
        )
        latencyCard.frame = NSRect(x: 20, y: startY - 140, width: cardWidth, height: cardHeight)
        container.addSubview(latencyCard)
        infoCards.append(latencyCard)
        
        // Version
        let versionCard = InfoCard(
            title: "Версия",
            value: SystemInfo.getAppVersion(),
            icon: NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil),
            iconColor: .systemGray
        )
        versionCard.frame = NSRect(x: 20 + cardWidth + 20, y: startY - 140, width: cardWidth, height: cardHeight)
        container.addSubview(versionCard)
        infoCards.append(versionCard)
    }
    
    private func setupToggleButton(container: NSView, width: CGFloat, height: CGFloat) {
        toggleButton = AnimatedToggleButton(frame: NSRect(x: (width-240)/2, y: 20, width: 240, height: 44))
        toggleButton.action = #selector(toggleDNS)
        toggleButton.target = self
        container.addSubview(toggleButton)
        toggleButton.toolTip = NSLocalizedString("Включить или выключить защиту AdGuard DNS.", comment: "Toggle button tooltip")
    }

    @objc func toggleDNS() {
        uiLogger.info("Toggle DNS called. Current status: \(self.isAdGuardEnabled ? "Enabled" : "Disabled")")
        toggleButton.setLoading(true)
        
        let command = self.isAdGuardEnabled ? Config.daemon.commands.disable : Config.daemon.commands.enable
        uiLogger.info("Sending command: \(command)")
        
        let success = sendCommand(command)
        if !success {
            uiLogger.error("Failed to send command: \(command)")
            let errorMessage = NSLocalizedString("Не удалось отправить команду daemon'у", comment: "Error message - failed to send command")
            showError(errorMessage)
            NotificationManager.shared.showError(errorMessage)
            toggleButton.setLoading(false)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.ui.timing.commandTimeout) {
            self.uiLogger.info("Checking status after timeout")
            self.checkStatus()
            self.toggleButton.setLoading(false)
        }
    }

    func checkStatus() {
        uiLogger.info("Checking status")
        let running = DaemonStatus.isDaemonRunning()
        updateUI(active: running)
    }

    func sendCommand(_ command: String) -> Bool {
        uiLogger.info("Sending command: \(command)")
        return DaemonStatus.sendCommand(command)
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemIcon()
        updateStatusItemMenu()
    }

    private func updateStatusItemIcon() {
        if let button = statusItem.button {
            let iconName = isAdGuardEnabled ? "shield.lefthalf.fill" : "shield.slash"
            let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: "AdGuard DNS Toggle")?.withSymbolConfiguration(.init(pointSize: 18, weight: .regular))
            icon?.isTemplate = true
            if let icon = icon {
                button.image = tintedImage(image: icon, color: isAdGuardEnabled ? .systemGreen : .systemGray)
            }
            button.toolTip = "AdGuard DNS Toggle — быстрый доступ"
            
            // Анимация иконки
            AnimatedStatusItem.animateIconChange(for: button, isActive: isAdGuardEnabled)
        }
    }

    private func tintedImage(image: NSImage, color: NSColor) -> NSImage {
        let newImage = image.copy() as! NSImage
        newImage.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: newImage.size)
        imageRect.fill(using: .sourceAtop)
        newImage.unlockFocus()
        return newImage
    }
    func updateStatusItemMenu() {
        let menu = NSMenu()
        let statusTitle = isAdGuardEnabled ? NSLocalizedString("AdGuard DNS: Включено", comment: "Menu status enabled") : NSLocalizedString("AdGuard DNS: Выключено", comment: "Menu status disabled")
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        menu.addItem(statusItem)
        menu.addItem(NSMenuItem.separator())
        let toggleTitle = isAdGuardEnabled ? NSLocalizedString("Выключить защиту", comment: "Menu disable") : NSLocalizedString("Включить защиту", comment: "Menu enable")
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleDNSFromMenu), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem(title: NSLocalizedString("Перезапустить демон", comment: "Menu restart daemon"), action: #selector(restartDaemonFromMenu), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Открыть главное окно", comment: "Menu open main window"), action: #selector(showMainWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Показать диагностику", comment: "Menu show diagnostics"), action: #selector(showDiagnosticsFromMenu), keyEquivalent: "d"))
        
        // Добавляем информацию о глобальных горячих клавишах
        menu.addItem(NSMenuItem.separator())
        let hotKeyInfo = NSMenuItem(title: "Глобальные горячие клавиши:", action: nil, keyEquivalent: "")
        hotKeyInfo.isEnabled = false
        menu.addItem(hotKeyInfo)
        
        let toggleHotKey = NSMenuItem(title: "Переключить защиту: \(HotKeyManager.getHotKeyDescription(for: "toggle"))", action: nil, keyEquivalent: "")
        toggleHotKey.isEnabled = false
        menu.addItem(toggleHotKey)
        
        let windowHotKey = NSMenuItem(title: "Показать окно: \(HotKeyManager.getHotKeyDescription(for: "showWindow"))", action: nil, keyEquivalent: "")
        windowHotKey.isEnabled = false
        menu.addItem(windowHotKey)
        
        let diagHotKey = NSMenuItem(title: "Диагностика: \(HotKeyManager.getHotKeyDescription(for: "diagnostics"))", action: nil, keyEquivalent: "")
        diagHotKey.isEnabled = false
        menu.addItem(diagHotKey)
        menu.addItem(NSMenuItem(title: NSLocalizedString("Показать приветствие", comment: "Menu show onboarding"), action: #selector(showOnboarding), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        // Добавляю пункт меню 'Настройки...'
        let prefsItem = NSMenuItem(title: NSLocalizedString("Настройки...", comment: "Menu preferences"), action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Выход", comment: "Menu quit"), action: #selector(quitApp), keyEquivalent: "q"))
        self.statusItem.menu = menu
    }

    @objc func toggleDNSFromMenu() {
        toggleDNS()
        updateStatusItemMenu()
    }
    @objc func restartDaemonFromMenu() {
        // Последовательно disable, затем enable
        let success = DaemonStatus.sendCommand(Config.daemon.commands.disable)
        if success {
            NotificationManager.shared.showDaemonStopped()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let enableSuccess = DaemonStatus.sendCommand(Config.daemon.commands.enable)
            if enableSuccess {
                NotificationManager.shared.showDaemonStarted()
            }
            self.checkStatus()
            self.updateStatusItemMenu()
        }
    }
    @objc func showMainWindow() {
        if !window.isVisible {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateUI(active: Bool) {
        uiLogger.info("Updating UI. Active: \(active)")
        let wasEnabled = isAdGuardEnabled
        isAdGuardEnabled = active
        let details = active ? "Защита активна" : "Защита неактивна"
        statusCard.updateStatus(isActive: active, details: details)
        toggleButton.updateState(isActive: active)
        updateStatusItemIcon()
        updateStatusItemMenu()
        
        // Показываем уведомления только при изменении статуса
        if wasEnabled != active {
            if active {
                NotificationManager.shared.showProtectionEnabled()
            } else {
                NotificationManager.shared.showProtectionDisabled()
            }
        }
    }

    private func updateInfoCards() {
        guard infoCards.count >= 6 else { return }
        // DNS Servers
        let dnsServers = SystemInfo.getCurrentDNS()
        let dnsText = dnsServers.joined(separator: ", ")
        if dnsText == "Не удалось определить" {
            let reason = SystemInfo.getLastLogError(forKey: "scutil") ?? SystemInfo.getLastLogError(forKey: "networksetup")
            infoCards[0].updateValue(dnsText + (reason != nil ? "\n(Причина: \(reason!))" : ""))
        } else {
            infoCards[0].updateValue(dnsText)
        }
        // Network Interface
        let networkInterface = SystemInfo.getActiveNetworkInterface()
        if networkInterface == "Неизвестно" {
            let reason = SystemInfo.getLastLogError(forKey: "route") ?? SystemInfo.getLastLogError(forKey: "networksetup")
            infoCards[1].updateValue(networkInterface + (reason != nil ? "\n(Причина: \(reason!))" : ""))
        } else {
            infoCards[1].updateValue(networkInterface)
        }
        // Uptime
        let uptime = SystemInfo.getDaemonUptime()
        if uptime == "Не запущен" || uptime == "Неизвестно" {
            let reason = SystemInfo.getLastLogError(forKey: "PID file") ?? SystemInfo.getLastLogError(forKey: "ps etime")
            infoCards[2].updateValue(uptime + (reason != nil ? "\n(Причина: \(reason!))" : ""))
        } else {
            infoCards[2].updateValue(uptime)
        }
        // Memory Usage
        let memory = SystemInfo.getDaemonMemoryUsage()
        if memory == "0 MB" {
            let reason = SystemInfo.getLastLogError(forKey: "PID file") ?? SystemInfo.getLastLogError(forKey: "ps rss")
            infoCards[3].updateValue(memory + (reason != nil ? "\n(Причина: \(reason!))" : ""))
        } else {
            infoCards[3].updateValue(memory)
        }
        // Latency
        let (isConnected, latency) = SystemInfo.checkAdGuardConnection()
        let latencyValue = Double(latency.replacingOccurrences(of: " ms", with: "")) ?? 0
        latencyHistory.append(latencyValue)
        if latencyHistory.count > 10 { latencyHistory.removeFirst() }
        let latencyText = isConnected ? latency : "Нет соединения"
        infoCards[4].updateValue(latencyText)
        infoCards[4].updateSparkline(latencyHistory)
        // Version is static
    }

    func showError(_ message: String) {
        uiLogger.error("Showing error: \(message)")
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Ошибка", comment: "Error title")
        alert.informativeText = NSLocalizedString(message, comment: "Error message")
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc func showDiagnostics() {
        diagnosticsWindow = DiagnosticsWindowController()
        diagnosticsWindow?.showWindow(nil)
        diagnosticsWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showDiagnosticsFromMenu() {
        showDiagnostics()
    }
    @objc func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController()
        }
        
        guard let prefsWin = preferencesWindow?.window else { return }
        
        // Устанавливаем окно настроек поверх всех остальных
        prefsWin.level = .floating
        prefsWin.makeKeyAndOrderFront(nil)
        prefsWin.orderFrontRegardless()
        
        // Активируем приложение
        NSApp.activate(ignoringOtherApps: true)
        
        print("[Preferences] Window shown with level: \(prefsWin.level.rawValue)")
    }
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func closeWindow() {
        window.orderOut(nil)
    }
    
    @objc func showOnboarding() {
        // Сбрасываем флаг, чтобы показать onboarding снова
        UserDefaults.standard.set(false, forKey: "onboarding_shown")
        UserDefaults.standard.synchronize()
        
        let hosting = NSHostingController(rootView: OnboardingView())
        onboardingWindow = NSWindow(contentViewController: hosting)
        onboardingWindow?.title = NSLocalizedString("Добро пожаловать!", comment: "Onboarding title")
        onboardingWindow?.styleMask = [.titled, .closable]
        onboardingWindow?.level = .modalPanel
        onboardingWindow?.center()
        onboardingWindow?.ignoresMouseEvents = false
        onboardingWindow?.acceptsMouseMovedEvents = true
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Скрываем главное окно
        window.orderOut(nil)
    }
    
    // MARK: - Notification Handling
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "ENABLE_PROTECTION":
            DispatchQueue.main.async {
                self.toggleDNS()
            }
        case "DISABLE_PROTECTION":
            DispatchQueue.main.async {
                self.toggleDNS()
            }
        case "OPEN_APP":
            DispatchQueue.main.async {
                self.showMainWindow()
            }
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показываем уведомления даже когда приложение активно
        completionHandler([.banner, .sound])
    }
    
    // MARK: - NSWindowDelegate
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Скрываем окно вместо закрытия приложения
        DispatchQueue.main.async {
            sender.orderOut(nil)
        }
        return false
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Убеждаемся, что окно остается активным
        if let window = notification.object as? NSWindow {
            window.level = .floating
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Восстанавливаем уровень окна при потере фокуса
        if let window = notification.object as? NSWindow {
            window.level = .floating
        }
    }
}

struct OnboardingView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.green, Color(NSColor.systemTeal)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(radius: 10, y: 3)
                Image(systemName: "shield.lefthalf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.white)
            }
            Text("AdGuard DNS Toggle")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 12)
            Text(NSLocalizedString("Добро пожаловать!", comment: "Onboarding welcome"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.bottom, 16)

            VStack(spacing: 16) {
                featureCard(icon: "shield.checkered", title: NSLocalizedString("Защита одним кликом", comment: "Onboarding feature 1"), desc: NSLocalizedString("Включайте и выключайте AdGuard DNS защиту мгновенно", comment: "Onboarding feature 1 desc"))
                featureCard(icon: "chart.line.uptrend.xyaxis", title: NSLocalizedString("Мониторинг в реальном времени", comment: "Onboarding feature 2"), desc: NSLocalizedString("Следите за статусом, задержкой и использованием ресурсов", comment: "Onboarding feature 2 desc"))
                featureCard(icon: "gear", title: NSLocalizedString("Гибкие настройки", comment: "Onboarding feature 3"), desc: NSLocalizedString("Настраивайте DNS серверы, уведомления и автозапуск", comment: "Onboarding feature 3 desc"))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            Button(action: {
                // Закрыть onboarding окно
                NSApp.keyWindow?.close()
                UserDefaults.standard.set(true, forKey: "onboarding_shown")
                UserDefaults.standard.synchronize()
                
                // Показать главное окно приложения
                DispatchQueue.main.async {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }) {
                Text(NSLocalizedString("Начать", comment: "Onboarding start button"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 80)
            .padding(.bottom, 24)
        }
        .frame(width: 440, height: 520)
    }

    @ViewBuilder
    func featureCard(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
        )
    }
}
