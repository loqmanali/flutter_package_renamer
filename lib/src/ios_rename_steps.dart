// lib/src/ios_rename_steps.dart

import 'dart:async';
import 'dart:io';

import 'file_utils.dart';

class IosRenameSteps {
  final String newBundleId;
  String? oldBundleId;
  static const String PATH_PROJECT_FILE =
      'ios/Runner.xcodeproj/project.pbxproj';
  static const String PATH_INFO_PLIST = 'ios/Runner/Info.plist';

  IosRenameSteps(this.newBundleId);

  Future<void> process() async {
    print("🚀 Running for iOS");
    if (!await File(PATH_PROJECT_FILE).exists()) {
      print(
          '❌ ERROR:: project.pbxproj file not found. Check if you have the correct ios directory in your project.\n\nRun "flutter create ." to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_PROJECT_FILE);

    var reg = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);',
        caseSensitive: true);
    var match = reg.firstMatch(contents!);
    if (match == null) {
      print(
          '❌ ERROR:: Bundle Identifier not found in project.pbxproj file. Please check the file or file an issue on GitHub.');
      return;
    }
    var name = match.group(1);
    oldBundleId = name;

    print("🔍 Old Bundle Identifier: $oldBundleId");

    print('🔄 Updating project.pbxproj File');
    await _replace(PATH_PROJECT_FILE);

    // Update Info.plist
    await _updateInfoPlist();

    print('✅ Finished updating iOS bundle identifier');
  }

  Future<void> _replace(String path) async {
    await replaceInFileRegex(path, r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;',
        'PRODUCT_BUNDLE_IDENTIFIER = $newBundleId;');
  }

  Future<void> _updateInfoPlist() async {
    print('🔄 Updating Info.plist with new bundle identifier');
    if (await File(PATH_INFO_PLIST).exists()) {
      // Update CFBundleIdentifier
      await replaceInFileRegex(
          PATH_INFO_PLIST,
          r'<key>CFBundleIdentifier</key>\s*<string>[^<]+</string>',
          '<key>CFBundleIdentifier</key>\n\t<string>$newBundleId</string>');
      print('✅ Info.plist updated.');
    } else {
      print('⚠️ Warning: $PATH_INFO_PLIST not found.');
    }
  }
}
