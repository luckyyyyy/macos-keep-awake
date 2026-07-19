import AppKit
import IOKit.pwr_mgt

final class AwakeController {
    private var displayAssertion: IOPMAssertionID = 0
    private var systemAssertion: IOPMAssertionID = 0
    private(set) var isActive = false

    @discardableResult
    func start() -> Bool {
        guard !isActive else { return true }

        let reason = "用户正在运行“保持唤醒”应用" as CFString
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &displayAssertion
        )

        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &systemAssertion
        )

        if displayResult == kIOReturnSuccess && systemResult == kIOReturnSuccess {
            isActive = true
            return true
        }

        stop()
        return false
    }

    func stop() {
        if displayAssertion != 0 {
            IOPMAssertionRelease(displayAssertion)
            displayAssertion = 0
        }
        if systemAssertion != 0 {
            IOPMAssertionRelease(systemAssertion)
            systemAssertion = 0
        }
        isActive = false
    }

    deinit {
        stop()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let awakeController = AwakeController()
    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    private var statusDot: NSView!
    private var statusLabel: NSTextField!
    private var detailLabel: NSTextField!
    private var toggleButton: NSButton!
    private var statusMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupWindow()
        _ = awakeController.start()
        refreshUI()
        showWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        awakeController.stop()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "保持唤醒")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        statusMenuItem = NSMenuItem(title: "正在保持屏幕点亮", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "打开窗口", action: #selector(showWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "暂停 / 恢复", action: #selector(toggleAwake), keyEquivalent: "p"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出保持唤醒", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 330),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "保持唤醒"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()

        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = root

        let icon = NSImageView(image: NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: nil)!)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 46, weight: .medium)
        icon.contentTintColor = .systemOrange
        root.addSubview(icon)

        let title = NSTextField(labelWithString: "保持这台 Mac 醒着")
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 25, weight: .semibold)
        title.alignment = .center
        root.addSubview(title)

        let statusRow = NSStackView()
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        statusRow.orientation = .horizontal
        statusRow.alignment = .centerY
        statusRow.spacing = 8
        root.addSubview(statusRow)

        statusDot = NSView()
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 5
        statusRow.addArrangedSubview(statusDot)

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusRow.addArrangedSubview(statusLabel)

        detailLabel = NSTextField(wrappingLabelWithString: "应用运行期间，系统不会因为空闲而锁屏、熄屏或进入睡眠。\n没有修改任何系统设置；退出应用后立即恢复原有行为。")
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .center
        detailLabel.maximumNumberOfLines = 3
        root.addSubview(detailLabel)

        toggleButton = NSButton(title: "", target: self, action: #selector(toggleAwake))
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.bezelStyle = .rounded
        toggleButton.controlSize = .large
        root.addSubview(toggleButton)

        let quitButton = NSButton(title: "退出应用", target: self, action: #selector(quitApp))
        quitButton.translatesAutoresizingMaskIntoConstraints = false
        quitButton.bezelStyle = .rounded
        root.addSubview(quitButton)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: root.topAnchor, constant: 30),
            icon.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 58),
            icon.heightAnchor.constraint(equalToConstant: 58),

            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12),
            title.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 30),
            title.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -30),

            statusRow.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 13),
            statusRow.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),

            detailLabel.topAnchor.constraint(equalTo: statusRow.bottomAnchor, constant: 17),
            detailLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 44),
            detailLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -44),

            toggleButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 21),
            toggleButton.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 170),
            toggleButton.heightAnchor.constraint(equalToConstant: 34),

            quitButton.topAnchor.constraint(equalTo: toggleButton.bottomAnchor, constant: 10),
            quitButton.centerXAnchor.constraint(equalTo: root.centerXAnchor)
        ])
    }

    private func refreshUI(error: Bool = false) {
        if error {
            statusDot.layer?.backgroundColor = NSColor.systemRed.cgColor
            statusLabel.stringValue = "无法启用"
            statusLabel.textColor = .systemRed
            statusMenuItem.title = "无法启用保持唤醒"
            toggleButton.title = "重试"
            statusItem.button?.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "无法保持唤醒")
        } else if awakeController.isActive {
            statusDot.layer?.backgroundColor = NSColor.systemGreen.cgColor
            statusLabel.stringValue = "正在保持屏幕点亮"
            statusLabel.textColor = .labelColor
            statusMenuItem.title = "正在保持屏幕点亮"
            toggleButton.title = "暂停"
            statusItem.button?.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "正在保持唤醒")
        } else {
            statusDot.layer?.backgroundColor = NSColor.systemGray.cgColor
            statusLabel.stringValue = "已暂停"
            statusLabel.textColor = .secondaryLabelColor
            statusMenuItem.title = "保持唤醒已暂停"
            toggleButton.title = "恢复"
            statusItem.button?.image = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "保持唤醒已暂停")
        }
        statusItem.button?.image?.isTemplate = true
    }

    @objc private func toggleAwake() {
        if awakeController.isActive {
            awakeController.stop()
            refreshUI()
        } else {
            refreshUI(error: !awakeController.start())
        }
    }

    @objc private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
