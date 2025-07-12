import Cocoa
import QuartzCore

class AnimatedToggleButton: ModernToggleButton {
    private var animationLayer: CALayer?
    
    override func updateState(isActive: Bool) {
        super.updateState(isActive: isActive)
        
        // Анимация переключения
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fromValue = isActive ? NSColor.systemGray.cgColor : NSColor.systemGreen.cgColor
        animation.toValue = isActive ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor
        
        layer?.add(animation, forKey: "backgroundColor")
        
        // Анимация масштабирования
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 0.15
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.05
        scaleAnimation.autoreverses = true
        
        layer?.add(scaleAnimation, forKey: "scale")
    }
}

class AnimatedStatusCard: StatusCard {
    private var currentStatus: Bool = false
    
    override func updateStatus(isActive: Bool, details: String) {
        let wasActive = currentStatus
        currentStatus = isActive
        super.updateStatus(isActive: isActive, details: details)
        
        // Анимация только при изменении статуса
        if wasActive != isActive {
            let pulseAnimation = CABasicAnimation(keyPath: "opacity")
            pulseAnimation.duration = 0.3
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulseAnimation.fromValue = 0.7
            pulseAnimation.toValue = 1.0
            pulseAnimation.autoreverses = true
            
            layer?.add(pulseAnimation, forKey: "pulse")
        }
    }
}

class AnimatedInfoCard: InfoCard {
    override func updateValue(_ value: String) {
        super.updateValue(value)
        
        // Scale-анимация при обновлении значения
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = 0.18
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.05
        scaleAnimation.autoreverses = true
        
        layer?.add(scaleAnimation, forKey: "scale")
    }
}

// Анимированная иконка в меню-баре
class AnimatedStatusItem {
    static func animateIconChange(for button: NSStatusBarButton, isActive: Bool) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.duration = 0.3
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = isActive ? 0.1 : -0.1
        rotationAnimation.autoreverses = true
        
        button.layer?.add(rotationAnimation, forKey: "rotation")
    }
}

// Анимированные уведомления
class AnimatedNotification {
    static func showWithAnimation(title: String, message: String, style: NSAlert.Style = .informational) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        
        // Анимация появления окна
        let window = alert.window
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1.0
        })
        
        alert.runModal()
    }
} 