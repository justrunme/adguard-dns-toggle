import Foundation
import Network

class SystemInfo {
    
    // MARK: - DNS Information
    static func getCurrentDNS() -> [String] {
        let task = Process()
        task.launchPath = "/usr/sbin/scutil"
        task.arguments = ["--dns"]
        task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("scutil output: \(output)")
            if !errorOutput.isEmpty { logToFile("scutil error: \(errorOutput)") }
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
        } catch {
            logToFile("Failed to run scutil: \(error.localizedDescription)")
        }
        // 2. networksetup
        let serviceTask = Process()
        serviceTask.launchPath = "/usr/sbin/networksetup"
        serviceTask.arguments = ["-listallnetworkservices"]
        serviceTask.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let servicePipe = Pipe()
        let serviceErrorPipe = Pipe()
        serviceTask.standardOutput = servicePipe
        serviceTask.standardError = serviceErrorPipe
        do {
            try serviceTask.run()
            serviceTask.waitUntilExit()
            let data = servicePipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = serviceErrorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("networksetup -listallnetworkservices output: \(output)")
            if !errorOutput.isEmpty { logToFile("networksetup -listallnetworkservices error: \(errorOutput)") }
            let services = output.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.contains("An asterisk") }
            for service in services {
                let dnsTask = Process()
                dnsTask.launchPath = "/usr/sbin/networksetup"
                dnsTask.arguments = ["-getdnsservers", service]
                dnsTask.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
                let dnsPipe = Pipe()
                let dnsErrorPipe = Pipe()
                dnsTask.standardOutput = dnsPipe
                dnsTask.standardError = dnsErrorPipe
                try? dnsTask.run()
                dnsTask.waitUntilExit()
                let dnsData = dnsPipe.fileHandleForReading.readDataToEndOfFile()
                let dnsErrorData = dnsErrorPipe.fileHandleForReading.readDataToEndOfFile()
                let dnsOutput = String(data: dnsData, encoding: .utf8) ?? ""
                let dnsErrorOutput = String(data: dnsErrorData, encoding: .utf8) ?? ""
                logToFile("networksetup -getdnsservers \(service) output: \(dnsOutput)")
                if !dnsErrorOutput.isEmpty { logToFile("networksetup -getdnsservers \(service) error: \(dnsErrorOutput)") }
                let lines = dnsOutput.components(separatedBy: .newlines)
                for line in lines {
                    if line != "There aren't any DNS Servers set on" && !line.contains("any DNS Servers") && !line.isEmpty && line != "127.0.0.1" {
                        return [line]
                    }
                }
            }
        } catch {
            logToFile("Failed to run networksetup: \(error.localizedDescription)")
        }
        logToFile(NSLocalizedString("Не удалось определить DNS", comment: "Could not determine DNS"));
        return ["Не удалось определить"]
    }
    
    // MARK: - Network Interface
    static func getActiveNetworkInterface() -> String {
        let task = Process()
        task.launchPath = "/sbin/route"
        task.arguments = ["-n", "get", "default"]
        task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        var interface: String?
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("route output: \(output)")
            if !errorOutput.isEmpty { logToFile("route error: \(errorOutput)") }
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
        } catch {
            logToFile("Failed to run route: \(error.localizedDescription)")
        }
        guard let iface = interface, !iface.isEmpty else { logToFile(NSLocalizedString("Не удалось определить", comment: "Could not determine")); return NSLocalizedString("Неизвестно", comment: "Unknown") }
        let hwTask = Process()
        hwTask.launchPath = "/usr/sbin/networksetup"
        hwTask.arguments = ["-listallhardwareports"]
        hwTask.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let hwPipe = Pipe()
        let hwErrorPipe = Pipe()
        hwTask.standardOutput = hwPipe
        hwTask.standardError = hwErrorPipe
        do {
            try hwTask.run()
            hwTask.waitUntilExit()
            let data = hwPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = hwErrorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("networksetup -listallhardwareports output: \(output)")
            if !errorOutput.isEmpty { logToFile("networksetup -listallhardwareports error: \(errorOutput)") }
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
        } catch {
            logToFile("Failed to run networksetup -listallhardwareports: \(error.localizedDescription)")
        }
        logToFile(NSLocalizedString("Не удалось определить friendly name для интерфейса", comment: "Could not determine friendly name for interface"));
        return iface
    }
    
    // MARK: - Uptime
    static func getDaemonUptime() -> String {
        let pidFilePath = Config.daemon.paths.pidFile
        let exists = FileManager.default.fileExists(atPath: pidFilePath)
        logToFile("PID file exists: \(exists)")
        guard exists,
              let pidStr = try? String(contentsOfFile: pidFilePath).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int(pidStr) else {
            logToFile(NSLocalizedString("Не удалось прочитать PID-файл или PID некорректен", comment: "Could not read PID file or PID is incorrect"));
            return NSLocalizedString("Не запущен", comment: "Not running")
        }
        logToFile("PID file content: \(pidStr)")
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-o", "etime=", "-p", "\(pid)"]
        task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("ps etime output: \(output)")
            if !errorOutput.isEmpty { logToFile("ps etime error: \(errorOutput)") }
            let uptime = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return uptime.isEmpty ? NSLocalizedString("Не запущен", comment: "Not running") : uptime
        } catch {
            logToFile("Failed to run ps etime: \(error.localizedDescription)")
            return NSLocalizedString("Неизвестно", comment: "Unknown")
        }
    }
    
    // MARK: - Memory Usage
    static func getDaemonMemoryUsage() -> String {
        let pidFilePath = Config.daemon.paths.pidFile
        let exists = FileManager.default.fileExists(atPath: pidFilePath)
        logToFile("PID file exists: \(exists)")
        guard exists,
              let pidStr = try? String(contentsOfFile: pidFilePath).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int(pidStr) else {
            logToFile(NSLocalizedString("Не удалось прочитать PID-файл или PID некорректен", comment: "Could not read PID file or PID is incorrect"));
            return NSLocalizedString("0 MB", comment: "0 MB")
        }
        logToFile("PID file content: \(pidStr)")
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-o", "rss=", "-p", "\(pid)"]
        task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("ps rss output: \(output)")
            if !errorOutput.isEmpty { logToFile("ps rss error: \(errorOutput)") }
            let rss = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if let rssValue = Int(rss) {
                let mb = Double(rssValue) / 1024.0
                return String(format: NSLocalizedString("%.1f MB", comment: "%.1f MB"), mb)
            }
            return NSLocalizedString("0 MB", comment: "0 MB")
        } catch {
            logToFile("Failed to run ps rss: \(error.localizedDescription)")
            return NSLocalizedString("0 MB", comment: "0 MB")
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
        var latency = NSLocalizedString("Неизвестно", comment: "Unknown")
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                isConnected = true
                let timeInterval = Date().timeIntervalSince(startTime)
                latency = String(format: NSLocalizedString("%.0f ms", comment: "%.0f ms"), timeInterval * 1000)
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
        task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            logToFile("sw_vers output: \(output)")
            if !errorOutput.isEmpty { logToFile("sw_vers error: \(errorOutput)") }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            logToFile("Failed to run sw_vers: \(error.localizedDescription)")
            return NSLocalizedString("Неизвестно", comment: "Unknown")
        }
    }
    
    // MARK: - App Version
    static func getAppVersion() -> String {
        let version = Config.app.version
        let build = Config.app.buildNumber
        return String(format: NSLocalizedString("%@ (%@)", comment: "%@ (%@)"), version, build)
    }
    
    static func getLastLogError(forKey key: String) -> String? {
        let logPath = "/tmp/adguard-dns-toggle-app.log"
        guard let log = try? String(contentsOfFile: logPath) else { return nil }
        let lines = log.components(separatedBy: .newlines).reversed()
        for line in lines {
            if line.contains(key) {
                // Вернуть только текст после даты
                if let idx = line.firstIndex(of: "]") {
                    return String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
                } else {
                    return line
                }
            }
        }
        return nil
    }

    static func runDiagnostics() -> String {
        var report = String(format: NSLocalizedString("[Диагностика]", comment: "[Diagnostics]"))
        let fm = FileManager.default
        // Проверка PID-файла
        let pidPath = Config.daemon.paths.pidFile
        if fm.fileExists(atPath: pidPath) {
            if let attrs = try? fm.attributesOfItem(atPath: pidPath), let perms = attrs[.posixPermissions] as? NSNumber {
                report += String(format: NSLocalizedString("✓ %@ найден, права: %@", comment: "PID found"), pidPath, String(format: "%o", perms.intValue))
            } else {
                report += String(format: NSLocalizedString("✓ %@ найден, права: неизвестно", comment: "PID found unknown perms"), pidPath)
            }
        } else {
            report += String(format: NSLocalizedString("✗ %@ не найден", comment: "PID not found"), pidPath)
        }
        // Проверка пайпа
        let pipePath = Config.daemon.paths.commandPipe
        if fm.fileExists(atPath: pipePath) {
            if let attrs = try? fm.attributesOfItem(atPath: pipePath), let perms = attrs[.posixPermissions] as? NSNumber {
                report += String(format: NSLocalizedString("✓ %@ найден, права: %@", comment: "Pipe found"), pipePath, String(format: "%o", perms.intValue))
            } else {
                report += String(format: NSLocalizedString("✓ %@ найден, права: неизвестно", comment: "Pipe found unknown perms"), pipePath)
            }
        } else {
            report += String(format: NSLocalizedString("✗ %@ не найден", comment: "Pipe not found"), pipePath)
        }
        // Проверка процесса демона
        if let pidStr = try? String(contentsOfFile: pidPath).trimmingCharacters(in: .whitespacesAndNewlines), let pid = Int(pidStr), pid > 0 {
            let task = Process()
            task.launchPath = "/bin/ps"
            task.arguments = ["-p", "\(pid)"]
            task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
            let pipe = Pipe()
            task.standardOutput = pipe
            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                if output.contains("dnsproxy") {
                    report += String(format: NSLocalizedString("✓ Процесс dnsproxy (PID: %@) запущен", comment: "DNS proxy process (PID: %@) is running"), pidStr)
                } else {
                    report += String(format: NSLocalizedString("✗ Процесс dnsproxy (PID: %@) не найден", comment: "DNS proxy process (PID: %@) not found"), pidStr)
                }
            } catch {
                report += String(format: NSLocalizedString("✗ Не удалось проверить процесс dnsproxy (PID: %@)", comment: "Could not check DNS proxy process (PID: %@)"), pidStr)
            }
        } else {
            report += String(format: NSLocalizedString("✗ Не удалось получить PID демона", comment: "Could not get daemon PID"))
        }
        // Проверка бинарей
        let binaries = ["/usr/sbin/scutil", "/sbin/route", "/usr/sbin/networksetup", "/bin/ps", "/usr/bin/sw_vers"]
        for bin in binaries {
            if fm.isExecutableFile(atPath: bin) {
                report += String(format: NSLocalizedString("✓ %@ найден", comment: "Binary found"), bin)
            } else {
                report += String(format: NSLocalizedString("✗ %@ не найден", comment: "Binary not found"), bin)
            }
        }
        // Проверка прав на /tmp
        let tmpTest = "/tmp/adguard-dns-toggle-testfile"
        do {
            try "test".write(toFile: tmpTest, atomically: true, encoding: .utf8)
            report += String(format: NSLocalizedString("✓ Права на запись в /tmp есть", comment: "Write permission to /tmp exists"))
            try? fm.removeItem(atPath: tmpTest)
        } catch {
            report += String(format: NSLocalizedString("✗ Нет прав на запись в /tmp", comment: "No write permission to /tmp"))
        }
        // Проверка DNS для Wi-Fi
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-getdnsservers", "Wi-Fi"]
        task.environment = ["PATH": "/usr/bin:/usr/sbin:/bin:/sbin:/opt/homebrew/bin"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            if output.contains("127.0.0.1") {
                report += String(format: NSLocalizedString("✓ DNS 127.0.0.1 прописан для интерфейса Wi-Fi", comment: "DNS 127.0.0.1 for Wi-Fi"), output.trimmingCharacters(in: .whitespacesAndNewlines))
            } else if output.contains("any DNS Servers") || output.contains("There aren't any DNS Servers set on") {
                report += String(format: NSLocalizedString("✗ DNS не задан для Wi-Fi", comment: "DNS not set for Wi-Fi"))
            } else {
                report += String(format: NSLocalizedString("✓ DNS для Wi-Fi: %@", comment: "DNS for Wi-Fi"), output.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {
            report += String(format: NSLocalizedString("✗ Не удалось проверить DNS для Wi-Fi", comment: "Could not check DNS for Wi-Fi"))
        }
        logToFile(report)
        return report
    }
} 