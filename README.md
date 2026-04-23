# Sanity-Preserving Frame Stepper (for macOS)

Better video player holy fuck.

If you are trying to analyze a video frame-by-frame on a Mac, you have probably realized that every major video player is actively conspiring against you. This repo is the ultimate, zero-bullshit configuration for `mpv` that fixes all of it.

## The Motivation

- I just want clean frame stepping.
- QuickTime keeps fighting me with chrome.
- IINA hover chrome still gets in the way.
- VLC is not much better.
- Default `mpv` quits at EOF.
- Default `mpv` controls can cover the frame.

## The Solution

A completely naked video player where:

1. You can step forward (`.`) and backward (`,`) frame-by-frame flawlessly.
2. The UI is permanently pinned **below** the video in its own physical box (zero overlapping pixels, zero hover animations).
3. The window has no macOS borders or fake title bars.
4. The video freezes on the last frame instead of closing the app.
5. Pressing Spacebar at the end of the video instantly loops back to `00:00` and starts playing.

## Step 1: Install `mpv`

If you don't have it, install it via Homebrew:

```bash
brew install mpv
```

This repo assumes Homebrew `mpv` lives at:

```text
/opt/homebrew/bin/mpv
```

## Step 2: Add the Replay Script

By default, `--keep-open` traps you at the end of the file and spacebar does nothing. Run this single command in your terminal to create a Lua script that fixes the spacebar logic:

```bash
mkdir -p ~/.config/mpv/scripts && cat << 'EOF' > ~/.config/mpv/scripts/replay.lua
mp.add_key_binding("SPACE", "replay_eof", function()
    if mp.get_property_native("eof-reached") then
        mp.command("no-osd seek 0 absolute")
        mp.set_property("pause", "no")
    else
        mp.command("cycle pause")
    end
end)
EOF
```

The same script is tracked in this repo at `mpv/scripts/replay.lua`, and `./install.sh` installs it automatically.

## Step 3: Run Your Video

Launch your video with this exact command to banish the UI to the shadow realm (a dedicated black box under the video) and kill the borders:

```bash
mpv --keep-open --no-border --script-opts=osc-layout=bottombar,osc-visibility=always,osc-boxvideo=yes your_video.mp4
```

Pro-tip: Alias this command in your `.zshrc` so you don't have to type it every time.

## Step 4: Make Double-Clicked Videos Use It Too

macOS default-app handling wants an `.app` bundle, not just a shell command. This repo builds a minimal AppKit wrapper app named `Better Video Player.app`.

Run:

```bash
./install.sh
```

That creates:

```text
~/Applications/Better Video Player.app
~/.config/mpv/mpv.conf
~/.config/mpv/scripts/replay.lua
```

Then it registers `computer.moonshot.better-video-player` as the default handler for common video types, including `.mp4`, `.mov`, `.mkv`, `.webm`, `.avi`, `.wmv`, `.m4v`, `.ts`, `.m2ts`, `.flv`, and `.ogv`.

When Finder, Spotlight, AirDrop, or `open some-video.mp4` sends the wrapper a video file, it immediately launches:

```bash
/opt/homebrew/bin/mpv --keep-open --no-border --script-opts=osc-layout=bottombar,osc-visibility=always,osc-boxvideo=yes -- <video paths>
```

The wrapper is an `LSUIElement`, so it does not sit in the Dock. It starts `mpv`, hands off the video paths, and quits.

Enjoy your sanity.

## Files

- `Sources/BetterVideoPlayer.swift`: the tiny AppKit wrapper that receives opened files and launches `mpv`.
- `Resources/Info.plist`: declares the app bundle, hidden Dock behavior, and supported video document types.
- `scripts/set-defaults.swift`: registers the wrapper as the default handler for common video content types.
- `mpv/mpv.conf`: global mpv defaults matching the command above.
- `mpv/scripts/replay.lua`: SPACE replay behavior at EOF while keeping normal pause/unpause elsewhere.
- `install.sh`: rebuilds the app, registers it with LaunchServices, installs the mpv config, and installs the replay script.

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

Copied in the bundle plist, mpv config, and replay script:

```bash
cp Resources/Info.plist "$HOME/Applications/Better Video Player.app/Contents/Info.plist"
mkdir -p "$HOME/.config/mpv/scripts"
cp mpv/mpv.conf "$HOME/.config/mpv/mpv.conf"
cp mpv/scripts/replay.lua "$HOME/.config/mpv/scripts/replay.lua"
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
