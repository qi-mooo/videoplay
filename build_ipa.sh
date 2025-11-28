#!/bin/bash
# Build unsigned IPA using Tuist
set -e

echo "🚀 Building iOS App with Tuist..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf Videoplay.xcworkspace
rm -rf Videoplay.xcodeproj
rm -f Videoplay.ipa
rm -rf Payload

# Generate Xcode project with Tuist
echo "📦 Generating Xcode project..."
tuist generate

# Build the app
echo "🔨 Building Release configuration..."
xcodebuild -workspace Videoplay.xcworkspace \
    -scheme Videoplay \
    -configuration Release \
    -sdk iphoneos \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Videoplay*/Build/Products/Release-iphoneos -name "Videoplay.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

echo "📱 Found app at: $APP_PATH"

# Create IPA
echo "📦 Creating IPA..."
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qr Videoplay.ipa Payload
rm -rf Payload

# Show result
echo "✅ Build complete!"
ls -lh Videoplay.ipa
echo ""
echo "📍 IPA location: $(pwd)/Videoplay.ipa"
echo "📦 Size: $(du -h Videoplay.ipa | cut -f1)"
