# Keyviz

Keyviz is a lightweight, native macOS menu bar app that displays your
keystrokes as clean key caps on screen. It is useful for demos, screen
recordings, presentations, and tutorials.

![Keyviz app icon and keyboard overlay](Resources/AppIcon.svg)

## Features

- Native AppKit app with no third-party dependencies
- Global keystroke overlay across apps, Spaces, and full-screen windows
- Configurable opacity, color, screen position, and display time
- Click-through overlay that never steals focus
- Remembers your preferences
- Runs only in the menu bar

## Install

1. Download and open `Keyviz-1.0.0.dmg`.
2. Drag **Keyviz** to **Applications**.
3. Open Keyviz and grant Accessibility access when macOS asks.
4. Use the keyboard icon in the menu bar to customize the overlay.

Because release builds are currently ad-hoc signed, macOS may require you to
right-click Keyviz and select **Open** the first time.

Keyviz observes keyboard events only to render them on screen. It does not
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