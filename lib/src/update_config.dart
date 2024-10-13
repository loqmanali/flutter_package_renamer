// lib/src/update_config.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_package_renamer/src/change_app_package_name.dart';
import 'package:flutter_package_renamer/src/file_utils.dart';

class UpdateConfig {
  final String configPath;
  final String projectRoot;

  UpdateConfig({required this.configPath, required this.projectRoot});

  Future<void> run() async {
    // Check if config.json exists
    final configFile = File(configPath);
    if (!await configFile.exists()) {
      print('ERROR: $configPath not found!');
      exit(1);
    }

    // Read config.json
    final configContents = await configFile.readAsString();
    final config = _parseConfig(configContents);

    // Validate config fields
    if (!_validateConfig(config)) {
      print(
          'ERROR: Invalid config.json. Please ensure all required fields are present.');
      exit(1);
    }

    // Extract fields
    final appName = config['appName'] as String;
    final appDescription = config['appDescription'] as String;
    final appVersion = config['appVersion'] as String;
    final androidPackage = config['androidPackage'] as String;
    final iosBundleId = config['iosBundleId'] as String;
    final appCopyright = config['appCopyright'] as String;

    print('Starting configuration update...');
    print('App Name: $appName');
    print('App Description: $appDescription');
    print('App Version: $appVersion');
    print('Android Package: $androidPackage');
    print('iOS Bundle ID: $iosBundleId');
    print('App Copyright: $appCopyright');
    print('----------------------------------------');

    // Rename Android and iOS packages
    await ChangeAppPackageName.start([androidPackage, '--both'], projectRoot);
    await ChangeAppPackageName.start([iosBundleId, '--both'], projectRoot);

    // Update pubspec.yaml
    await _updatePubspec(appName, appDescription, appVersion);

    // Update Android build.gradle
    await _updateAndroidBuildGradle(appVersion);

    // Update iOS Info.plist
    await _updateIosInfoPlist(appVersion, iosBundleId);

    // Update Android strings.xml
    await _updateAndroidStringsXml(appDescription, appCopyright, appName);

    print('Configuration update completed successfully.');
  }

  Map<String, dynamic> _parseConfig(String contents) {
    try {
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      print('ERROR: Failed to parse config.json - $e');
      exit(1);
    }
  }

  bool _validateConfig(Map<String, dynamic> config) {
    return config.containsKey('appName') &&
        config.containsKey('appDescription') &&
        config.containsKey('appVersion') &&
        config.containsKey('androidPackage') &&
        config.containsKey('iosBundleId') &&
        config.containsKey('appCopyright');
  }

  Future<void> _updatePubspec(
      String appName, String appDescription, String appVersion) async {
    final pubspecPath = '$projectRoot/pubspec.yaml';
    final pubspecFile = File(pubspecPath);
    if (!await pubspecFile.exists()) {
      print('Warning: pubspec.yaml not found.');
      return;
    }

    String? contents = await readFileAsString(pubspecPath);
    if (contents == null) return;

    // Replace name
    contents = contents.replaceAllMapped(
      RegExp(r'^name:\s+.*$', multiLine: true),
      (match) => 'name: ${appName.toLowerCase()}',
    );

    // Replace description
    contents = contents.replaceAllMapped(
      RegExp(r'^description:\s+.*$', multiLine: true),
      (match) => 'description: "$appDescription"',
    );

    // Replace version
    contents = contents.replaceAllMapped(
      RegExp(r'^version:\s+.*$', multiLine: true),
      (match) => 'version: $appVersion',
    );

    await writeFileAsString(pubspecPath, contents);
    print('pubspec.yaml updated.');
  }

