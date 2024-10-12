// lib/src/update_config.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_package_renamer/src/change_app_package_name.dart';

class UpdateConfig {
  final String configPath;

  UpdateConfig(this.configPath);

  Future<void> run() async {
    // Check if config.json exists
    final configFile = File(configPath);
    if (!await configFile.exists()) {
      print('❌ ERROR: $configPath not found!');
      exit(1);
    }

    // Read config.json
    final configContents = await configFile.readAsString();
    final config = parseConfig(configContents);

    // Validate config fields
    if (!validateConfig(config)) {
      print(
          '❌ ERROR: Invalid config.json. Please ensure all required fields are present.');
      exit(1);
    }

    // Extract fields
    final appName = config['appName'] as String;
    final appDescription = config['appDescription'] as String;
    final appVersion = config['appVersion'] as String;
    final androidPackage = config['androidPackage'] as String;
    final iosBundleId = config['iosBundleId'] as String;
    final appCopyright = config['appCopyright'] as String;

    print('🚀 Starting configuration update...');
    print('📦 App Name: $appName');
    print('📝 App Description: $appDescription');
    print('🔖 App Version: $appVersion');
    print('📱 Android Package: $androidPackage');
    print('🍏 iOS Bundle ID: $iosBundleId');
    print('----------------------------------------');

    // Rename Android and iOS packages
    await ChangeAppPackageName.start([androidPackage, '--android']);
    await ChangeAppPackageName.start([iosBundleId, '--ios']);

    // Update pubspec.yaml
    await updatePubspec(appName, appDescription, appVersion);

    // Update Android build.gradle
    await updateAndroidBuildGradle(appVersion);

    // Update iOS Info.plist
    await updateIosInfoPlist(appVersion);

    // Update strings.xml
    await updateAndroidStringsXml(appDescription, appCopyright);

    print('✅ Configuration update completed successfully.');
  }

  Map<String, dynamic> parseConfig(String contents) {
    try {
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      print('❌ ERROR: Failed to parse config.json - $e');
      exit(1);
    }
  }

  bool validateConfig(Map<String, dynamic> config) {
    return config.containsKey('appName') &&
        config.containsKey('appDescription') &&
        config.containsKey('appVersion') &&
        config.containsKey('androidPackage') &&
        config.containsKey('iosBundleId') &&
        config.containsKey('appCopyright');
  }

  Future<void> updatePubspec(
      String appName, String appDescription, String appVersion) async {
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      print('Warning: pubspec.yaml not found.');
      return;
    }

    final contents = await pubspecFile.readAsString();
    final lines = contents.split('\n');
    final updatedLines = lines.map((line) {
      if (line.startsWith('name: ')) {
        return 'name: ${appName.toLowerCase()}';
      } else if (line.startsWith('description: ')) {
        return 'description: "$appDescription"';
      } else if (line.startsWith('version: ')) {
        return 'version: $appVersion';
      } else {
        return line;
      }
    }).toList();

    await pubspecFile.writeAsString(updatedLines.join('\n'));
    print('pubspec.yaml updated.');
  }

  Future<void> updateAndroidBuildGradle(String appVersion) async {
    final buildGradleFile = File('android/app/build.gradle');
    if (!await buildGradleFile.exists()) {
      print('Warning: android/app/build.gradle not found.');
      return;
    }

    final versionName = appVersion.split('+').first;
    final versionCode = appVersion.split('+').last;

    final contents = await buildGradleFile.readAsString();
    final updatedContents = contents
        .replaceAll(RegExp(r'versionCode\s+\d+'), 'versionCode $versionCode')
        .replaceAll(
            RegExp(r'versionName\s+".+"'), 'versionName "$versionName"');

    await buildGradleFile.writeAsString(updatedContents);
    print('android/app/build.gradle updated with version details.');
  }

  Future<void> updateIosInfoPlist(String appVersion) async {
    final infoPlistFile = File('ios/Runner/Info.plist');
    if (!await infoPlistFile.exists()) {
      print('Warning: ios/Runner/Info.plist not found.');
      return;
    }

    final versionName = appVersion.split('+').first;
    final versionCode = appVersion.split('+').last;

    // Update CFBundleShortVersionString and CFBundleVersion
    // This requires parsing the plist, which can be done using PlistBuddy or a Dart plist parser.
    // For simplicity, we'll use PlistBuddy via Process.

    final process = await Process.run('PlistBuddy', [
      '-c',
      'Set :CFBundleShortVersionString $versionName',
      '-c',
      'Set :CFBundleVersion $versionCode',
      infoPlistFile.path
    ]);

    if (process.exitCode == 0) {
      print('ios/Runner/Info.plist updated with version details.');
    } else {
      print(
          'ERROR: Failed to update ios/Runner/Info.plist - ${process.stderr}');
    }
  }

  Future<void> updateAndroidStringsXml(
      String appDescription, String appCopyright) async {
    final stringsXmlFile = File('android/app/src/main/res/values/strings.xml');
    if (!await stringsXmlFile.exists()) {
      print('Warning: android/app/src/main/res/values/strings.xml not found.');
      return;
    }

    String contents = await stringsXmlFile.readAsString();

    // Update app_description
    contents = contents.replaceAllMapped(
      RegExp(r'<string name="app_description">.*?</string>'),
      (match) => '<string name="app_description">$appDescription</string>',
    );

    // Update or add copyright
    if (RegExp(r'<string name="app_copyright">.*?</string>')
        .hasMatch(contents)) {
      contents = contents.replaceAllMapped(
        RegExp(r'<string name="app_copyright">.*?</string>'),
        (match) => '<string name="app_copyright">$appCopyright</string>',
      );
    } else {
      // Insert before closing </resources>
      contents = contents.replaceAll(RegExp(r'</resources>'),
          '    <string name="app_description">$appDescription</string>\n    <string name="app_copyright">$appCopyright</string>\n</resources>');
    }

    await stringsXmlFile.writeAsString(contents);
    print(
        'android/app/src/main/res/values/strings.xml updated with app details.');
  }
}
