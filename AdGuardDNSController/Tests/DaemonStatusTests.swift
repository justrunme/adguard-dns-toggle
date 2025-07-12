import XCTest
@testable import AdGuardDNSController

final class DaemonStatusTests: XCTestCase {
    
    func testCommandValidation() {
        // Test valid commands
        XCTAssertTrue(Config.daemon.commands.isValid("enable"))
        XCTAssertTrue(Config.daemon.commands.isValid("disable"))
        
        // Test invalid commands
        XCTAssertFalse(Config.daemon.commands.isValid("invalid"))
        XCTAssertFalse(Config.daemon.commands.isValid(""))
        XCTAssertFalse(Config.daemon.commands.isValid("start"))
        XCTAssertFalse(Config.daemon.commands.isValid("stop"))
    }
    
    func testDaemonCommandsStructure() {
        let commands = Config.daemon.commands
        
        XCTAssertEqual(commands.enable, "enable")
        XCTAssertEqual(commands.disable, "disable")
        XCTAssertEqual(commands.allCommands.count, 2)
        XCTAssertTrue(commands.allCommands.contains("enable"))
        XCTAssertTrue(commands.allCommands.contains("disable"))
    }
    
    func testConfigPaths() {
        let paths = Config.daemon.paths
        
        XCTAssertFalse(paths.pidFile.isEmpty)
        XCTAssertFalse(paths.commandPipe.isEmpty)
        XCTAssertFalse(paths.logFile.isEmpty)
        XCTAssertFalse(paths.configFile.isEmpty)
        
        XCTAssertTrue(paths.pidFile.hasPrefix("/tmp/"))
        XCTAssertTrue(paths.commandPipe.hasPrefix("/tmp/"))
        XCTAssertTrue(paths.logFile.hasPrefix("/tmp/"))
    }
    
    func testDNSProxyConfig() {
        let dnsproxy = Config.daemon.dnsproxy
        
        XCTAssertFalse(dnsproxy.executablePath.isEmpty)
        XCTAssertGreaterThan(dnsproxy.port, 0)
        XCTAssertLessThan(dnsproxy.port, 65536)
        XCTAssertFalse(dnsproxy.listenAddress.isEmpty)
        XCTAssertGreaterThan(dnsproxy.timeout, 0)
    }
    
    func testUIConfig() {
        let ui = Config.ui
        
        XCTAssertGreaterThan(ui.window.width, 0)
        XCTAssertGreaterThan(ui.window.height, 0)
        XCTAssertGreaterThan(ui.window.cornerRadius, 0)
        
        XCTAssertEqual(ui.colors.enabledGradient.count, 2)
        XCTAssertEqual(ui.colors.disabledGradient.count, 2)
        
        XCTAssertGreaterThan(ui.timing.statusCheckInterval, 0)
        XCTAssertGreaterThan(ui.timing.commandTimeout, 0)
        XCTAssertGreaterThan(ui.timing.uiUpdateDelay, 0)
    }
    
    func testAppConfig() {
        let app = Config.app
        
        XCTAssertFalse(app.name.isEmpty)
        XCTAssertFalse(app.bundleIdentifier.isEmpty)
        XCTAssertFalse(app.version.isEmpty)
        XCTAssertFalse(app.buildNumber.isEmpty)
        XCTAssertFalse(app.minimumSystemVersion.isEmpty)
        
        XCTAssertTrue(app.bundleIdentifier.contains("."))
        XCTAssertTrue(app.version.contains("."))
    }
} 