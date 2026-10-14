import AppKit

enum KeyFormatter {
    private static let keyNames: [UInt16: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        54: "⌘", 55: "⌘", 56: "⇧", 57: "⇪", 58: "⌥",
        59: "⌃", 60: "⇧", 61: "⌥", 62: "⌃", 63: "Fn",
        71: "Clear", 72: "Volume ↑", 73: "Volume ↓", 74: "Mute",
        76: "⌤", 115: "↖", 116: "⇞", 117: "⌦", 119: "↘",
        121: "⇟", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]

    static func labels(
        characters: String?,
        charactersIgnoringModifiers: String?,
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags
    ) -> [String] {
        var labels: [String] = []
        let relevant = modifiers.intersection(.deviceIndependentFlagsMask)

        if relevant.contains(.control) { labels.append("⌃") }
        if relevant.contains(.option) { labels.append("⌥") }
        if relevant.contains(.shift) { labels.append("⇧") }
        if relevant.contains(.command) { labels.append("⌘") }
        if relevant.contains(.capsLock) { labels.append("⇪") }

        if let namedKey = keyNames[keyCode] {
            labels.append(namedKey)
        } else {
            let value = charactersIgnoringModifiers ?? characters ?? ""
            let cleaned = value.trimmingCharacters(in: .controlCharacters)
            if !cleaned.isEmpty {
                labels.append(cleaned.uppercased())
            }
        }

        return labels
    }

    static func labels(for event: NSEvent) -> [String] {
        labels(
            characters: event.characters,
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            keyCode: event.keyCode,
            modifiers: event.modifierFlags
        )
    }

    static func definition(for event: NSEvent) -> KeyDefinition? {
        let label: String
        if let namedKey = keyNames[event.keyCode] {
            label = namedKey
        } else {
            let value = event.charactersIgnoringModifiers ?? event.characters ?? ""
            let cleaned = value.trimmingCharacters(in: .controlCharacters)
            guard !cleaned.isEmpty else { return nil }
            label = cleaned.uppercased()
        }
        return KeyDefinition(keyCode: event.keyCode, label: label)
    }

    static func isModifierPressed(event: NSEvent) -> Bool {
        switch event.keyCode {
        case 54, 55:
            event.modifierFlags.contains(.command)
        case 56, 60:
            event.modifierFlags.contains(.shift)
        case 57:
            event.modifierFlags.contains(.capsLock)
        case 58, 61:
            event.modifierFlags.contains(.option)
        case 59, 62:
            event.modifierFlags.contains(.control)
        case 63:
            event.modifierFlags.contains(.function)
        default:
            false
        }
    }
}
