import AppKit

@main
struct KeyFormatterTests {
    static func main() {
        formatsCommandShiftShortcut()
        formatsNamedKeys()
        omitsControlCharactersWithoutAKeyName()
        validatesBuiltInKeyPresets()
        capsAndDeduplicatesPersistedKeys()
        print("KeyFormatter self-tests passed")
    }

    static func formatsCommandShiftShortcut() {
        let labels = KeyFormatter.labels(
            characters: "K",
            charactersIgnoringModifiers: "k",
            keyCode: 40,
            modifiers: [.command, .shift]
        )

        precondition(labels == ["⇧", "⌘", "K"])
    }

    static func formatsNamedKeys() {
        let labels = KeyFormatter.labels(
            characters: nil,
            charactersIgnoringModifiers: nil,
            keyCode: 123,
            modifiers: [.option]
        )

        precondition(labels == ["⌥", "←"])
    }

    static func omitsControlCharactersWithoutAKeyName() {
        let labels = KeyFormatter.labels(
            characters: "\u{1}",
            charactersIgnoringModifiers: "\u{1}",
            keyCode: 0,
            modifiers: []
        )

        precondition(labels.isEmpty)
    }

    static func validatesBuiltInKeyPresets() {
        precondition(KeyDefinition.wasd.map(\.label) == ["W", "A", "S", "D"])
        precondition(KeyDefinition.arrows.map(\.keyCode) == [123, 125, 126, 124])
        precondition(Set(KeyDefinition.wasdAndArrows).count == 8)
    }

    static func capsAndDeduplicatesPersistedKeys() {
        let suiteName = "KeyvizSelfTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferences = OverlayPreferences(defaults: defaults)
        let keys = (0..<14).map {
            KeyDefinition(keyCode: UInt16($0), label: "\($0)")
        }

        preferences.selectedKeys = keys + [keys[0]]

        precondition(preferences.selectedKeys.count == 12)
        precondition(Set(preferences.selectedKeys).count == 12)
        defaults.removePersistentDomain(forName: suiteName)
    }
}
