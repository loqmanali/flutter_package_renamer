#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to print error messages and exit
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Path to the config.json file
CONFIG_FILE="config.json"

# Path to the strings.xml file
STRINGS_FILE="android/app/src/main/res/values/strings.xml"

# Check if config.json exists
if [ ! -f "$CONFIG_FILE" ]; then
    error_exit "❌ Error: $CONFIG_FILE not found! Please create config.json with required fields."
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    error_exit "❌ Error: jq is not installed. Please install jq to proceed. (https://stedolan.github.io/jq/)"
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
    error_exit "❌ Error: One or more required fields are missing in $CONFIG_FILE."
fi

# Starting configuration update with emoji
echo "🚀 Starting configuration update..."
echo "App Name: $APP_NAME 📱"
echo "App Description: $APP_DESCRIPTION 📝"
echo "App Version: $APP_VERSION 🔢"
echo "Android Package: $ANDROID_PACKAGE 🤖"
echo "iOS Bundle ID: $IOS_BUNDLE_ID 🍏"
echo "App Copyright: $APP_COPYRIGHT ©️"
echo "----------------------------------------"

# Find Flutter executable path
FLUTTER_PATH=$(which flutter)
if [ -z "$FLUTTER_PATH" ]; then
    error_exit "❌ Error: Flutter executable not found in PATH."
fi

# Check if flutter_package_renamer is installed
if ! grep -q "flutter_package_renamer:" pubspec.yaml; then
    error_exit "❌ Error: flutter_package_renamer is not listed in pubspec.yaml. Please add it to your dependencies."
fi

# Run flutter pub get to ensure the package is available
echo "📦 Running flutter pub get..."
flutter pub get

# Run the package renamer for Android and iOS
echo "🔄 Renaming Android package..."
flutter pub run flutter_package_renamer:rename "$ANDROID_PACKAGE" "--android"

echo "🔄 Renaming iOS bundle identifier..."
flutter pub run flutter_package_renamer:rename "$IOS_BUNDLE_ID" "--ios"

# Update pubspec.yaml with app name, description, and version
echo "📄 Updating pubspec.yaml with app details..."
PUBSPEC_FILE="pubspec.yaml"

if [ -f "$PUBSPEC_FILE" ]; then
    # Backup pubspec.yaml
    cp "$PUBSPEC_FILE" "${PUBSPEC_FILE}.bak"

    # Update name (lowercase as per pubspec.yaml conventions)
    sed -i.bak "s/^name: .*/name: ${APP_NAME}/" "$PUBSPEC_FILE"

    # Update description
    sed -i.bak "s/^description: .*/description: \"${APP_DESCRIPTION}\"/" "$PUBSPEC_FILE"

    # Update version
    sed -i.bak "s/^version: .*/version: ${APP_VERSION}/" "$PUBSPEC_FILE"

    echo "✅ pubspec.yaml updated."
else
    echo "⚠️ Warning: $PUBSPEC_FILE not found."
fi

# Function to extract versionCode and versionName
extract_versions() {
    local version="$1"
    if [[ "$version" == *"+"* ]]; then
        VERSION_NAME=$(echo "$version" | cut -d'+' -f1)
        VERSION_CODE=$(echo "$version" | cut -d'+' -f2)
    else
        VERSION_NAME="$version"
        VERSION_CODE=1
        echo "⚠️ Warning: VERSION_CODE missing in APP_VERSION. Setting VERSION_CODE to 1."
    fi
}

# Extract versionCode and versionName from APP_VERSION
extract_versions "$APP_VERSION"

