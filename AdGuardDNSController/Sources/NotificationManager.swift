import Cocoa
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let logger = AppLogger.app
    
    private init() {
        requestNotificationPermission()
        setupNotificationCategories()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                self.logger.error("Failed to request notification permission: \(error.localizedDescription)")
            } else {
                self.logger.info("Notification permission granted: \(granted)")
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Quick Actions для уведомлений о статусе защиты
        let enableAction = UNNotificationAction(
            identifier: "ENABLE_PROTECTION",
            title: NSLocalizedString("Включить защиту", comment: "Quick action - enable protection"),
            options: [.foreground]
        )
        
        let disableAction = UNNotificationAction(
            identifier: "DISABLE_PROTECTION",
            title: NSLocalizedString("Выключить защиту", comment: "Quick action - disable protection"),
            options: [.foreground]
        )
        
        let openAppAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: NSLocalizedString("Открыть приложение", comment: "Quick action - open app"),
            options: [.foreground]
        )
        
        let protectionCategory = UNNotificationCategory(
            identifier: "PROTECTION_STATUS",
            actions: [enableAction, disableAction, openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        let errorCategory = UNNotificationCategory(
            identifier: "ERROR",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        let daemonCategory = UNNotificationCategory(
            identifier: "DAEMON_STATUS",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        let connectionCategory = UNNotificationCategory(
            identifier: "CONNECTION_STATUS",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        let adBlockCategory = UNNotificationCategory(
            identifier: "AD_BLOCK",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            protectionCategory,
            errorCategory,
            daemonCategory,
            connectionCategory,
            adBlockCategory
        ])
    }
    
    private func shouldPlaySound() -> Bool {
        return PreferencesWindowController.areSoundNotificationsEnabled()
    }
    
    // Временная заглушка для метода, который будет добавлен в PreferencesWindowController
    private func areAdBlockNotificationsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "ad_block_notifications_enabled")
    }
    
    func showProtectionEnabled() {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Защита включена", comment: "Notification title - protection enabled")
        content.body = NSLocalizedString("AdGuard DNS защита теперь активна", comment: "Notification body - protection enabled")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "PROTECTION_STATUS"
        
        let request = UNNotificationRequest(identifier: "protection_enabled", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show protection enabled notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showProtectionDisabled() {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Защита выключена", comment: "Notification title - protection disabled")
        content.body = NSLocalizedString("AdGuard DNS защита отключена", comment: "Notification body - protection disabled")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "PROTECTION_STATUS"
        
        let request = UNNotificationRequest(identifier: "protection_disabled", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show protection disabled notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showError(_ error: String) {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Ошибка AdGuard DNS", comment: "Notification title - error")
        content.body = NSLocalizedString(error, comment: "Notification body - error")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "ERROR"
        
        let request = UNNotificationRequest(identifier: "error_\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show error notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showDaemonStarted() {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Демон запущен", comment: "Notification title - daemon started")
        content.body = NSLocalizedString("AdGuard DNS демон успешно запущен", comment: "Notification body - daemon started")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "DAEMON_STATUS"
        
        let request = UNNotificationRequest(identifier: "daemon_started", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show daemon started notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showDaemonStopped() {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Демон остановлен", comment: "Notification title - daemon stopped")
        content.body = NSLocalizedString("AdGuard DNS демон остановлен", comment: "Notification body - daemon stopped")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "DAEMON_STATUS"
        
        let request = UNNotificationRequest(identifier: "daemon_stopped", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show daemon stopped notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showConnectionRestored() {
        guard PreferencesWindowController.areNotificationsEnabled() && PreferencesWindowController.isConnectionMonitoringEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Соединение восстановлено", comment: "Notification title - connection restored")
        content.body = NSLocalizedString("Соединение с AdGuard DNS серверами восстановлено", comment: "Notification body - connection restored")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "CONNECTION_STATUS"
        
        let request = UNNotificationRequest(identifier: "connection_restored", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show connection restored notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showConnectionLost() {
        guard PreferencesWindowController.areNotificationsEnabled() && PreferencesWindowController.isConnectionMonitoringEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Соединение потеряно", comment: "Notification title - connection lost")
        content.body = NSLocalizedString("Потеряно соединение с AdGuard DNS серверами", comment: "Notification body - connection lost")
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "CONNECTION_STATUS"
        
        let request = UNNotificationRequest(identifier: "connection_lost", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show connection lost notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Ad Blocking Notifications
    
    func showAdBlocked(domain: String) {
        guard PreferencesWindowController.areNotificationsEnabled() && areAdBlockNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Реклама заблокирована", comment: "Notification title - ad blocked")
        content.body = String(format: NSLocalizedString("Заблокирован домен: %@", comment: "Notification body - blocked domain"), domain)
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "AD_BLOCK"
        
        let request = UNNotificationRequest(identifier: "ad_blocked_\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show ad blocked notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showDailyStats(blocked: Int, total: Int) {
        guard PreferencesWindowController.areNotificationsEnabled() && areAdBlockNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Статистика за день", comment: "Notification title - daily stats")
        content.body = String(format: NSLocalizedString("Заблокировано %d из %d запросов", comment: "Notification body - daily stats"), blocked, total)
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "AD_BLOCK"
        
        let request = UNNotificationRequest(identifier: "daily_stats", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show daily stats notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Enhanced Notifications with Custom Sounds
    
    func showProtectionEnabledWithCustomSound() {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Защита включена", comment: "Notification title - protection enabled")
        content.body = NSLocalizedString("AdGuard DNS защита теперь активна", comment: "Notification body - protection enabled")
        
        if shouldPlaySound() {
            // Используем системный звук успеха
            content.sound = UNNotificationSound.default
        }
        
        content.categoryIdentifier = "PROTECTION_STATUS"
        
        let request = UNNotificationRequest(identifier: "protection_enabled_enhanced", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show enhanced protection enabled notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Новые функции для уведомлений о блокировке рекламы
    func showAdBlocked(domain: String, count: Int = 1) {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Реклама заблокирована", comment: "Notification title - ad blocked")
        
        let bodyText: String
        if count == 1 {
            bodyText = String(format: NSLocalizedString("Заблокирован домен: %@", comment: "Notification body - single ad blocked"), domain)
        } else {
            bodyText = String(format: NSLocalizedString("Заблокировано %d рекламных запросов", comment: "Notification body - multiple ads blocked"), count)
        }
        
        content.body = bodyText
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "AD_BLOCK"
        
        let request = UNNotificationRequest(identifier: "ad_blocked_\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show ad blocked notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showDailyStats(blockedCount: Int, totalRequests: Int) {
        guard PreferencesWindowController.areNotificationsEnabled() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Статистика за день", comment: "Notification title - daily stats")
        content.body = String(format: NSLocalizedString("Заблокировано %d из %d запросов", comment: "Notification body - daily stats"), blockedCount, totalRequests)
        content.sound = shouldPlaySound() ? .default : nil
        content.categoryIdentifier = "STATS"
        
        let request = UNNotificationRequest(identifier: "daily_stats", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show daily stats notification: \(error.localizedDescription)")
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
} 