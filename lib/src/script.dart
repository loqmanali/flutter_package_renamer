#!/usr/bin/env dart
// update_config.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Entry point of the script.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Error: Config file path not provided');
    exit(1);
  }

  final configFilePath = args[0];

  try {
    await runUpdateConfig(configFilePath);
    print("🎉 Configuration update completed successfully. ✅");
  } catch (e) {
    print("❌ An error occurred: $e");
    exit(1);
  }
}

/// Runs the entire configuration update process.
Future<void> runUpdateConfig(String configFilePath) async {
  // Paths to necessary files
  final pubspecFilePath = 'pubspec.yaml';
  final stringsXmlPath = 'android/app/src/main/res/values/strings.xml';
  final iosInfoPlistPath = 'ios/Runner/Info.plist';
  final renameScriptPath = 'rename.dart'; // Ensure this path is correct

  // Step 1: Check if config.json exists
  final configFile = File(configFilePath);
  if (!await configFile.exists()) {
    throw '❌ Error: $configFilePath not found! Please create config.json with required fields.';
  }

  // Step 2: Read and parse config.json
  final configContent = await configFile.readAsString();
  Map<String, dynamic> config;
  try {
    config = jsonDecode(configContent);
  } catch (e) {
    throw '❌ Error: Failed to parse $configFilePath. Ensure it contains valid JSON.';
  }

  // Step 3: Validate required fields
  final requiredFields = [
    'appName',
    'appDescription',
    'appVersion',
    'androidPackage',
    'iosBundleId',
    'appCopyright'
  ];

  for (var field in requiredFields) {
    if (!config.containsKey(field) ||
        (config[field] as String).trim().isEmpty) {
      throw '❌ Error: Required field "$field" is missing or empty in $configFilePath.';
    }
  }

  // Extract fields
  final appName = config['appName'].trim();
  final appDescription = config['appDescription'].trim();
  final appVersion = config['appVersion'].trim();
  final androidPackage = config['androidPackage'].trim();
  final iosBundleId = config['iosBundleId'].trim();
  final appCopyright = config['appCopyright'].trim();

  // Step 4: Print starting messages with emojis
  print("🚀 Starting configuration update...");
  print("App Name: $appName 📱");
  print("App Description: $appDescription 📝");
  print("App Version: $appVersion 🔢");
  print("Android Package: $androidPackage 🤖");
  print("iOS Bundle ID: $iosBundleId 🍏");
  print("Copyright: $appCopyright ©️");
  print("----------------------------------------");

  // Step 5: Check if rename.dart exists
  final renameScript = File(renameScriptPath);
  if (!await renameScript.exists()) {
    throw '❌ Error: $renameScriptPath not found! Please ensure rename.dart exists with the necessary renaming logic.';
  }

  // Step 6: Run the rename.dart script for Android and iOS
  print("🔄 Renaming Android package...");
  final androidExitCode =
      await runRenameScript(renameScriptPath, [androidPackage, '--android']);
  if (androidExitCode != 0) {
    throw '❌ Error: Failed to rename Android package.';
  }

  print("🔄 Renaming iOS bundle identifier...");
  final iosExitCode =
      await runRenameScript(renameScriptPath, [iosBundleId, '--ios']);
  if (iosExitCode != 0) {
    throw '❌ Error: Failed to rename iOS bundle identifier.';
  }

  // Step 7: Update pubspec.yaml
  print("📄 Updating pubspec.yaml with app details...");
  await updatePubspec(pubspecFilePath, appName, appDescription, appVersion);
  print("✅ pubspec.yaml updated.");

  // Step 8: Extract versionCode and versionName from appVersion
  final versionDetails = extractVersionDetails(appVersion);
  final versionName = versionDetails['versionName']!;
  final versionCode = versionDetails['versionCode']!;
  print("🔍 Extracted Version Name: $versionName");
  print("🔍 Extracted Version Code: $versionCode");

  // Step 9: Update iOS Info.plist
  print("🛠️ Updating iOS Info.plist with version details...");
  await updateIosInfoPlist(iosInfoPlistPath, versionName, versionCode);
  print("✅ iOS Info.plist updated with version details.");

  // Step 10: Update Android strings.xml
  print("📜 Updating Android strings.xml with app details...");
  await updateAndroidStringsXml(stringsXmlPath, appName, appDescription,
      appVersion, versionCode, appCopyright);
  print("✅ strings.xml has been updated.");
}

