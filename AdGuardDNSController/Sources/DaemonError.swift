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
            return "Command pipe not found at: \(path)"
        case .daemonNotRunning:
            return "AdGuard DNS daemon is not running"
        case .commandFailed(let command):
            return "Failed to send command: \(command)"
        case .invalidPID:
            return "Invalid PID in daemon file"
        case .processNotFound(let pid):
            return "Process with PID \(pid) not found"
        case .fileAccessDenied(let path):
            return "Access denied to file: \(path)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .pipeNotFound:
            return "Try restarting the daemon or check if it's running"
        case .daemonNotRunning:
            return "Start the daemon using the launch agent"
        case .commandFailed:
            return "Check daemon logs for more information"
        case .invalidPID:
            return "Remove the PID file and restart the daemon"
        case .processNotFound:
            return "The daemon process may have crashed. Restart it."
        case .fileAccessDenied:
            return "Check file permissions and try again"
        case .configurationError:
            return "Verify configuration files and paths"
        }
    }
} 