import Foundation

class DaemonStatus {
    private static let logger = AppLogger.daemon
    
    static func isDaemonRunning() -> Bool {
        logger.info("Checking if daemon is running...")
        
        do {
            let pid = try getDaemonPID()
            let running = try checkProcessRunning(pid: pid)
            logger.info("Daemon status: \(running ? "running" : "not running") (PID: \(pid))")
            return running
        } catch {
            logger.error("Failed to check daemon status: \(error.localizedDescription)")
            return false
        }
    }
    
    static func sendCommand(_ command: String) -> Bool {
        logger.info("Sending command: \(command)")
        
        // Validate command
        guard Config.daemon.commands.isValid(command) else {
            logger.error("Invalid command: \(command)")
            return false
        }
        
        do {
            try sendCommandToPipe(command)
            logger.info("Command sent successfully: \(command)")
            return true
        } catch {
            logger.error("Failed to send command: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private static func getDaemonPID() throws -> Int {
        let pidFilePath = Config.daemon.paths.pidFile
        
        guard FileManager.default.fileExists(atPath: pidFilePath) else {
            throw DaemonError.daemonNotRunning
        }
        
        do {
            let pidStr = try String(contentsOfFile: pidFilePath).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let pid = Int(pidStr), pid > 0 else {
                throw DaemonError.invalidPID
            }
            return pid
        } catch {
            throw DaemonError.fileAccessDenied(path: pidFilePath)
        }
    }
    
    private static func checkProcessRunning(pid: Int) throws -> Bool {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-p", "\(pid)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            logger.debug("PS output for PID \(pid): \(output)")
            
            let running = output.contains("dnsproxy")
            if !running {
                throw DaemonError.processNotFound(pid: pid)
            }
            
            return running
        } catch {
            throw DaemonError.processNotFound(pid: pid)
        }
    }
    
    private static func sendCommandToPipe(_ command: String) throws {
        let pipePath = Config.daemon.paths.commandPipe
        
        guard FileManager.default.fileExists(atPath: pipePath) else {
            throw DaemonError.pipeNotFound(path: pipePath)
        }
        
        guard let handle = FileHandle(forWritingAtPath: pipePath) else {
            throw DaemonError.fileAccessDenied(path: pipePath)
        }
        
        defer {
            handle.closeFile()
        }
        
        let commandData = (command + "\n").data(using: .utf8)!
        handle.write(commandData)
    }
}