/// Runs the rename.dart script with given arguments.
/// Returns the exit code of the process.
Future<int> runRenameScript(String scriptPath, List<String> arguments) async {
  final process =
      await Process.start('dart', ['run', scriptPath, ...arguments]);

  // Capture stdout
  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  // Capture stderr
  process.stderr.transform(utf8.decoder).listen((data) {
    print(data);
  });

  final exitCode = await process.exitCode;
  return exitCode;
}

/// Updates pubspec.yaml with the provided app details.
Future<void> updatePubspec(String pubspecPath, String appName,
    String appDescription, String appVersion) async {
  final pubspecFile = File(pubspecPath);
  if (!await pubspecFile.exists()) {
    print("⚠️ Warning: $pubspecPath not found.");
    return;
  }

  String contents = await pubspecFile.readAsString();

  // Create a backup
  await pubspecFile.copy('$pubspecPath.bak');

  // Update name, description, and version using regex
  contents = contents.replaceAllMapped(
    RegExp(r'^name:\s+.*$', multiLine: true),
    (match) => 'name: ${appName.toLowerCase()}',
  );

  contents = contents.replaceAllMapped(
    RegExp(r'^description:\s+.*$', multiLine: true),
    (match) => 'description: "$appDescription"',
  );

  contents = contents.replaceAllMapped(
    RegExp(r'^version:\s+.*$', multiLine: true),
    (match) => 'version: $appVersion',
  );

  await pubspecFile.writeAsString(contents);
}

/// Extracts versionName and versionCode from appVersion.
Map<String, String> extractVersionDetails(String appVersion) {
  if (!appVersion.contains('+')) {
    print(
        "⚠️ Warning: APP_VERSION does not contain '+'. Setting versionCode to 1.");
    return {'versionName': appVersion, 'versionCode': '1'};
  }

  final parts = appVersion.split('+');
  final versionName = parts[0];
  final versionCode = parts[1];

  if (!RegExp(r'^\d+$').hasMatch(versionCode)) {
    throw '❌ Error: versionCode extracted from APP_VERSION is not a valid integer.';
  }

  return {'versionName': versionName, 'versionCode': versionCode};
}

/// Updates iOS Info.plist with versionName and versionCode.
Future<void> updateIosInfoPlist(
    String plistPath, String versionName, String versionCode) async {
  final plistFile = File(plistPath);
  if (!await plistFile.exists()) {
    print("⚠️ Warning: $plistPath not found.");
    return;
  }

  String contents = await plistFile.readAsString();

  // Backup Info.plist
  await plistFile.copy('$plistPath.bak');

  // Update CFBundleShortVersionString
  contents = contents.replaceAllMapped(
    RegExp(r'<key>CFBundleShortVersionString</key>\s*<string>.*?</string>'),
    (match) =>
        '<key>CFBundleShortVersionString</key>\n        <string>$versionName</string>',
  );

  // Update CFBundleVersion
  contents = contents.replaceAllMapped(
    RegExp(r'<key>CFBundleVersion</key>\s*<string>.*?</string>'),
    (match) =>
        '<key>CFBundleVersion</key>\n        <string>$versionCode</string>',
  );

  await plistFile.writeAsString(contents);
}

