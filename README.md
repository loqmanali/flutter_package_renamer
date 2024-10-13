```
# flutter_package_renamer

**A Flutter package to automate the renaming of Android packages and iOS bundle identifiers, along with updating app configurations like name, description, version, and copyright.**

![flutter_package_renamer](https://img.shields.io/pub/v/flutter_package_renamer.svg)

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Option 1: Path Dependency (Local Installation)](#option-1-path-dependency-local-installation)
  - [Option 2: Installing from Pub.dev](#option-2-installing-from-pubdev)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Running the Shell Script (`update_config.sh`)](#running-the-shell-script-update_configsh)
  - [Using the Dart CLI](#using-the-dart-cli)
- [Example](#example)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Features

- **Automated Renaming**: Seamlessly rename Android package names and iOS bundle identifiers.
- **App Configuration Updates**: Update app name, description, version, and copyright.
- **Platform-Specific Handling**: Handles both Android and iOS configurations independently or simultaneously.
- **Backup Mechanism**: Creates backup copies of modified files to prevent data loss.
- **Command-Line Interface (CLI)**: Easy-to-use CLI for executing renaming tasks.
- **Extensible**: Easily add support for additional platforms or configuration fields.

## Prerequisites

Ensure you have the following installed:

- **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Comes bundled with Flutter.
- **jq**: A lightweight and flexible command-line JSON processor.
  - **macOS**: `brew install jq`
  - **Linux (Debian/Ubuntu)**: `sudo apt-get install jq`
  - **Windows**: Install via [Chocolatey](https://chocolatey.org/packages/jq) or download from the [official site](https://stedolan.github.io/jq/download/).
- **Git**: For version control.
```

## Installation

### Option 1: Path Dependency (Local Installation)

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/flutter_package_renamer.git
   ```

2. **Add as a Path Dependency**

   In your Flutter project's `pubspec.yaml`, add the package as a path dependency.

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_package_renamer:
       path: ../flutter_package_renamer  # Adjust the path relative to your project
   ```

3. **Fetch Dependencies**

   ```bash
   flutter pub get
   ```

### Option 2: Installing from Pub.dev

1. **Add as a Dependency**

   In your Flutter project's `pubspec.yaml`, add the package under dependencies.

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_package_renamer: ^1.0.0  # Replace with the latest version
   ```

2. **Fetch Dependencies**

   ```bash
   flutter pub get
   ```

## Configuration

1. **Create a `config.json` File**

   In the root directory of your Flutter project, create a `config.json` file with the following structure:

   ```json
   {
     "appName": "MyAwesomeApp",
     "appDescription": "This is an awesome Flutter application.",
     "appVersion": "1.2.3+4",
     "androidPackage": "com.example.myawesomeapp",
     "iosBundleId": "com.example.myawesomeapp",
     "appCopyright": "© 2024 Example Company"
   }
   ```

   **Field Descriptions:**

   - **`appName`**: The display name of your app.
   - **`appDescription`**: A brief description of your app.
   - **`appVersion`**: The version of your app in the format `major.minor.patch+build` (e.g., `1.2.3+4`).
   - **`androidPackage`**: The new package name for Android (e.g., `com.example.myawesomeapp`).
   - **`iosBundleId`**: The new bundle identifier for iOS (e.g., `com.example.myawesomeapp`).
   - **`appCopyright`**: Legal information about the app's ownership.

## Usage

The `flutter_package_renamer` package provides two primary methods to perform renaming tasks:

1. **Running the Shell Script (`update_config.sh`)**
2. **Using the Dart CLI**

### Running the Shell Script (`update_config.sh`)
### Create file update_config.sh   in root project file

``` bash
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

# Check if rename.dart exists
RENAME_DART="rename.dart"
if [ ! -f "$RENAME_DART" ]; then
    error_exit "❌ Error: $RENAME_DART not found! Please ensure rename.dart exists with the necessary renaming logic."
fi

# Run the Dart script to rename Android and iOS packages
echo "🔄 Renaming Android package..."
dart run rename.dart "$ANDROID_PACKAGE" "--android"

echo "🔄 Renaming iOS bundle identifier..."
dart run rename.dart "$IOS_BUNDLE_ID" "--ios"

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

