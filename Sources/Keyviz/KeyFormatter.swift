import AppKit

enum KeyFormatter {
    private static let keyNames: [UInt16: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
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
}
