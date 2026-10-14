# Keyviz

Keyviz is a lightweight, native macOS menu bar app that displays your
keystrokes as clean key caps on screen. It is useful for demos, screen
recordings, presentations, and tutorials.

![Keyviz app icon and keyboard overlay](Resources/AppIcon.svg)

## Features

- Native AppKit app with no third-party dependencies
- Persistent keys that highlight while they are pressed
- WASD, arrow-key, and combined presets
- Custom selection of up to 12 keys
- Global key state across apps, Spaces, and full-screen windows
- Configurable opacity, color, and screen position
- Click-through overlay that never steals focus
- Remembers your preferences
- Runs only in the menu bar

## Install

1. Download and open `Keyviz-1.1.0-beta.dmg`.
2. Drag **Keyviz** to **Applications**.
3. Open Keyviz and grant Accessibility access when macOS asks.
4. Use the keyboard icon in the menu bar to customize the overlay.

Because release builds are currently ad-hoc signed, macOS may require you to
right-click Keyviz and select **Open** the first time.

Choose **Displayed Keys → Customize Keys…** from the menu bar to select the
keys that remain visible. Selected boxes brighten while their keys are held.

Keyviz observes keyboard events only to update the overlay. It does not
store or transmit keystrokes.

## Build

Requires macOS 13 or later and the Swift toolchain from Xcode or Xcode Command
Line Tools.

```sh
./Scripts/test.sh
./Scripts/package-dmg.sh
```

The app bundle and disk image are written to `build/`.

## License

MIT