# Better Video Player

Tiny macOS wrapper that makes double-clicked video files open in Homebrew `mpv` with a cleaner always-visible control bar:

```bash
mpv --keep-open --no-border --script-opts=osc-layout=bottombar,osc-visibility=always,osc-boxvideo=yes your_video.mp4
```

## What This Does

macOS default-app handling wants an `.app` bundle, not just a shell command. This repo builds a minimal AppKit wrapper app named `Better Video Player.app`.

When Finder, Spotlight, AirDrop, or `open some-video.mp4` sends the wrapper a video file, it immediately launches:

```bash
/opt/homebrew/bin/mpv --keep-open --no-border --script-opts=osc-layout=bottombar,osc-visibility=always,osc-boxvideo=yes -- <video paths>
```

The wrapper is an `LSUIElement`, so it does not sit in the Dock. It starts `mpv`, hands off the video paths, and quits.

The repo also installs an `mpv.conf` so direct terminal launches like `mpv movie.mkv` use the same defaults.

## Files

- `Sources/BetterVideoPlayer.swift`: the tiny AppKit wrapper that receives opened files and launches `mpv`.
- `Resources/Info.plist`: declares the app bundle, hidden Dock behavior, and supported video document types.
- `scripts/set-defaults.swift`: registers the wrapper as the default handler for common video content types.
- `mpv/mpv.conf`: global mpv defaults matching the command above.
- `install.sh`: rebuilds the app, registers it with LaunchServices, and installs the mpv config.

## Install

Requirements:

- macOS
- Xcode command line tools
- Homebrew `mpv` at `/opt/homebrew/bin/mpv`

Run:

```bash
./install.sh
```

That creates:

```text
~/Applications/Better Video Player.app
~/.config/mpv/mpv.conf
```

Then it registers `computer.moonshot.better-video-player` as the default handler for common video types, including `.mp4`, `.mov`, `.mkv`, `.webm`, `.avi`, `.wmv`, `.m4v`, `.ts`, `.m2ts`, `.flv`, and `.ogv`.

## How I Set It Up On This Mac

I first checked whether `mpv` existed and whether there was already an `mpv.app` bundle:

```bash
which mpv
mdfind 'kMDItemCFBundleIdentifier == "io.mpv" || kMDItemCFBundleIdentifier == "io.mpv.MPV" || kMDItemDisplayName == "mpv.app"'
```

This Mac had Homebrew `mpv` at `/opt/homebrew/bin/mpv`, but no app bundle. Since macOS default-open behavior needs an app bundle, I made `Better Video Player.app`.

Then I compiled the Swift wrapper:

```bash
xcrun swiftc -O -framework AppKit \
  -o "$HOME/Applications/Better Video Player.app/Contents/MacOS/BetterVideoPlayer" \
  Sources/BetterVideoPlayer.swift
```

Copied in the bundle plist and mpv config:

```bash
cp Resources/Info.plist "$HOME/Applications/Better Video Player.app/Contents/Info.plist"
mkdir -p "$HOME/.config/mpv"
cp mpv/mpv.conf "$HOME/.config/mpv/mpv.conf"
```

Signed and registered the wrapper:

```bash
codesign --force --sign - "$HOME/Applications/Better Video Player.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$HOME/Applications/Better Video Player.app"
```

Then I used `scripts/set-defaults.swift` to call `LSSetDefaultRoleHandlerForContentType` for video UTIs.

## Verify

Check the registered default handlers:

```bash
xcrun swift - <<'SWIFT'
import CoreServices
import UniformTypeIdentifiers

for ext in ["mp4", "mov", "mkv", "webm", "avi", "wmv", "m4v"] {
    guard let type = UTType(filenameExtension: ext) else { continue }
    let handler = LSCopyDefaultRoleHandlerForContentType(type.identifier as CFString, .viewer)?.takeRetainedValue() as String?
    print("\(ext) \(type.identifier): \(handler ?? "nil")")
}
SWIFT
```

Expected handler:

```text
computer.moonshot.better-video-player
```

You can also test an actual file:

```bash
open /path/to/video.mp4
```

It should launch `mpv` with the no-border, keep-open, bottom-bar OSC setup.