```

1. **Ensure Executable Permissions**

   Make sure the `update_config.sh` script is executable.

   ```bash
   chmod +x update_config.sh
   ```

2. **Execute the Shell Script**

   Run the script from your Flutter project's root directory.

   ```bash
   ./update_config.sh
   ```

   **What the Script Does:**

   - Reads the `config.json` file.
   - Updates the Android package name and iOS bundle identifier.
   - Updates `pubspec.yaml` with the new app name, description, and version.
   - Updates platform-specific configuration files (`build.gradle`, `AndroidManifest.xml`, `Info.plist`, etc.).
   - Handles directory restructuring for Android's `MainActivity`.
   - Creates backups of modified files (`.bak` files) before making changes.

### Using the Dart CLI

1. **Ensure Dependencies Are Installed**

   If you used a path dependency, ensure that the `flutter_package_renamer` package is included in your project's dependencies.

2. **Run the Dart CLI Command**

   Execute the Dart CLI command to perform the renaming. The CLI supports different modes:

   - **Rename Both Android and iOS**

     ```bash
     dart run flutter_package_renamer:rename <new_package_name>
     ```

     **Example:**

     ```bash
     dart run flutter_package_renamer:rename com.example.myawesomeapp
     ```

   - **Rename Specific Platform**

     - **Android Only**

       ```bash
       dart run flutter_package_renamer:rename <new_package_name> --android
       ```

       **Example:**

       ```bash
       dart run flutter_package_renamer:rename com.example.myawesomeapp --android
       ```

     - **iOS Only**

       ```bash
       dart run flutter_package_renamer:rename <new_bundle_id> --ios
       ```

       **Example:**

       ```bash
       dart run flutter_package_renamer:rename com.example.myawesomeapp --ios
       ```

   - **Run Update Config**

     This command performs all updates based on the `config.json` file.

     ```bash
     dart run flutter_package_renamer:rename --update-config
     ```

     **Optional:** Specify a custom path to `config.json`:

     ```bash
     dart run flutter_package_renamer:rename --update-config path/to/config.json
     ```

     **Note:** This approach is recommended for users who prefer using the Dart CLI over the shell script.

## Example

Assuming you have a Flutter project named `sample_app`, here's how you can use the `flutter_package_renamer` package to rename its Android package and iOS bundle identifier.

1. **Setup**

   ```bash
   cd path/to/sample_app
   ```

2. **Create `config.json`**

   ```json
   {
     "appName": "SampleApp",
     "appDescription": "A sample Flutter application.",
     "appVersion": "1.0.0+1",
     "androidPackage": "com.example.sampleapp",
     "iosBundleId": "com.example.sampleapp",
     "appCopyright": "© 2024 Example Company"
   }
   ```

3. **Run the Shell Script**

   ```bash
   ./scripts/update_config.sh
   ```

   **Or, using Dart CLI:**

   ```bash
   dart run flutter_package_renamer:rename --update-config
   ```

4. **Verify Changes**

   - **`pubspec.yaml`:**

     ```yaml
     name: sampleapp
     description: "A sample Flutter application."
     version: 1.0.0+1
     ```

   - **Android Configuration:**
     - `build.gradle`:

       ```groovy
       defaultConfig {
           applicationId "com.example.sampleapp"
           minSdkVersion 21
           targetSdkVersion 30
           versionCode 1
           versionName "1.0.0"
           // ...
       }
       ```

     - `AndroidManifest.xml`:

       ```xml
       <manifest xmlns:android="http://schemas.android.com/apk/res/android"
           package="com.example.sampleapp">
           <!-- ... -->
       </manifest>
       ```

     - `MainActivity.java` or `MainActivity.kt`:

       ```java
       package com.example.sampleapp;

       import io.flutter.embedding.android.FlutterActivity;

       public class MainActivity extends FlutterActivity {
       }
       ```

   - **iOS Configuration:**
     - `project.pbxproj`:

       ```pbxproj
       PRODUCT_BUNDLE_IDENTIFIER = com.example.sampleapp;
       ```

     - `Info.plist`:

       ```xml
       <key>CFBundleIdentifier</key>
       <string>com.example.sampleapp</string>
       ```

   - **`strings.xml`:**

     ```xml
     <resources>
         <string name="app_name">SampleApp</string>
         <string name="app_description">A sample Flutter application.</string>
         <!-- ... -->
     </resources>
     ```

5. **Run the App**

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

   Ensure that the app builds and runs correctly with the updated configurations.

## Testing

To ensure the package functions correctly, it's recommended to run automated tests and perform manual verifications.

### Automated Tests

1. **Navigate to the Package Directory**

   ```bash
   cd path/to/flutter_package_renamer
   ```

2. **Run Tests**

   ```bash
   dart test
   ```

   Ensure all tests pass without errors.

### Manual Testing

1. **Create a Sample Flutter Project**

   ```bash
   flutter create sample_app
   cd sample_app
   ```

2. **Integrate the Package**

   Add the package as a path dependency in `pubspec.yaml`.

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_package_renamer:
       path: ../flutter_package_renamer  # Adjust the path accordingly
   ```

3. **Create `config.json`**

   ```json
   {
     "appName": "SampleApp",
     "appDescription": "A sample Flutter application.",
     "appVersion": "1.0.0+1",
     "androidPackage": "com.example.sampleapp",
     "iosBundleId": "com.example.sampleapp",
     "appCopyright": "© 2024 Example Company"
   }
   ```

4. **Run the Renaming Script**

   ```bash
   cd ../flutter_package_renamer
   ./scripts/update_config.sh
   ```

   **Or, using Dart CLI:**

   ```bash
   dart run flutter_package_renamer:rename --update-config
   ```

5. **Verify Changes**

   Check that all configurations in `pubspec.yaml`, Android, and iOS files are updated correctly.

6. **Build and Run the App**

   ```bash
   cd ../sample_app
   flutter clean
   flutter pub get
   flutter run
   ```

   Ensure the app runs without issues.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please follow the steps below.

1. **Fork the Repository**

   Click the "Fork" button on the [GitHub repository](https://github.com/yourusername/flutter_package_renamer) page.

2. **Clone Your Fork**

   ```bash
   git clone https://github.com/yourusername/flutter_package_renamer.git
   ```

3. **Create a New Branch**

   ```bash
   cd flutter_package_renamer
   git checkout -b feature/your-feature-name
   ```

4. **Make Your Changes**

   Implement your feature or fix.

5. **Commit Your Changes**

   ```bash
   git add .
   git commit -m "Add feature: your feature description"
   ```

6. **Push to Your Fork**

   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**

   Navigate to your fork on GitHub and click "Compare & pull request." Provide a clear description of your changes and submit the pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Contact

For any questions or support, please contact [grahyy1@gmail.com](mailto:your.email@example.com).

---

```
