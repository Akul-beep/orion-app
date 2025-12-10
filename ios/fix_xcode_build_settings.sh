#!/bin/bash
# This script adds module map path to Xcode project

PROJECT_FILE="Runner.xcodeproj/project.pbxproj"

# Check if we need to add SWIFT_INCLUDE_PATHS
if ! grep -q "SWIFT_INCLUDE_PATHS.*app_links" "$PROJECT_FILE" 2>/dev/null; then
    echo "Module map paths should be set via Pods xcconfig files"
    echo "The issue is likely that Xcode isn't loading the Pods config"
    echo ""
    echo "Solution: Use Flutter commands instead:"
    echo "  flutter run              # For simulator"
    echo "  flutter build ipa        # For App Store"
fi