  Future<void> _updateAndroidBuildGradle(String appVersion) async {
    final buildGradlePath = '$projectRoot/android/app/build.gradle';
    final buildGradleFile = File(buildGradlePath);
    if (!await buildGradleFile.exists()) {
      print('Warning: android/app/build.gradle not found.');
      return;
    }

    final versionName = appVersion.split('+').first;
    final versionCode = appVersion.split('+').last;

    String? contents = await readFileAsString(buildGradlePath);
    if (contents == null) return;

    // Update versionCode
    contents = contents.replaceAllMapped(
      RegExp(r'versionCode\s+\d+'),
      (match) => 'versionCode $versionCode',
    );

    // Update versionName
    contents = contents.replaceAllMapped(
      RegExp(r'versionName\s+".+"'),
      (match) => 'versionName "$versionName"',
    );

    await writeFileAsString(buildGradlePath, contents);
    print('android/app/build.gradle updated with version details.');
  }

  Future<void> _updateIosInfoPlist(
      String appVersion, String iosBundleId) async {
    final infoPlistPath = '$projectRoot/ios/Runner/Info.plist';
    final infoPlistFile = File(infoPlistPath);
    if (!await infoPlistFile.exists()) {
      print('Warning: ios/Runner/Info.plist not found.');
      return;
    }

    String? contents = await readFileAsString(infoPlistPath);
    if (contents == null) return;

    final versionName = appVersion.split('+').first;
    final versionCode = appVersion.split('+').last;

    // Update CFBundleShortVersionString
    contents = contents.replaceAllMapped(
      RegExp(
          r'<key>CFBundleShortVersionString<\/key>\s*<string>[^<]+<\/string>'),
      (match) =>
          '<key>CFBundleShortVersionString</key>\n\t<string>$versionName</string>',
    );

    // Update CFBundleVersion
    contents = contents.replaceAllMapped(
      RegExp(r'<key>CFBundleVersion<\/key>\s*<string>[^<]+<\/string>'),
      (match) => '<key>CFBundleVersion</key>\n\t<string>$versionCode</string>',
    );

    // Update CFBundleIdentifier
    contents = contents.replaceAllMapped(
      RegExp(r'<key>CFBundleIdentifier<\/key>\s*<string>[^<]+<\/string>'),
      (match) =>
          '<key>CFBundleIdentifier</key>\n\t<string>$iosBundleId</string>',
    );

    await writeFileAsString(infoPlistPath, contents);
    print('ios/Runner/Info.plist updated with version details.');
  }

  Future<void> _updateAndroidStringsXml(
      String appDescription, String copyright, String appName) async {
    final stringsXmlPath =
        '$projectRoot/android/app/src/main/res/values/strings.xml';
    final stringsXmlFile = File(stringsXmlPath);
    if (!await stringsXmlFile.exists()) {
      print('Warning: android/app/src/main/res/values/strings.xml not found.');
      return;
    }

    String? contents = await readFileAsString(stringsXmlPath);
    if (contents == null) return;

    // Update app_description
    contents = contents.replaceAllMapped(
      RegExp(r'<string name="app_description">.*?</string>'),
      (match) => '<string name="app_description">$appDescription</string>',
    );

    // Update app_name
    contents = contents.replaceAllMapped(
      RegExp(r'<string name="app_name">.*?</string>'),
      (match) => '<string name="app_name">${_extractAppName(appName)}</string>',
    );

    // Update or add copyright
    if (RegExp(r'<string name="app_copyright">.*?</string>')
        .hasMatch(contents)) {
      contents = contents.replaceAllMapped(
        RegExp(r'<string name="app_copyright">.*?</string>'),
        (match) => '<string name="app_copyright">$copyright</string>',
      );
    } else {
      // Insert before closing </resources>
      contents = contents.replaceAll(RegExp(r'</resources>'),
          '    <string name="app_description">$appDescription</string>\n    <string name="app_copyright">$copyright</string>\n</resources>');
    }

    await writeFileAsString(stringsXmlPath, contents);
    print(
        'android/app/src/main/res/values/strings.xml updated with app details.');
  }

  // Update the method signature to accept a packageName parameter
  String _extractAppName(String packageName) {
    // Return the last segment of the package name
    return packageName.split('.').last;
  }
}
