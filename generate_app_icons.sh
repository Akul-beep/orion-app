#!/bin/bash

# Script to generate iOS app icons from your logo
# Usage: ./generate_app_icons.sh

echo "📱 Generating iOS App Icons from app_logo.png"
echo ""

# Check if source logo exists
SOURCE_LOGO="assets/logo/app_logo.png"
ICON_OUTPUT_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE_LOGO" ]; then
    echo "❌ Error: Logo not found at $SOURCE_LOGO"
    echo "   Please make sure your logo is at assets/logo/app_logo.png"
    exit 1
fi

# Check if ImageMagick is installed (sips is built into macOS)
if command -v sips &> /dev/null; then
    echo "✅ Using sips (built into macOS) to resize images"
    USE_SIPS=true
elif command -v convert &> /dev/null; then
    echo "✅ Using ImageMagick to resize images"
    USE_SIPS=false
else
    echo "⚠️  Neither sips nor ImageMagick found"
    echo "   Using sips (should be available on macOS)..."
    USE_SIPS=true
fi

# Create output directory if it doesn't exist
mkdir -p "$ICON_OUTPUT_DIR"

echo ""
echo "📐 Generating icon sizes..."

# Function to resize using sips (macOS built-in)
resize_with_sips() {
    local size=$1
    local output=$2
    sips -z $size $size "$SOURCE_LOGO" --out "$output" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Generated ${size}x${size}"
    else
        echo "   ❌ Failed to generate ${size}x${size}"
    fi
}

# Function to resize using ImageMagick
resize_with_imagemagick() {
    local size=$1
    local output=$2
    convert "$SOURCE_LOGO" -resize "${size}x${size}" "$output" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Generated ${size}x${size}"
    else
        echo "   ❌ Failed to generate ${size}x${size}"
    fi
}

# Generate all required iOS icon sizes
# 20pt (@1x, @2x, @3x)
resize_with_sips 20 "$ICON_OUTPUT_DIR/Icon-App-20x20@1x.png"
resize_with_sips 40 "$ICON_OUTPUT_DIR/Icon-App-20x20@2x.png"
resize_with_sips 60 "$ICON_OUTPUT_DIR/Icon-App-20x20@3x.png"

# 29pt (@1x, @2x, @3x)
resize_with_sips 29 "$ICON_OUTPUT_DIR/Icon-App-29x29@1x.png"
resize_with_sips 58 "$ICON_OUTPUT_DIR/Icon-App-29x29@2x.png"
resize_with_sips 87 "$ICON_OUTPUT_DIR/Icon-App-29x29@3x.png"

# 40pt (@1x, @2x, @3x)
resize_with_sips 40 "$ICON_OUTPUT_DIR/Icon-App-40x40@1x.png"
resize_with_sips 80 "$ICON_OUTPUT_DIR/Icon-App-40x40@2x.png"
resize_with_sips 120 "$ICON_OUTPUT_DIR/Icon-App-40x40@3x.png"

# 60pt (@2x, @3x)
resize_with_sips 120 "$ICON_OUTPUT_DIR/Icon-App-60x60@2x.png"
resize_with_sips 180 "$ICON_OUTPUT_DIR/Icon-App-60x60@3x.png"

# 76pt (@1x, @2x)
resize_with_sips 76 "$ICON_OUTPUT_DIR/Icon-App-76x76@1x.png"
resize_with_sips 152 "$ICON_OUTPUT_DIR/Icon-App-76x76@2x.png"

# 83.5pt (@2x)
resize_with_sips 167 "$ICON_OUTPUT_DIR/Icon-App-83.5x83.5@2x.png"

# 1024x1024 (App Store)
resize_with_sips 1024 "$ICON_OUTPUT_DIR/Icon-App-1024x1024@1x.png"

echo ""
echo "✅ Done! All icon sizes generated in $ICON_OUTPUT_DIR"
echo ""
echo "📝 Next steps:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Go to Assets.xcassets → AppIcon"
echo "   3. The icons should already be there!"
echo "   4. Clean build folder (Cmd+Shift+K)"
echo "   5. Run the app (Cmd+R)"
echo ""
echo "🎉 Your logo is now the app icon!"

