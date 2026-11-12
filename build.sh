#!/bin/zsh
set -eu
cd "${0:A:h}"
task_compiler="$(xcrun --find swiftc)"
task_min="13.0"
task_flags=()
case "${1:-native}" in
  native)
    task_arch="$(uname -m)"
    task_bundle="dist/MiniLab Piano.app"
    ;;
  intel|--intel)
    task_arch="x86_64"
    task_bundle="dist/MiniLab Piano Intel.app"
    ;;
  sonoma|--sonoma)
    task_arch="x86_64"
    task_bundle="dist/MiniLab Piano Intel Sonoma.app"
    task_compiler="/Library/Developer/CommandLineTools/usr/bin/swiftc"
    task_min="14.0"
    task_flags=(-sdk /Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk -swift-version 5)
    ;;
  *)
    echo "Usage: ./build.sh [native|--intel|--sonoma]" >&2
    exit 2
    ;;
esac
mkdir -p "$task_bundle/Contents/MacOS"
"$task_compiler" "${task_flags[@]}" -target "${task_arch}-apple-macosx${task_min}" -module-cache-path /tmp/minilab-swift-module-cache Sources/*.swift -o "$task_bundle/Contents/MacOS/MiniLabPiano" -framework AppKit -framework AVFoundation -framework CoreMIDI
cat > "$task_bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>MiniLabPiano</string><key>CFBundleIdentifier</key><string>local.minilab.piano</string><key>CFBundleName</key><string>MiniLab Piano</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>1</string><key>NSHighResolutionCapable</key><true/><key>LSMinimumSystemVersion</key><string>13.0</string></dict></plist>
PLIST
plutil -replace LSMinimumSystemVersion -string "$task_min" "$task_bundle/Contents/Info.plist"
codesign --force --sign - "$task_bundle"
echo "Built: $task_bundle ($task_arch, macOS $task_min+)"
