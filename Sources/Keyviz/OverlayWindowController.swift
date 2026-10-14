import AppKit

@MainActor
final class OverlayWindowController: NSWindowController {
    private let preferences: OverlayPreferences
    private let stackView = NSStackView()
    private var keyViews: [UInt16: NSView] = [:]
    private var pressedKeyCodes = Set<UInt16>()

    init(preferences: OverlayPreferences) {
        self.preferences = preferences

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        super.init(window: panel)
        configureContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadKeys() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        keyViews.removeAll()
        pressedKeyCodes.removeAll()

        for key in preferences.selectedKeys {
            let keyView = makeKeyView(label: key.label)
            keyViews[key.keyCode] = keyView
            stackView.addArrangedSubview(keyView)
        }
        updateWindow(animated: true)
    }

    func setPressed(_ isPressed: Bool, keyCode: UInt16) {
        guard let view = keyViews[keyCode], preferences.isEnabled else { return }
        if isPressed {
            pressedKeyCodes.insert(keyCode)
        } else {
            pressedKeyCodes.remove(keyCode)
        }
        applyAppearance(to: view, pressed: isPressed, animated: true)
    }

    func refreshAppearance() {
        for (keyCode, view) in keyViews {
            applyAppearance(
                to: view,
                pressed: pressedKeyCodes.contains(keyCode),
                animated: false
            )
        }
        updateWindow(animated: false)
    }

    func setVisible(_ isVisible: Bool) {
        if isVisible {
            reloadKeys()
        } else {
            window?.orderOut(nil)
        }
    }

    private func configureContent() {
        guard let panel = window as? NSPanel else { return }
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 10
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        panel.contentView = stackView
    }

    private func makeKeyView(label: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 15
        container.layer?.masksToBounds = false

        let text = NSTextField(labelWithString: label)
        text.font = .systemFont(ofSize: label.count > 3 ? 20 : 32, weight: .semibold)
        text.textColor = .white
        text.alignment = .center
        text.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(text)

        let width = max(CGFloat(68), text.intrinsicContentSize.width + 30)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: width),
            container.heightAnchor.constraint(equalToConstant: 68),
            text.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            text.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            text.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 12),
            text.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12)
        ])

        applyAppearance(to: container, pressed: false, animated: false)
        return container
    }

    private func applyAppearance(to view: NSView, pressed: Bool, animated: Bool) {
        let color = pressed
            ? preferences.color.nsColor.blended(withFraction: 0.38, of: .white)
                ?? preferences.color.nsColor
            : preferences.color.nsColor
        let alpha: CGFloat = pressed ? 1 : preferences.opacity

        let changes = {
            view.layer?.backgroundColor = color.withAlphaComponent(alpha).cgColor
            view.layer?.borderColor = NSColor.white
                .withAlphaComponent(pressed ? 0.95 : 0.2)
                .cgColor
            view.layer?.borderWidth = pressed ? 3 : 1
            view.layer?.shadowColor = NSColor.black.cgColor
            view.layer?.shadowOpacity = pressed ? 0.45 : 0.18
            view.layer?.shadowRadius = pressed ? 10 : 4
            view.layer?.shadowOffset = NSSize(width: 0, height: -2)
            view.layer?.setAffineTransform(
                pressed
                    ? CGAffineTransform(scaleX: 1.08, y: 1.08)
                    : .identity
            )
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                context.allowsImplicitAnimation = true
                changes()
            }
        } else {
            changes()
        }
    }

    private func updateWindow(animated: Bool) {
        guard let window else { return }
        guard preferences.isEnabled, !keyViews.isEmpty else {
            window.orderOut(nil)
            return
        }

        stackView.layoutSubtreeIfNeeded()
        let fittingSize = stackView.fittingSize
        let targetSize = NSSize(
            width: max(fittingSize.width, 92),
            height: max(fittingSize.height, 92)
        )
        let screen = screenForOverlay()
        let origin = windowOrigin(size: targetSize, visibleFrame: screen.visibleFrame)
        let frame = NSRect(origin: origin, size: targetSize)

        if !window.isVisible {
            window.setFrame(frame, display: true)
            window.alphaValue = 0
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                window.animator().alphaValue = 1
            }
        } else {
            window.setFrame(frame, display: true, animate: animated)
        }
    }

    private func screenForOverlay() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func windowOrigin(size: NSSize, visibleFrame: NSRect) -> NSPoint {
        let margin: CGFloat = 28
        let horizontal: CGFloat
        let vertical: CGFloat

        switch preferences.position {
        case .topLeft, .bottomLeft:
            horizontal = visibleFrame.minX + margin
        case .topCenter, .bottomCenter:
            horizontal = visibleFrame.midX - size.width / 2
        case .topRight, .bottomRight:
            horizontal = visibleFrame.maxX - size.width - margin
        }

        switch preferences.position {
        case .topLeft, .topCenter, .topRight:
            vertical = visibleFrame.maxY - size.height - margin
        case .bottomLeft, .bottomCenter, .bottomRight:
            vertical = visibleFrame.minY + margin
        }

        return NSPoint(x: horizontal, y: vertical)
    }
}
