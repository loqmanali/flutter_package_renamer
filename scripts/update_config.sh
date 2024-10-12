#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to print error messages and exit
function error_exit {
    echo -e "❌ $1" 1>&2  # Added emoji
    exit 1
}

# Check if config.json exists
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    error_exit "Error: $CONFIG_FILE not found! Please create config.json with required fields."
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    error_exit "Error: jq is not installed. Please install jq to proceed. (https://stedolan.github.io/jq/)"
fi

# Read fields from config.json using jq
APP_NAME=$(jq -r '.appName' "$CONFIG_FILE")
APP_DESCRIPTION=$(jq -r '.appDescription' "$CONFIG_FILE")
APP_VERSION=$(jq -r '.appVersion' "$CONFIG_FILE")
ANDROID_PACKAGE=$(jq -r '.androidPackage' "$CONFIG_FILE")
IOS_BUNDLE_ID=$(jq -r '.iosBundleId' "$CONFIG_FILE")
APP_COPYRIGHT=$(jq -r '.appCopyright' "$CONFIG_FILE")

# Validate that the necessary fields are present
if [ -z "$APP_NAME" ] || [ -z "$APP_DESCRIPTION" ] || [ -z "$APP_VERSION" ] || [ -z "$ANDROID_PACKAGE" ] || [ -z "$IOS_BUNDLE_ID" ] || [ -z "$APP_COPYRIGHT" ]; then
    error_exit "Error: One or more required fields are missing in $CONFIG_FILE."
fi

# Starting configuration update message
echo -e "🚀 Starting configuration update..."  # Added rocket emoji

# Check if rename.dart exists
RENAME_DART="bin/rename.dart"
if [ ! -f "$RENAME_DART" ]; then
    error_exit "Error: $RENAME_DART not found! Please ensure rename.dart exists with the necessary renaming logic."
fi

# Run the Dart script to rename Android and iOS packages
echo -e "🔄 Renaming Android package..."  # Added refresh emoji
dart run $RENAME_DART "$ANDROID_PACKAGE" "--android"

echo -e "🔄 Renaming iOS bundle identifier..."  # Added refresh emoji
dart run $RENAME_DART "$IOS_BUNDLE_ID" "--ios"

# Update pubspec.yaml with app name, description, and version
echo -e "📝 Updating pubspec.yaml with app details..."  # Added memo emoji
PUBSPEC_FILE="pubspec.yaml"

if [ -f "$PUBSPEC_FILE" ]; then
    # Backup pubspec.yaml
    cp "$PUBSPEC_FILE" "${PUBSPEC_FILE}.bak"

    # Update name (lowercase as per pubspec.yaml conventions)
    sed -i.bak "s/^name: .*/name: ${APP_NAME,,}/" "$PUBSPEC_FILE"

    # Update description
    sed -i.bak "s/^description: .*/description: \"$APP_DESCRIPTION\"/" "$PUBSPEC_FILE"

    # Update version
    sed -i.bak "s/^version: .*/version: $APP_VERSION/" "$PUBSPEC_FILE"

    echo "pubspec.yaml updated."
else
    echo "Warning: $PUBSPEC_FILE not found."
fi

# Update Android build.gradle with versionCode and versionName
echo -e "📱 Updating Android build.gradle with version details..."  # Added mobile phone emoji
ANDROID_BUILD_GRADLE_FILE="android/app/build.gradle"

if [ -f "$ANDROID_BUILD_GRADLE_FILE" ]; then
    # Extract versionCode and versionName from appVersion
    VERSION_NAME=$(echo "$APP_VERSION" | cut -d'+' -f1)
    VERSION_CODE=$(echo "$APP_VERSION" | cut -d'+' -f2)

    # Update versionCode
    sed -i.bak "s/versionCode [0-9]*/versionCode $VERSION_CODE/" "$ANDROID_BUILD_GRADLE_FILE"

    # Update versionName
    sed -i.bak "s/versionName \".*\"/versionName \"$VERSION_NAME\"/" "$ANDROID_BUILD_GRADLE_FILE"

    echo "Android build.gradle updated with version details."
else
    echo "Warning: $ANDROID_BUILD_GRADLE_FILE not found."
fi

# Update iOS Info.plist with version details
echo -e "🍏 Updating iOS Info.plist with version details..."  # Added apple emoji
IOS_INFO_PLIST_FILE="ios/Runner/Info.plist"

if [ -f "$IOS_INFO_PLIST_FILE" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NAME" "$IOS_INFO_PLIST_FILE"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION_CODE" "$IOS_INFO_PLIST_FILE"
    echo "iOS Info.plist updated with version details."
else
    echo "Warning: $IOS_INFO_PLIST_FILE not found."
fi

# Update Android strings.xml with app description and copyright
echo -e "📱 Updating Android strings.xml with app details..."  # Added mobile phone emoji
ANDROID_STRINGS_FILE="android/app/src/main/res/values/strings.xml"

if [ -f "$ANDROID_STRINGS_FILE" ]; then
    # Update app_description
    if grep -q "<string name=\"app_description\">" "$ANDROID_STRINGS_FILE"; then
        sed -i.bak "s/<string name=\"app_description\">.*<\/string>/<string name=\"app_description\">$APP_DESCRIPTION<\/string>/" "$ANDROID_STRINGS_FILE"
    else
        # Insert before closing </resources>
        sed -i.bak "/<\/resources>/i \\    <string name=\"app_description\">$APP_DESCRIPTION<\/string>" "$ANDROID_STRINGS_FILE"
    fi

    # Add or update copyright
    if grep -q "<string name=\"app_copyright\">" "$ANDROID_STRINGS_FILE"; then
        sed -i.bak "s/<string name=\"app_copyright\">.*<\/string>/<string name=\"app_copyright\">$APP_COPYRIGHT<\/string>/" "$ANDROID_STRINGS_FILE"
    else
        # Insert before closing </resources>
        sed -i.bak "/<\/resources>/i \\    <string name=\"app_copyright\">$APP_COPYRIGHT<\/string>" "$ANDROID_STRINGS_FILE"
    fi

    echo "Android strings.xml updated with app details."
else
    echo "Warning: $ANDROID_STRINGS_FILE not found."
fi

# Update iOS Info.plist with app details
echo -e "🍏 Updating iOS Info.plist with app details..."  # Added apple emoji
if [ -f "$IOS_INFO_PLIST_FILE" ]; then
    # Update CFBundleDisplayName if needed
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$IOS_INFO_PLIST_FILE" || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string \"$APP_NAME\"" "$IOS_INFO_PLIST_FILE"

    # Add or update NSHumanReadableCopyright
    /usr/libexec/PlistBuddy -c "Set :NSHumanReadableCopyright $APP_COPYRIGHT" "$IOS_INFO_PLIST_FILE" || \
    /usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string \"$APP_COPYRIGHT\"" "$IOS_INFO_PLIST_FILE"

    echo "iOS Info.plist updated with app details."
else
    echo "Warning: $IOS_INFO_PLIST_FILE not found."
fi

echo -e "✅ Configuration update completed successfully."  # Added check mark emoji
