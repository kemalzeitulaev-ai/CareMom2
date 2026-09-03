#!/bin/bash
# Archive CareMom2 and upload to App Store Connect (TestFlight).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CareMom2.xcodeproj"
SCHEME="CareMom2"
ARCHIVE="$ROOT/build/CareMom2.xcarchive"
EXPORT_PLIST="$ROOT/ExportOptions.plist"
TEAM="66TWNVSJ4U"

echo "CareMom2 → TestFlight"
echo "====================="
echo "Version: $(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' /dev/stdin 2>/dev/null <<< "" || defaults read "$ROOT/CareMom2.xcodeproj/project.pbxproj" MARKETING_VERSION 2>/dev/null || echo 2.1)"
echo ""

mkdir -p "$ROOT/build"

echo "1/2 Archive (Release)..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -destination 'generic/platform=iOS' \
  DEVELOPMENT_TEAM="$TEAM" \
  CODE_SIGN_STYLE=Automatic

echo ""
echo "2/2 Export IPA (upload via Xcode Organizer)..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$ROOT/build/export" \
  -exportOptionsPlist "$ROOT/ExportOptions-export-only.plist" \
  -allowProvisioningUpdates

echo ""
echo "✅ Archive: $ARCHIVE"
echo "✅ IPA:     $ROOT/build/export/CareMom2.ipa"
echo ""
echo "Upload в TestFlight:"
echo "  Xcode → Window → Organizer → Archives → CareMom2 → Distribute App → App Store Connect → Upload"
echo ""
echo "Или в терминале (нужен Apple ID с доступом к ASC):"
echo "  xcodebuild -exportArchive -archivePath \"$ARCHIVE\" -exportOptionsPlist \"$EXPORT_PLIST\" -exportPath \"$ROOT/build/export\" -allowProvisioningUpdates"
