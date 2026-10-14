import AppKit

@MainActor
final class KeySelectionWindowController: NSWindowController {
    private let preferences: OverlayPreferences
    private let onChange: () -> Void
    private let selectedLabel = NSTextField(labelWithString: "")
    private let captureView = KeyCaptureView()
    private var selectedKeys: [KeyDefinition]

    init(preferences: OverlayPreferences, onChange: @escaping () -> Void) {
        self.preferences = preferences
        self.onChange = onChange
        selectedKeys = preferences.selectedKeys

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Choose Overlay Keys"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        configureContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        selectedKeys = preferences.selectedKeys
        updateSelectedLabel()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeFirstResponder(captureView)
    }

    private func configureContent() {
        guard let contentView = window?.contentView else { return }

        let heading = NSTextField(labelWithString: "Choose up to 12 keys")
        heading.font = .systemFont(ofSize: 20, weight: .semibold)

        let detail = NSTextField(
            wrappingLabelWithString: "Click the capture area, then press a key to add it. Press it again to remove it."
        )
        detail.textColor = .secondaryLabelColor

        captureView.wantsLayer = true
        captureView.layer?.cornerRadius = 12
        captureView.layer?.borderWidth = 2
        captureView.layer?.borderColor = NSColor.controlAccentColor.cgColor
        captureView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        captureView.onKey = { [weak self] event in
            self?.toggle(event: event)
        }

        let captureText = NSTextField(labelWithString: "Press keys here")
        captureText.font = .systemFont(ofSize: 17, weight: .medium)
        captureText.textColor = .controlAccentColor
        captureText.translatesAutoresizingMaskIntoConstraints = false
        captureView.addSubview(captureText)

        selectedLabel.font = .monospacedSystemFont(ofSize: 17, weight: .medium)
        selectedLabel.alignment = .center
        selectedLabel.lineBreakMode = .byTruncatingTail

        let clearButton = NSButton(
            title: "Clear",
            target: self,
            action: #selector(clearSelection)
        )
        let doneButton = NSButton(
            title: "Done",
            target: self,
            action: #selector(saveAndClose)
        )
        doneButton.keyEquivalent = "\r"

        let buttonStack = NSStackView(views: [clearButton, doneButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 10

        let stack = NSStackView(views: [
            heading,
            detail,
            captureView,
            selectedLabel,
            buttonStack
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22),
            detail.widthAnchor.constraint(equalTo: stack.widthAnchor),
            captureView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            captureView.heightAnchor.constraint(equalToConstant: 86),
            selectedLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            captureText.centerXAnchor.constraint(equalTo: captureView.centerXAnchor),
            captureText.centerYAnchor.constraint(equalTo: captureView.centerYAnchor)
        ])
        updateSelectedLabel()
    }

    private func toggle(event: NSEvent) {
        guard let key = KeyFormatter.definition(for: event) else {
            NSSound.beep()
            return
        }

        if let index = selectedKeys.firstIndex(where: { $0.keyCode == key.keyCode }) {
            selectedKeys.remove(at: index)
        } else if selectedKeys.count < 12 {
            selectedKeys.append(key)
        } else {
            NSSound.beep()
        }
        updateSelectedLabel()
    }

    private func updateSelectedLabel() {
        selectedLabel.stringValue = selectedKeys.isEmpty
            ? "No keys selected"
            : selectedKeys.map(\.label).joined(separator: "   ")
    }

    @objc private func clearSelection() {
        selectedKeys.removeAll()
        updateSelectedLabel()
        window?.makeFirstResponder(captureView)
    }

    @objc private func saveAndClose() {
        preferences.selectedKeys = selectedKeys
        onChange()
        close()
    }
}

private final class KeyCaptureView: NSView {
    var onKey: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        onKey?(event)
    }

    override func flagsChanged(with event: NSEvent) {
        guard KeyFormatter.isModifierPressed(event: event) else { return }
        onKey?(event)
    }
}
