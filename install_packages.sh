#!/bin/bash
# Script to install Flutter packages
cd "$(dirname "$0")"
echo "📦 Installing Flutter packages..."
echo "Location: $(pwd)"

# Try different Flutter paths
if command -v flutter &> /dev/null; then
    flutter pub get
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    "$HOME/flutter/bin/flutter" pub get
elif [ -f "/Applications/flutter/bin/flutter" ]; then
    "/Applications/flutter/bin/flutter" pub get
else
    echo "❌ Flutter not found. Please run 'flutter pub get' in your IDE or terminal."
    echo "Or install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi
