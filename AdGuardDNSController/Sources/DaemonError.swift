import Foundation

enum DaemonError: Error, LocalizedError {
    case pipeNotFound(path: String)
    case daemonNotRunning
    case commandFailed(command: String)
    case invalidPID
    case processNotFound(pid: Int)
    case fileAccessDenied(path: String)
    case configurationError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .pipeNotFound(let path):
            return String(format: NSLocalizedString("Command pipe not found at: %@", comment: "Pipe not found error"), path)
        case .daemonNotRunning:
            return NSLocalizedString("AdGuard DNS daemon is not running", comment: "Daemon not running error")
        case .commandFailed(let command):
            return String(format: NSLocalizedString("Failed to send command: %@", comment: "Command failed error"), command)
        case .invalidPID:
            return NSLocalizedString("Invalid PID in daemon file", comment: "Invalid PID error")
        case .processNotFound(let pid):
            return String(format: NSLocalizedString("Process with PID %d not found", comment: "Process not found error"), pid)
        case .fileAccessDenied(let path):
            return String(format: NSLocalizedString("Access denied to file: %@", comment: "Access denied error"), path)
        case .configurationError(let message):
            return String(format: NSLocalizedString("Configuration error: %@", comment: "Configuration error"), message)
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .pipeNotFound:
            return NSLocalizedString("Try restarting the daemon or check if it's running", comment: "Pipe not found suggestion")
        case .daemonNotRunning:
            return NSLocalizedString("Start the daemon using the launch agent", comment: "Daemon not running suggestion")
        case .commandFailed:
            return NSLocalizedString("Check daemon logs for more information", comment: "Command failed suggestion")
        case .invalidPID:
            return NSLocalizedString("Remove the PID file and restart the daemon", comment: "Invalid PID suggestion")
        case .processNotFound:
            return NSLocalizedString("The daemon process may have crashed. Restart it.", comment: "Process not found suggestion")
        case .fileAccessDenied:
            return NSLocalizedString("Check file permissions and try again", comment: "Access denied suggestion")
        case .configurationError:
            return NSLocalizedString("Verify configuration files and paths", comment: "Configuration error suggestion")
        }
    }
} 