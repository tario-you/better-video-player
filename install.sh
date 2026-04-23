#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_name="Better Video Player.app"
app_path="$HOME/Applications/$app_name"
bundle_id="computer.moonshot.better-video-player"
mpv_conf_dir="$HOME/.config/mpv"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required. Install Xcode command line tools first." >&2
  exit 1
fi

if [[ ! -x /opt/homebrew/bin/mpv ]]; then
  echo "mpv was not found at /opt/homebrew/bin/mpv." >&2
  echo "Install it with: brew install mpv" >&2
  exit 1
fi

mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources" "$mpv_conf_dir"

xcrun swiftc \
  -O \
  -framework AppKit \
  -o "$app_path/Contents/MacOS/BetterVideoPlayer" \
  "$repo_root/Sources/BetterVideoPlayer.swift"

cp "$repo_root/Resources/Info.plist" "$app_path/Contents/Info.plist"
cp "$repo_root/mpv/mpv.conf" "$mpv_conf_dir/mpv.conf"
chmod +x "$app_path/Contents/MacOS/BetterVideoPlayer"

/usr/bin/codesign --force --sign - "$app_path"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app_path"
xcrun swift "$repo_root/scripts/set-defaults.swift"

echo "Installed $app_path"
echo "Registered $bundle_id as the default video handler."
