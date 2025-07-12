import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = AppLogger.app
    private let uiLogger = AppLogger.ui
    
    // MARK: - UI Components
    var window: NSWindow!
    var statusCard: StatusCard!
    var toggleButton: ModernToggleButton!
    var infoCards: [InfoCard] = []
    
    // MARK: - State
    var isAdGuardEnabled = false
    var timer: Timer?
    var infoUpdateTimer: Timer?
    var latencyHistory: [Double] = Array(repeating: 0, count: 10)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        logger.info("Application did finish launching")
        setupUI()
        checkStatus()
        startStatusMonitoring()
        startInfoMonitoring()
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
        window.title = Config.app.name
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear

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
        
        uiLogger.info("UI setup completed")

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
        statusCard = StatusCard(frame: NSRect(x: 20, y: height - 200, width: width - 40, height: 60))
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
        toggleButton = ModernToggleButton(frame: NSRect(x: (width-240)/2, y: 20, width: 240, height: 44))
        toggleButton.action = #selector(toggleDNS)
        toggleButton.target = self
        container.addSubview(toggleButton)
    }

    @objc func toggleDNS() {
        uiLogger.info("Toggle DNS called. Current status: \(self.isAdGuardEnabled ? "Enabled" : "Disabled")")
        toggleButton.setLoading(true)
        
        let command = self.isAdGuardEnabled ? Config.daemon.commands.disable : Config.daemon.commands.enable
        uiLogger.info("Sending command: \(command)")
        
        let success = sendCommand(command)
        if !success {
            uiLogger.error("Failed to send command: \(command)")
            showError("Не удалось отправить команду daemon'у")
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

    func updateUI(active: Bool) {
        uiLogger.info("Updating UI. Active: \(active)")
        isAdGuardEnabled = active
        let details = active ? "Защита активна" : "Защита неактивна"
        statusCard.updateStatus(isActive: active, details: details)
        toggleButton.updateState(isActive: active)
    }

    private func updateInfoCards() {
        guard infoCards.count >= 6 else { return }
        // DNS Servers
        let dnsServers = SystemInfo.getCurrentDNS()
        let dnsText = dnsServers.joined(separator: ", ")
        infoCards[0].updateValue(dnsText)
        // Network Interface
        let networkInterface = SystemInfo.getActiveNetworkInterface()
        infoCards[1].updateValue(networkInterface)
        // Uptime
        let uptime = SystemInfo.getDaemonUptime()
        infoCards[2].updateValue(uptime)
        // Memory Usage
        let memory = SystemInfo.getDaemonMemoryUsage()
        infoCards[3].updateValue(memory)
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
        alert.messageText = "Ошибка"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
