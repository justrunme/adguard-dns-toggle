import Foundation
import Network

class SystemInfo {
    
    // MARK: - DNS Information
    static func getCurrentDNS() -> [String] {
        // 1. Попробовать через scutil
        let task = Process()
        task.launchPath = "/usr/bin/scutil"
        task.arguments = ["--dns"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let lines = output.components(separatedBy: .newlines)
            var dnsServers: [String] = []
            for line in lines {
                if line.contains("nameserver[") {
                    let components = line.components(separatedBy: ":")
                    if components.count > 1 {
                        let server = components[1].trimmingCharacters(in: .whitespaces)
                        if !server.isEmpty && !dnsServers.contains(server) {
                            dnsServers.append(server)
                        }
                    }
                }
            }
            if !dnsServers.isEmpty {
                return dnsServers
            }
        } catch {}
        // 2. Попробовать через networksetup для всех сервисов
        let serviceTask = Process()
        serviceTask.launchPath = "/usr/sbin/networksetup"
        serviceTask.arguments = ["-listallnetworkservices"]
        let servicePipe = Pipe()
        serviceTask.standardOutput = servicePipe
        do {
            try serviceTask.run()
            serviceTask.waitUntilExit()
            let data = servicePipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let services = output.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.contains("An asterisk") }
            for service in services {
                let dnsTask = Process()
                dnsTask.launchPath = "/usr/sbin/networksetup"
                dnsTask.arguments = ["-getdnsservers", service]
                let dnsPipe = Pipe()
                dnsTask.standardOutput = dnsPipe
                try? dnsTask.run()
                dnsTask.waitUntilExit()
                let dnsData = dnsPipe.fileHandleForReading.readDataToEndOfFile()
                let dnsOutput = String(data: dnsData, encoding: .utf8) ?? ""
                let lines = dnsOutput.components(separatedBy: .newlines)
                for line in lines {
                    if line != "There aren't any DNS Servers set on" && !line.contains("any DNS Servers") && !line.isEmpty && line != "127.0.0.1" {
                        return [line]
                    }
                }
            }
        } catch {}
        return ["Не удалось определить"]
    }
    
    // MARK: - Network Interface
    static func getActiveNetworkInterface() -> String {
        // 1. Получить имя интерфейса через route
        let task = Process()
        task.launchPath = "/usr/sbin/route"
        task.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        task.standardOutput = pipe
        var interface: String?
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("interface:") {
                    let components = line.components(separatedBy: ":")
                    if components.count > 1 {
                        interface = components[1].trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
            }
        } catch {}
        guard let iface = interface, !iface.isEmpty else { return "Неизвестно" }
        // 2. Получить friendly name через networksetup
        let hwTask = Process()
        hwTask.launchPath = "/usr/sbin/networksetup"
        hwTask.arguments = ["-listallhardwareports"]
        let hwPipe = Pipe()
        hwTask.standardOutput = hwPipe
        do {
            try hwTask.run()
            hwTask.waitUntilExit()
            let data = hwPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let blocks = output.components(separatedBy: "\n\n")
            for block in blocks {
                if block.contains("Device: \(iface)") {
                    for line in block.components(separatedBy: .newlines) {
                        if line.contains("Hardware Port:") {
                            let name = line.replacingOccurrences(of: "Hardware Port:", with: "").trimmingCharacters(in: .whitespaces)
                            return name + " (" + iface + ")"
                        }
                    }
                }
            }
        } catch {}
        return iface
    }
    
    // MARK: - Uptime
    static func getDaemonUptime() -> String {
        let pidFilePath = Config.daemon.paths.pidFile
        
        guard FileManager.default.fileExists(atPath: pidFilePath),
              let pidStr = try? String(contentsOfFile: pidFilePath).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int(pidStr) else {
            return "Не запущен"
        }
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-o", "etime=", "-p", "\(pid)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let uptime = output.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return uptime.isEmpty ? "Не запущен" : uptime
        } catch {
            return "Неизвестно"
        }
    }
    
    // MARK: - Memory Usage
    static func getDaemonMemoryUsage() -> String {
        let pidFilePath = Config.daemon.paths.pidFile
        
        guard FileManager.default.fileExists(atPath: pidFilePath),
              let pidStr = try? String(contentsOfFile: pidFilePath).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int(pidStr) else {
            return "0 MB"
        }
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-o", "rss=", "-p", "\(pid)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let rss = output.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let rssValue = Int(rss) {
                let mb = Double(rssValue) / 1024.0
                return String(format: "%.1f MB", mb)
            }
            
            return "0 MB"
        } catch {
            return "0 MB"
        }
    }
    
    // MARK: - Connection Status
    static func checkAdGuardConnection() -> (isConnected: Bool, latency: String) {
        let testHost = "dns.adguard.com"
        let testPort: UInt16 = 53
        
        let startTime = Date()
        
        let connection = NWConnection(host: NWEndpoint.Host(testHost), port: NWEndpoint.Port(integerLiteral: testPort), using: .udp)
        
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        var latency = "Неизвестно"
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                isConnected = true
                let timeInterval = Date().timeIntervalSince(startTime)
                latency = String(format: "%.0f ms", timeInterval * 1000)
                connection.cancel()
                semaphore.signal()
            case .failed, .cancelled:
                connection.cancel()
                semaphore.signal()
            default:
                break
            }
        }
        
        connection.start(queue: .global())
        
        // Timeout after 3 seconds
        let result = semaphore.wait(timeout: .now() + 3.0)
        if result == .timedOut {
            connection.cancel()
        }
        
        return (isConnected, latency)
    }
    
    // MARK: - System Version
    static func getSystemVersion() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/sw_vers"
        task.arguments = ["-productVersion"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Неизвестно"
        }
    }
    
    // MARK: - App Version
    static func getAppVersion() -> String {
        let version = Config.app.version
        let build = Config.app.buildNumber
        return "\(version) (\(build))"
    }
} 