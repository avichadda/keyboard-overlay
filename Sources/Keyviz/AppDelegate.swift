import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let preferences = OverlayPreferences()
    private lazy var overlayController = OverlayWindowController(preferences: preferences)
    private var statusItem: NSStatusItem?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        startMonitoring()
        requestAccessibilityIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "keyboard",
            accessibilityDescription: "Keyviz"
        )
        item.button?.toolTip = "Keyviz"
        item.menu = makeMenu()
        statusItem = item
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let enabled = NSMenuItem(
            title: "Show Keystrokes",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        enabled.target = self
        enabled.state = preferences.isEnabled ? .on : .off
        enabled.identifier = NSUserInterfaceItemIdentifier("enabled")
        menu.addItem(enabled)
        menu.addItem(.separator())

        menu.addItem(submenuItem(title: "Opacity", menu: opacityMenu()))
        menu.addItem(submenuItem(title: "Color", menu: colorMenu()))
        menu.addItem(submenuItem(title: "Position", menu: positionMenu()))
        menu.addItem(submenuItem(title: "Display Time", menu: durationMenu()))
        menu.addItem(.separator())

        let permissions = NSMenuItem(
            title: "Open Accessibility Settings…",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        permissions.target = self
        menu.addItem(permissions)

        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: "Quit Keyviz",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)
        return menu
    }

    private func submenuItem(title: String, menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private func opacityMenu() -> NSMenu {
        let menu = NSMenu(title: "Opacity")
        for percent in [40, 55, 70, 85, 100] {
            let item = NSMenuItem(
                title: "\(percent)%",
                action: #selector(setOpacity(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = percent
            item.state = abs(preferences.opacity - CGFloat(percent) / 100) < 0.01 ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func colorMenu() -> NSMenu {
        let menu = NSMenu(title: "Color")
        for (index, color) in OverlayColor.choices.enumerated() {
            let item = NSMenuItem(
                title: color.name,
                action: #selector(setColor(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.state = preferences.color == color ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func positionMenu() -> NSMenu {
        let menu = NSMenu(title: "Position")
        for (index, position) in OverlayPosition.allCases.enumerated() {
            let item = NSMenuItem(
                title: position.title,
                action: #selector(setPosition(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.state = preferences.position == position ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func durationMenu() -> NSMenu {
        let menu = NSMenu(title: "Display Time")
        for (index, duration) in [0.6, 1.0, 1.5, 2.5].enumerated() {
            let item = NSMenuItem(
                title: "\(duration.formatted()) seconds",
                action: #selector(setDuration(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.state = abs(preferences.displayDuration - duration) < 0.01 ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func startMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) {
            [weak self] event in
            Task { @MainActor in
                self?.handle(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak self] event in
            self?.handle(event)
            return event
        }
    }

    private func handle(_ event: NSEvent) {
        guard !event.isARepeat else { return }
        overlayController.show(labels: KeyFormatter.labels(for: event))
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        preferences.isEnabled.toggle()
        sender.state = preferences.isEnabled ? .on : .off
        if !preferences.isEnabled {
            overlayController.clear()
        }
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        preferences.opacity = CGFloat(sender.tag) / 100
        select(sender)
        overlayController.refreshAppearance()
    }

    @objc private func setColor(_ sender: NSMenuItem) {
        guard OverlayColor.choices.indices.contains(sender.tag) else { return }
        preferences.color = OverlayColor.choices[sender.tag]
        select(sender)
        overlayController.refreshAppearance()
    }

    @objc private func setPosition(_ sender: NSMenuItem) {
        guard OverlayPosition.allCases.indices.contains(sender.tag) else { return }
        preferences.position = OverlayPosition.allCases[sender.tag]
        select(sender)
        overlayController.refreshAppearance()
    }

    @objc private func setDuration(_ sender: NSMenuItem) {
        let durations = [0.6, 1.0, 1.5, 2.5]
        guard durations.indices.contains(sender.tag) else { return }
        preferences.displayDuration = durations[sender.tag]
        select(sender)
    }

    private func select(_ sender: NSMenuItem) {
        sender.menu?.items.forEach { $0.state = $0 === sender ? .on : .off }
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
