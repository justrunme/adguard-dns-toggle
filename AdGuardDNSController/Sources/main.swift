import Cocoa
import Foundation

// File lock для single-instance
import Darwin

let lockFilePath = "/tmp/adguard-dns-toggle.lock"
let lockFile = open(lockFilePath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
if lockFile == -1 {
    print("[SingleInstance] Не удалось открыть lock-файл: \(lockFilePath)")
    exit(1)
}
if flock(lockFile, LOCK_EX | LOCK_NB) != 0 {
    print("[SingleInstance] Уже запущен экземпляр (file lock)")
    exit(0)
}

defer {
    // lockFile не закрываем до завершения процесса
}

let bundleID = Bundle.main.bundleIdentifier!
let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
if runningApps.count > 1 {
    print("[SingleInstance] Found \(runningApps.count) running instances, activating existing and exiting.")
    for app in runningApps {
        if app != NSRunningApplication.current {
            print("[SingleInstance] Activating existing instance: \(app.processIdentifier)")
            app.activate(options: .activateIgnoringOtherApps)
            break
        }
    }
    exit(0)
}

print("[SingleInstance] This is the only running instance (PID: \(ProcessInfo.processInfo.processIdentifier)), continuing startup.")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()