import AppKit

struct KeyDefinition: Codable, Hashable {
    let keyCode: UInt16
    let label: String

    static let wasd = [
        KeyDefinition(keyCode: 13, label: "W"),
        KeyDefinition(keyCode: 0, label: "A"),
        KeyDefinition(keyCode: 1, label: "S"),
        KeyDefinition(keyCode: 2, label: "D")
    ]

    static let arrows = [
        KeyDefinition(keyCode: 123, label: "←"),
        KeyDefinition(keyCode: 125, label: "↓"),
        KeyDefinition(keyCode: 126, label: "↑"),
        KeyDefinition(keyCode: 124, label: "→")
    ]

    static let wasdAndArrows = wasd + arrows
}

enum OverlayPosition: String, CaseIterable {
    case topLeft
    case topCenter
    case topRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .topCenter: "Top Center"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomCenter: "Bottom Center"
        case .bottomRight: "Bottom Right"
        }
    }
}

struct OverlayColor: Equatable {
    let name: String
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }

    static let choices = [
        OverlayColor(name: "Graphite", red: 0.12, green: 0.13, blue: 0.15),
        OverlayColor(name: "Blue", red: 0.08, green: 0.32, blue: 0.72),
        OverlayColor(name: "Purple", red: 0.37, green: 0.18, blue: 0.68),
        OverlayColor(name: "Green", red: 0.08, green: 0.46, blue: 0.28),
        OverlayColor(name: "Red", red: 0.72, green: 0.12, blue: 0.15),
        OverlayColor(name: "Orange", red: 0.84, green: 0.32, blue: 0.07)
    ]
}

final class OverlayPreferences {
    private enum Key {
        static let isEnabled = "overlay.isEnabled"
        static let opacity = "overlay.opacity"
        static let colorName = "overlay.colorName"
        static let position = "overlay.position"
        static let selectedKeys = "overlay.selectedKeys"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.opacity: 0.85,
            Key.colorName: OverlayColor.choices[0].name,
            Key.position: OverlayPosition.bottomCenter.rawValue
        ])
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Key.isEnabled) }
        set { defaults.set(newValue, forKey: Key.isEnabled) }
    }

    var opacity: CGFloat {
        get { CGFloat(defaults.double(forKey: Key.opacity)) }
        set { defaults.set(min(max(newValue, 0.2), 1), forKey: Key.opacity) }
    }

    var color: OverlayColor {
        get {
            let name = defaults.string(forKey: Key.colorName)
            return OverlayColor.choices.first { $0.name == name } ?? OverlayColor.choices[0]
        }
        set { defaults.set(newValue.name, forKey: Key.colorName) }
    }

    var position: OverlayPosition {
        get {
            OverlayPosition(rawValue: defaults.string(forKey: Key.position) ?? "")
                ?? .bottomCenter
        }
        set { defaults.set(newValue.rawValue, forKey: Key.position) }
    }

    var selectedKeys: [KeyDefinition] {
        get {
            guard
                let data = defaults.data(forKey: Key.selectedKeys),
                let keys = try? JSONDecoder().decode([KeyDefinition].self, from: data)
            else {
                return KeyDefinition.wasd
            }
            return Array(keys.prefix(12))
        }
        set {
            let uniqueKeys = newValue.reduce(into: [KeyDefinition]()) { result, key in
                guard !result.contains(where: { $0.keyCode == key.keyCode }) else { return }
                result.append(key)
            }
            guard let data = try? JSONEncoder().encode(Array(uniqueKeys.prefix(12))) else {
                return
            }
            defaults.set(data, forKey: Key.selectedKeys)
        }
    }
}
