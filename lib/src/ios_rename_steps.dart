// lib/src/ios_rename_steps.dart

import 'dart:async';
import 'dart:io';

import 'file_utils.dart';

class IosRenameSteps {
  final String newBundleId;
  final String projectRoot;
  String? oldBundleId;

  IosRenameSteps(this.newBundleId, this.projectRoot);

  static const String PATH_PROJECT_FILE =
      'ios/Runner.xcodeproj/project.pbxproj';
  static const String PATH_INFO_PLIST = 'ios/Runner/Info.plist';

  Future<void> process() async {
    print("Running for iOS");
    final projectFilePath = '$projectRoot/$PATH_PROJECT_FILE';
    if (!await File(projectFilePath).exists()) {
      print(
          'ERROR:: project.pbxproj file not found at $projectFilePath. Ensure you are in the correct project directory.');
      return;
    }
    String? contents = await readFileAsString(projectFilePath);

    var reg = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);',
        caseSensitive: true);
    var match = reg.firstMatch(contents!);
    if (match == null) {
      print(
          'ERROR:: Bundle Identifier not found in project.pbxproj file. Please check the file or file an issue on GitHub.');
      return;
    }
    var name = match.group(1);
    oldBundleId = name;

    print("Old Bundle Identifier: $oldBundleId");

    print('Updating project.pbxproj File');
    await _replace(projectFilePath);

    // Update Info.plist
    await _updateInfoPlist();

    print('Finished updating iOS bundle identifier');
  }

  Future<void> _replace(String path) async {
    final pattern = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;');
    final replacement = 'PRODUCT_BUNDLE_IDENTIFIER = $newBundleId;';
    await replaceInFileRegex(path, pattern, replacement);
  }

  Future<void> _updateInfoPlist() async {
    print('Updating Info.plist with new bundle identifier');
    final infoPlistPath = '$projectRoot/$PATH_INFO_PLIST';
    final infoPlistFile = File(infoPlistPath);
    if (!await infoPlistFile.exists()) {
      print('Warning: $infoPlistPath not found.');
      return;
    }

    String? contents = await readFileAsString(infoPlistPath);
    if (contents == null) return;

    // Update CFBundleIdentifier
    contents = contents.replaceAllMapped(
      RegExp(r'<key>CFBundleIdentifier<\/key>\s*<string>[^<]+<\/string>'),
      (match) =>
          '<key>CFBundleIdentifier</key>\n\t<string>$newBundleId</string>',
    );

    // Optionally, update other keys like CFBundleDisplayName if needed
    // Example:
    // contents = contents.replaceAllMapped(
    //   RegExp(r'<key>CFBundleDisplayName<\/key>\s*<string>[^<]+<\/string>'),
    //   (match) => '<key>CFBundleDisplayName</key>\n\t<string>New App Name</string>',
    // );

    await writeFileAsString(infoPlistPath, contents);
    print('Info.plist updated with new bundle identifier.');
  }
}