/// Updates Android strings.xml with app details.
Future<void> updateAndroidStringsXml(
    String stringsXmlPath,
    String appName,
    String appDescription,
    String appVersion,
    String versionCode,
    String appCopyright) async {
  final stringsXmlFile = File(stringsXmlPath);
  if (!await stringsXmlFile.exists()) {
    throw '❌ Error: strings.xml not found at $stringsXmlPath';
  }

  String contents = await stringsXmlFile.readAsString();

  // Backup strings.xml
  await stringsXmlFile.copy('$stringsXmlPath.bak');

  // Update or add strings
  contents = contents.replaceAllMapped(
    RegExp(r'<string name="app_name">.*?</string>'),
    (match) => '<string name="app_name">$appName</string>',
  );

  contents = contents.replaceAllMapped(
    RegExp(r'<string name="app_description">.*?</string>'),
    (match) => '<string name="app_description">$appDescription</string>',
  );

  contents = contents.replaceAllMapped(
    RegExp(r'<string name="app_version">.*?</string>'),
    (match) => '<string name="app_version">$appVersion</string>',
  );

  contents = contents.replaceAllMapped(
    RegExp(r'<string name="app_version_code">.*?</string>'),
    (match) => '<string name="app_version_code">$versionCode</string>',
  );

  contents = contents.replaceAllMapped(
    RegExp(r'<string name="app_copyright">.*?</string>'),
    (match) => '<string name="app_copyright">$appCopyright</string>',
  );

  await stringsXmlFile.writeAsString(contents);
}

/// Placeholder functions for renaming packages.
/// Implement the actual logic as needed.

/// Renames the Android package.
Future<void> _renameAndroidPackage(String newPackageName) async {
  print("🤖 Renaming Android package to: $newPackageName");

  // Update AndroidManifest.xml
  final manifestPath = 'android/app/src/main/AndroidManifest.xml';
  await _updateFileContent(manifestPath, (content) {
    return content.replaceAll(
        RegExp(r'package="[^"]+"'), 'package="$newPackageName"');
  });

  // Update build.gradle
  final buildGradlePath = 'android/app/build.gradle';
  await _updateFileContent(buildGradlePath, (content) {
    return content.replaceAll(
        RegExp(r'applicationId "[^"]+"'), 'applicationId "$newPackageName"');
  });

  // Rename package directories
  final oldPackagePath = path.join('android', 'app', 'src', 'main', 'kotlin');
  final newPackagePath = path.joinAll([
    'android',
    'app',
    'src',
    'main',
    'kotlin',
    ...newPackageName.split('.')
  ]);
  await Directory(newPackagePath).create(recursive: true);

  final files = await Directory(oldPackagePath)
      .list(recursive: true)
      .where((entity) => entity is File)
      .cast<File>()
      .toList();

  for (var file in files) {
    final newFilePath = path.join(newPackagePath, path.basename(file.path));
    await file.rename(newFilePath);

    // Update package declaration in Kotlin files
    if (file.path.endsWith('.kt')) {
      await _updateFileContent(newFilePath, (content) {
        return content.replaceAll(
            RegExp(r'package [^\n]+'), 'package $newPackageName');
      });
    }
  }

  print("✅ Android package renamed successfully.");
}

/// Renames the iOS bundle identifier.
Future<void> _renameIosBundleId(String newBundleId) async {
  print("🍏 Renaming iOS bundle identifier to: $newBundleId");

  // Update Info.plist
  final infoPlistPath = 'ios/Runner/Info.plist';
  await _updateFileContent(infoPlistPath, (content) {
    return content.replaceAll(
        RegExp(r'<key>CFBundleIdentifier</key>\s*<string>[^<]+</string>'),
        '<key>CFBundleIdentifier</key>\n\t<string>$newBundleId</string>');
  });

  // Update project.pbxproj
  final projectPath = 'ios/Runner.xcodeproj/project.pbxproj';
  await _updateFileContent(projectPath, (content) {
    return content.replaceAll(RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;'),
        'PRODUCT_BUNDLE_IDENTIFIER = $newBundleId;');
  });

  print("✅ iOS bundle identifier renamed successfully.");
}

/// Helper function to update file content
Future<void> _updateFileContent(
    String filePath, String Function(String) updateFunc) async {
  final file = File(filePath);
  if (await file.exists()) {
    String content = await file.readAsString();
    content = updateFunc(content);
    await file.writeAsString(content);
  } else {
    print("⚠️ Warning: File not found: $filePath");
  }
}
