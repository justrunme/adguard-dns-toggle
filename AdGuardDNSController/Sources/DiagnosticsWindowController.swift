import Cocoa

class DiagnosticsWindowController: NSWindowController {
    private var textView: NSTextView!
    private var copyButton: NSButton!
    private var infoLabel: NSTextField!
    private var diagnosticsButton: NSButton!

    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = NSLocalizedString("Диагностика", comment: "Diagnostics window title")
        self.init(window: window)
        setupUI()
        loadLog()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        if let window = self.window {
            window.alphaValue = 0.0
            window.setFrameOrigin(NSPoint(x: window.frame.origin.x, y: window.frame.origin.y - 20))
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.22
                window.animator().alphaValue = 1.0
                window.animator().setFrameOrigin(NSPoint(x: window.frame.origin.x, y: window.frame.origin.y + 20))
            })
        }
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Info label
        infoLabel = NSTextField(labelWithString: NSLocalizedString("Если видите ошибку 'file doesn’t exist' — проверьте пути к утилитам. Если PID file exists: false — проверьте, запущен ли демон.", comment: "Diagnostics info label"))
        infoLabel.frame = NSRect(x: 20, y: 360, width: 560, height: 32)
        infoLabel.font = NSFont.systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.maximumNumberOfLines = 2
        contentView.addSubview(infoLabel)

        // Text view (scrollable)
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: 290))
        scrollView.hasVerticalScroller = true
        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        // Copy button
        copyButton = NSButton(title: NSLocalizedString("Скопировать лог", comment: "Copy log button"), target: self, action: #selector(copyLog))
        copyButton.frame = NSRect(x: 20, y: 20, width: 140, height: 28)
        contentView.addSubview(copyButton)
        copyButton.toolTip = NSLocalizedString("Скопировать содержимое лога в буфер обмена.", comment: "Copy log tooltip")
        // Кнопка диагностики
        diagnosticsButton = NSButton(title: NSLocalizedString("Проверить систему", comment: "Run diagnostics button"), target: self, action: #selector(runDiagnostics))
        diagnosticsButton.frame = NSRect(x: 180, y: 20, width: 140, height: 28)
        contentView.addSubview(diagnosticsButton)
        diagnosticsButton.toolTip = NSLocalizedString("Проверить состояние системы и зависимостей.", comment: "Run diagnostics tooltip")
    }

    private func loadLog() {
        let logPath = "/tmp/adguard-dns-toggle-app.log"
        if let log = try? String(contentsOfFile: logPath) {
            textView.string = log
        } else {
            textView.string = NSLocalizedString("Лог-файл не найден.", comment: "Log file not found")
        }
    }

    @objc private func copyLog() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textView.string, forType: .string)
    }

    @objc private func runDiagnostics() {
        let report = SystemInfo.runDiagnostics()
        textView.string = report + "\n\n" + textView.string
    }
} 