import AppKit

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
        static let displayDuration = "overlay.displayDuration"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.opacity: 0.85,
            Key.colorName: OverlayColor.choices[0].name,
            Key.position: OverlayPosition.bottomCenter.rawValue,
            Key.displayDuration: 1.5
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

    var displayDuration: TimeInterval {
        get { defaults.double(forKey: Key.displayDuration) }
        set { defaults.set(min(max(newValue, 0.4), 5), forKey: Key.displayDuration) }
    }
}
