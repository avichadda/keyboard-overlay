import AppKit

@main
struct KeyFormatterTests {
    static func main() {
        formatsCommandShiftShortcut()
        formatsNamedKeys()
        omitsControlCharactersWithoutAKeyName()
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
}
