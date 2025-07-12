import Foundation
import Network

class ConnectionMonitor {
    static let shared = ConnectionMonitor()
    private let logger = AppLogger.app
    private var lastConnectionState: Bool?
    private var monitoringTimer: Timer?
    
    private init() {}
    
    func startMonitoring() {
        logger.info("Starting connection monitoring")
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkConnection()
        }
        // Первая проверка сразу
        checkConnection()
    }
    
    func stopMonitoring() {
        logger.info("Stopping connection monitoring")
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func checkConnection() {
        let (isConnected, _) = SystemInfo.checkAdGuardConnection()
        
        // Показываем уведомления только при изменении состояния
        if let lastState = lastConnectionState, lastState != isConnected {
            if isConnected {
                logger.info("Connection restored")
                NotificationManager.shared.showConnectionRestored()
            } else {
                logger.warning("Connection lost")
                NotificationManager.shared.showConnectionLost()
            }
        }
        
        lastConnectionState = isConnected
    }
    
    func getCurrentConnectionState() -> Bool? {
        return lastConnectionState
    }
} 