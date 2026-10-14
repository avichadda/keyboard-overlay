import AppKit

@MainActor
final class OverlayWindowController: NSWindowController {
    private struct Entry {
        let id: UUID
        let view: NSView
        let timer: Timer
    }

    private let preferences: OverlayPreferences
    private let stackView = NSStackView()
    private var entries: [Entry] = []

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

    func show(labels: [String]) {
        guard preferences.isEnabled, !labels.isEmpty else { return }

        for label in labels {
            addKey(label)
        }

        while entries.count > 7 {
            removeEntry(id: entries[0].id, animated: false)
        }

        updateWindow(animated: true)
    }

    func refreshAppearance() {
        for entry in entries {
            applyAppearance(to: entry.view)
        }
        updateWindow(animated: false)
    }

    func clear() {
        for entry in entries {
            entry.timer.invalidate()
            stackView.removeArrangedSubview(entry.view)
            entry.view.removeFromSuperview()
        }
        entries.removeAll()
        window?.orderOut(nil)
    }

    private func configureContent() {
        guard let panel = window as? NSPanel else { return }

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 10
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        panel.contentView = stackView
    }

    private func addKey(_ label: String) {
        let id = UUID()
        let keyView = makeKeyView(label: label)
        stackView.addArrangedSubview(keyView)

        let timer = Timer.scheduledTimer(
            withTimeInterval: preferences.displayDuration,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.removeEntry(id: id, animated: true)
            }
        }
        entries.append(Entry(id: id, view: keyView, timer: timer))
    }

    private func makeKeyView(label: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 15
        container.layer?.masksToBounds = true

        let text = NSTextField(labelWithString: label)
        text.font = .systemFont(ofSize: label.count > 3 ? 22 : 34, weight: .semibold)
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

        applyAppearance(to: container)
        return container
    }

    private func applyAppearance(to view: NSView) {
        view.layer?.backgroundColor = preferences.color.nsColor
            .withAlphaComponent(preferences.opacity)
            .cgColor
    }

    private func removeEntry(id: UUID, animated: Bool) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = entries.remove(at: index)
        entry.timer.invalidate()

        let completion = { [weak self] in
            self?.stackView.removeArrangedSubview(entry.view)
            entry.view.removeFromSuperview()
            self?.updateWindow(animated: true)
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                entry.view.animator().alphaValue = 0
            } completionHandler: {
                Task { @MainActor in completion() }
            }
        } else {
            completion()
        }
    }

    private func updateWindow(animated: Bool) {
        guard let window else { return }
        guard !entries.isEmpty else {
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
