import Cocoa

class ThemeManager {
    static let shared = ThemeManager()
    
    private init() {}
    
    // Определяем текущую тему
    var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        } else {
            return false
        }
    }
    
    // Цвета для светлой темы
    struct LightTheme {
        static let backgroundColor = NSColor.controlBackgroundColor
        static let cardBackground = NSColor.controlBackgroundColor.withAlphaComponent(0.8)
        static let textColor = NSColor.labelColor
        static let secondaryTextColor = NSColor.secondaryLabelColor
        static let accentColor = NSColor.systemBlue
        static let successColor = NSColor.systemGreen
        static let errorColor = NSColor.systemRed
        static let warningColor = NSColor.systemOrange
    }
    
    // Цвета для темной темы
    struct DarkTheme {
        static let backgroundColor = NSColor.controlBackgroundColor
        static let cardBackground = NSColor.controlBackgroundColor.withAlphaComponent(0.8)
        static let textColor = NSColor.labelColor
        static let secondaryTextColor = NSColor.secondaryLabelColor
        static let accentColor = NSColor.systemBlue
        static let successColor = NSColor.systemGreen
        static let errorColor = NSColor.systemRed
        static let warningColor = NSColor.systemOrange
    }
    
    // Получить цвет в зависимости от текущей темы
    func color(for key: String) -> NSColor {
        switch key {
        case "backgroundColor":
            return isDarkMode ? DarkTheme.backgroundColor : LightTheme.backgroundColor
        case "cardBackground":
            return isDarkMode ? DarkTheme.cardBackground : LightTheme.cardBackground
        case "textColor":
            return isDarkMode ? DarkTheme.textColor : LightTheme.textColor
        case "secondaryTextColor":
            return isDarkMode ? DarkTheme.secondaryTextColor : LightTheme.secondaryTextColor
        case "accentColor":
            return isDarkMode ? DarkTheme.accentColor : LightTheme.accentColor
        case "successColor":
            return isDarkMode ? DarkTheme.successColor : LightTheme.successColor
        case "errorColor":
            return isDarkMode ? DarkTheme.errorColor : LightTheme.errorColor
        case "warningColor":
            return isDarkMode ? DarkTheme.warningColor : LightTheme.warningColor
        default:
            return NSColor.labelColor
        }
    }
    
    // Применить тему к окну
    func applyTheme(to window: NSWindow) {
        if #available(macOS 10.14, *) {
            window.appearance = isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }
        
        // Обновляем цвета элементов
        updateWindowColors(window)
    }
    
    private func updateWindowColors(_ window: NSWindow) {
        // Обновляем цвет фона окна
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = color(for: "backgroundColor").cgColor
        }
    }
    
    // Наблюдатель за изменением темы
    func startThemeObserver() {
        // Пока отключаем наблюдение за изменением темы
        // TODO: Добавить правильное наблюдение за изменением темы
    }
    
    private func handleThemeChange() {
        // Уведомляем о изменении темы
        NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
    }
}

// Расширение для NSColor с поддержкой темной темы
extension NSColor {
    static var themeAwareBackground: NSColor {
        return ThemeManager.shared.color(for: "backgroundColor")
    }
    
    static var themeAwareCardBackground: NSColor {
        return ThemeManager.shared.color(for: "cardBackground")
    }
    
    static var themeAwareText: NSColor {
        return ThemeManager.shared.color(for: "textColor")
    }
    
    static var themeAwareSecondaryText: NSColor {
        return ThemeManager.shared.color(for: "secondaryTextColor")
    }
} 