import Foundation
import Cocoa

struct Config {
    static let app = AppConfig()
    static let daemon = DaemonConfig()
    static let ui = UIConfig()
}

struct AppConfig {
    let name = "AdGuard DNS Toggle"
    let bundleIdentifier = "com.adguard.toggle"
    let version = "1.0.0"
    let buildNumber = "1"
    let minimumSystemVersion = "11.0"
}

struct DaemonConfig {
    let paths = DaemonPaths()
    let dnsproxy = DNSProxyConfig()
    let commands = DaemonCommands()
    
    struct DaemonPaths {
        let pidFile = "/tmp/dnsproxy.pid"
        let commandPipe = "/tmp/adguard-cmd-pipe"
        let logFile = "/tmp/adguard-daemon.log"
        let configFile = "/Users/justrunme/adguard-dns-toggle/Scripts/dnsproxy-config.yml"
    }
    
    struct DNSProxyConfig {
        let executablePath = "/opt/homebrew/bin/dnsproxy"
        let port = 53535
        let listenAddress = "127.0.0.1"
        let timeout = 30.0
    }
    
    struct DaemonCommands {
        let enable = "enable"
        let disable = "disable"
        
        var allCommands: [String] {
            return [enable, disable]
        }
        
        func isValid(_ command: String) -> Bool {
            return allCommands.contains(command)
        }
    }
}

struct UIConfig {
    let window = WindowConfig()
    let colors = ColorConfig()
    let timing = TimingConfig()
    
    struct WindowConfig {
        let width: CGFloat = 420
        let height: CGFloat = 580
        let cornerRadius: CGFloat = 20
        let backgroundColor = NSColor.clear
    }
    
    struct ColorConfig {
        let enabledGradient = [NSColor.systemGreen.cgColor, NSColor.systemTeal.cgColor]
        let disabledGradient = [NSColor.systemRed.cgColor, NSColor.systemOrange.cgColor]
        let enabledStatus = NSColor.systemGreen
        let disabledStatus = NSColor.systemRed
    }
    
    struct TimingConfig {
        let statusCheckInterval: TimeInterval = 3.0
        let commandTimeout: TimeInterval = 2.0
        let uiUpdateDelay: TimeInterval = 0.1
    }
} 