# Ensure VERSION_CODE is an integer
if ! [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
    error_exit "❌ Error: VERSION_CODE extracted from APP_VERSION is not a valid integer."
fi

# Update Android build.gradle with versionCode and versionName
# echo "🛠️ Updating Android build.gradle with version details..."
# ANDROID_BUILD_GRADLE_FILE="android/app/build.gradle"

# if [ -f "$ANDROID_BUILD_GRADLE_FILE" ]; then
#     # Backup build.gradle
#     cp "$ANDROID_BUILD_GRADLE_FILE" "${ANDROID_BUILD_GRADLE_FILE}.bak"

#     # Create a temporary file
#     TEMP_FILE=$(mktemp)

#     # Process the file
#     while IFS= read -r line
#     do
#         echo "$line" >> "$TEMP_FILE"
#         if [[ "$line" == *"defaultConfig {"* ]]; then
#             echo "        versionCode $VERSION_CODE" >> "$TEMP_FILE"
#             echo "        versionName \"$VERSION_NAME\"" >> "$TEMP_FILE"
#         fi
#     done < "$ANDROID_BUILD_GRADLE_FILE"

#     # Replace original file with processed file
#     mv "$TEMP_FILE" "$ANDROID_BUILD_GRADLE_FILE"

#     echo "✅ Android build.gradle updated with version details."
# else
#     echo "⚠️ Warning: $ANDROID_BUILD_GRADLE_FILE not found."
# fi

# Update iOS Info.plist with version details
echo "🛠️ Updating iOS Info.plist with version details..."
IOS_INFO_PLIST_FILE="ios/Runner/Info.plist"

if [ -f "$IOS_INFO_PLIST_FILE" ]; then
    # Backup Info.plist
    cp "$IOS_INFO_PLIST_FILE" "${IOS_INFO_PLIST_FILE}.bak"

    # Update CFBundleShortVersionString
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NAME" "$IOS_INFO_PLIST_FILE" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION_NAME" "$IOS_INFO_PLIST_FILE"

    # Update CFBundleVersion
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION_CODE" "$IOS_INFO_PLIST_FILE" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION_CODE" "$IOS_INFO_PLIST_FILE"

    echo "✅ iOS Info.plist updated with version details."
else
    echo "⚠️ Warning: $IOS_INFO_PLIST_FILE not found."
fi

# Update Android package name in build.gradle
echo "🔄 Updating Android package name in build.gradle..."
GRADLE_FILE="android/app/build.gradle"

if [ ! -f "$GRADLE_FILE" ]; then
    error_exit "❌ Error: $GRADLE_FILE not found."
fi

# Update applicationId and namespace
awk -v package="$ANDROID_PACKAGE" '
    /defaultConfig {/,/}/ {
        if ($1 == "applicationId") {
            $0 = "        applicationId \"" package "\""
        }
    }
    /android {/,/}/ {
        if ($1 == "namespace") {
            $0 = "    namespace \"" package "\""
        }
    }
    {print}
' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp" && mv "${GRADLE_FILE}.tmp" "$GRADLE_FILE"

echo "✅ Updated $GRADLE_FILE with new package name: $ANDROID_PACKAGE"

# Update iOS bundle identifier
echo "🔄 Updating iOS bundle identifier..."
PLIST_FILE="ios/Runner/Info.plist"

if [ ! -f "$PLIST_FILE" ]; then
    error_exit "❌ Error: $PLIST_FILE not found."
fi

# Use PlistBuddy to update CFBundleIdentifier
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $IOS_BUNDLE_ID" "$PLIST_FILE"

echo "✅ Updated $PLIST_FILE with new bundle identifier: $IOS_BUNDLE_ID"

# Update Android strings.xml with app details
echo "📜 Updating Android strings.xml with app details..."
if [ -f "$STRINGS_FILE" ]; then
    # Backup strings.xml
    cp "$STRINGS_FILE" "${STRINGS_FILE}.bak"

    # Create a temporary file
    TEMP_FILE=$(mktemp)

    # Update the strings
    sed -e "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">$APP_NAME</string>|g" \
        -e "s|<string name=\"app_description\">.*</string>|<string name=\"app_description\">$APP_DESCRIPTION</string>|g" \
        -e "s|<string name=\"app_version\">.*</string>|<string name=\"app_version\">$APP_VERSION</string>|g" \
        -e "s|<string name=\"app_version_code\">.*</string>|<string name=\"app_version_code\">$VERSION_CODE</string>|g" \
        -e "s|<string name=\"app_copyright\">.*</string>|<string name=\"app_copyright\">$APP_COPYRIGHT</string>|g" \
        "$STRINGS_FILE" > "$TEMP_FILE"

    # Replace original file with processed file
    mv "$TEMP_FILE" "$STRINGS_FILE"

    echo "✅ strings.xml has been updated."
else
    echo "❌ Error: strings.xml not found at $STRINGS_FILE"
    exit 1
fi

# Final completion message with emoji
echo "🎉 Configuration update completed successfully. ✅"
