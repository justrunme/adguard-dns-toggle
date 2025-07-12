import Cocoa

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private let logger = AppLogger.app
    
    private init() {
        logger.info("Hot key manager initialized")
    }
    
    // Методы для управления горячими клавишами
    func enableHotKeys() {
        logger.info("Hot keys enabled")
    }
    
    func disableHotKeys() {
        logger.info("Hot keys disabled")
    }
    
    // Получить описание горячих клавиш для меню
    static func getHotKeyDescription(for action: String) -> String {
        switch action {
        case "toggle":
            return "⌘⇧T"
        case "showWindow":
            return "⌘⇧O"
        case "diagnostics":
            return "⌘⇧D"
        default:
            return ""
        }
    }
} 