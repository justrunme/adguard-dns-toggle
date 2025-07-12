import Foundation
import os.log

struct AppLogger {
    static let subsystem = "com.adguard.toggle"
    
    static let app = Logger(subsystem: subsystem, category: "app")
    static let daemon = Logger(subsystem: subsystem, category: "daemon")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let network = Logger(subsystem: subsystem, category: "network")
}

extension Logger {
    func debugWithContext(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        self.debug("\(fileName):\(line) \(function) - \(message)")
    }
    
    func infoWithContext(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        self.info("\(fileName):\(line) \(function) - \(message)")
    }
    
    func errorWithContext(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        self.error("\(fileName):\(line) \(function) - \(message)")
    }
} 