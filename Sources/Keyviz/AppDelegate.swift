import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let preferences = OverlayPreferences()
    private lazy var overlayController = OverlayWindowController(preferences: preferences)
    private lazy var keySelectionController = KeySelectionWindowController(
        preferences: preferences
    ) { [weak self] in
        self?.overlayController.reloadKeys()
        self?.refreshMenu()
    }
    private var statusItem: NSStatusItem?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        startLocalMonitoring()
        requestAccessibilityIfNeeded()
        refreshGlobalMonitoring()
        overlayController.reloadKeys()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshGlobalMonitoring()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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

        menu.addItem(submenuItem(title: "Displayed Keys", menu: displayedKeysMenu()))
        menu.addItem(submenuItem(title: "Opacity", menu: opacityMenu()))
        menu.addItem(submenuItem(title: "Color", menu: colorMenu()))
        menu.addItem(submenuItem(title: "Position", menu: positionMenu()))
        menu.addItem(.separator())

        let permissions = NSMenuItem(
            title: AXIsProcessTrusted()
                ? "Accessibility Access Granted"
                : "Grant Accessibility Access…",
            action: AXIsProcessTrusted() ? nil : #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        permissions.target = self
        permissions.state = AXIsProcessTrusted() ? .on : .off
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

    private func displayedKeysMenu() -> NSMenu {
        let menu = NSMenu(title: "Displayed Keys")
        let presets: [(String, [KeyDefinition])] = [
            ("WASD", KeyDefinition.wasd),
            ("Arrow Keys", KeyDefinition.arrows),
            ("WASD + Arrow Keys", KeyDefinition.wasdAndArrows)
        ]
        for (index, preset) in presets.enumerated() {
            let item = NSMenuItem(
                title: preset.0,
                action: #selector(selectKeyPreset(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.state = preferences.selectedKeys == preset.1 ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let customize = NSMenuItem(
            title: "Customize Keys…",
            action: #selector(customizeKeys),
            keyEquivalent: ""
        )
        customize.target = self
        menu.addItem(customize)
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

    private func startLocalMonitoring() {
        let eventMask: NSEvent.EventTypeMask = [.keyDown, .keyUp, .flagsChanged]
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) {
            [weak self] event in
            self?.handle(event)
            return event
        }
    }

    private func refreshGlobalMonitoring() {
        guard AXIsProcessTrusted() else {
            beginPermissionPolling()
            return
        }
        permissionTimer?.invalidate()
        permissionTimer = nil
        guard globalMonitor == nil else { return }

        let eventMask: NSEvent.EventTypeMask = [.keyDown, .keyUp, .flagsChanged]
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) {
            [weak self] event in
            Task { @MainActor in
                self?.handle(event)
            }
        }
        globalMonitor = monitor
        guard monitor != nil else {
            beginPermissionPolling()
            return
        }
        refreshMenu()
    }

    private func beginPermissionPolling() {
        guard permissionTimer == nil else { return }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.refreshGlobalMonitoring()
            }
        }
    }

    private func handle(_ event: NSEvent) {
        guard !event.isARepeat else { return }
        let isPressed = event.type == .flagsChanged
            ? KeyFormatter.isModifierPressed(event: event)
            : event.type == .keyDown
        overlayController.setPressed(isPressed, keyCode: event.keyCode)
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
        overlayController.setVisible(preferences.isEnabled)
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

    @objc private func selectKeyPreset(_ sender: NSMenuItem) {
        let presets = [
            KeyDefinition.wasd,
            KeyDefinition.arrows,
            KeyDefinition.wasdAndArrows
        ]
        guard presets.indices.contains(sender.tag) else { return }
        preferences.selectedKeys = presets[sender.tag]
        select(sender)
        overlayController.reloadKeys()
    }

    @objc private func customizeKeys() {
        keySelectionController.present()
    }

    private func select(_ sender: NSMenuItem) {
        sender.menu?.items.forEach { $0.state = $0 === sender ? .on : .off }
    }

    private func refreshMenu() {
        statusItem?.menu = makeMenu()
    }

    @objc private func openAccessibilitySettings() {
        requestAccessibilityIfNeeded()
        beginPermissionPolling()
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
