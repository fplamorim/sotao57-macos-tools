#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="/Applications/SOTAO57 macOS Tools.app"
LEGACY_APP_PATH="/Applications/SOTAO57 Basic Mac Tools.app"
CONTENTS="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES_DIR="$CONTENTS/Resources"
BUILD_TMP="$(mktemp -d /tmp/sotao57_macos_tools_build.XXXXXX)"
trap 'rm -rf "$BUILD_TMP"' EXIT

# Encerra instância anterior antes de atualizar o bundle
pkill -x SOTAO57macOSTools || true
pkill -x SOTAO57BasicMacTools || true
sleep 0.3

# 1. Ícone .icns
BASE_PNG="$BUILD_TMP/icon_1024.png"
ICONSET="$BUILD_TMP/AppIcon.iconset"
mkdir -p "$ICONSET"

/usr/bin/swift "$ROOT/scripts/make_icon.swift" "$BASE_PNG"
for sz in 16 32 128 256 512; do
    sips -z "$sz" "$sz" "$BASE_PNG" --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
    sz2=$((sz * 2))
    sips -z "$sz2" "$sz2" "$BASE_PNG" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$BUILD_TMP/AppIcon.icns"

# 2. Compilar binário nativo Universal (arm64 + x86_64)
SWIFT_SRCS=("$ROOT"/Sources/*.swift)
FRAMEWORKS=(
    -framework SwiftUI
    -framework AppKit
    -framework UniformTypeIdentifiers
    -framework PDFKit
    -framework Vision
    -framework CoreGraphics
    -framework CoreText
    -framework ImageIO
)

/usr/bin/swiftc \
    -swift-version 5 \
    -O \
    -target arm64-apple-macosx13.0 \
    "${FRAMEWORKS[@]}" \
    -o "$BUILD_TMP/SOTAO57macOSTools_arm64" \
    "${SWIFT_SRCS[@]}"

if /usr/bin/swiftc \
    -swift-version 5 \
    -O \
    -target x86_64-apple-macosx13.0 \
    "${FRAMEWORKS[@]}" \
    -o "$BUILD_TMP/SOTAO57macOSTools_x86_64" \
    "${SWIFT_SRCS[@]}" 2>/dev/null; then
    lipo -create \
        "$BUILD_TMP/SOTAO57macOSTools_arm64" \
        "$BUILD_TMP/SOTAO57macOSTools_x86_64" \
        -output "$BUILD_TMP/SOTAO57macOSTools"
    echo "ARCH=Universal(arm64+x86_64)"
else
    cp "$BUILD_TMP/SOTAO57macOSTools_arm64" "$BUILD_TMP/SOTAO57macOSTools"
    echo "ARCH=arm64"
fi

# 3. Montar bundle .app em /Applications
rm -rf "$LEGACY_APP_PATH"
rm -rf "$APP_PATH"
mkdir -p "$MACOS_DIR" "$RES_DIR"
cp "$BUILD_TMP/SOTAO57macOSTools" "$MACOS_DIR/SOTAO57macOSTools"
chmod +x "$MACOS_DIR/SOTAO57macOSTools"
cp "$BUILD_TMP/AppIcon.icns" "$RES_DIR/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>pt</string>
        <string>es</string>
    </array>
    <key>CFBundleDisplayName</key><string>SOTAO57 macOS Tools</string>
    <key>CFBundleExecutable</key><string>SOTAO57macOSTools</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>com.sotao57.macostools</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>SOTAO57 macOS Tools</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.1.1</string>
    <key>CFBundleVersion</key><string>3</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSRequiresAquaSystemAppearance</key><true/>
    <key>NSHumanReadableCopyright</key><string>Copyright © 2026 Fernando Amorim (SOTAO57). MIT License.</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key><string>Supported Media and Documents</string>
            <key>CFBundleTypeRole</key><string>Viewer</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.audio</string>
                <string>public.movie</string>
                <string>public.image</string>
                <string>public.text</string>
                <string>com.adobe.pdf</string>
                <string>public.spreadsheet</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# 4. Assinar ad-hoc e verificar
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
touch "$APP_PATH"

echo "BUILD_OK: $APP_PATH"
