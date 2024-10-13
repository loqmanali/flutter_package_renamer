// ios_rename_steps.dart

import 'dart:async';
import 'dart:io';

import './file_utils.dart';

class IosRenameSteps {
  final String newPackageName;
  String? oldPackageName;
  static const String PATH_PROJECT_FILE =
      'ios/Runner.xcodeproj/project.pbxproj';

  IosRenameSteps(this.newPackageName);

  Future<void> process() async {
    print("🚀 Running for iOS");
    if (!await File(PATH_PROJECT_FILE).exists()) {
      print(
          '❌ ERROR:: project.pbxproj file not found. Check if you have the correct ios directory in your project.'
          '\n\nRun "flutter create ." to regenerate missing files.');
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
    oldPackageName = name;

    print("🔍 Old Bundle Identifier: $oldPackageName");

    print('🔄 Updating project.pbxproj File');
    await _replace(PATH_PROJECT_FILE);
    print('✅ Finished updating iOS bundle identifier');

    // Update Info.plist if needed
    await updateInfoPlist();
  }

  Future<void> _replace(String path) async {
    await replaceInFileRegex(path, r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;',
        'PRODUCT_BUNDLE_IDENTIFIER = $newPackageName;');
  }

  Future<void> updateInfoPlist() async {
    String plistPath = 'ios/Runner/Info.plist';
    if (!await File(plistPath).exists()) {
      print('⚠️ Warning: Info.plist not found at $plistPath');
      return;
    }

    // Update CFBundleIdentifier
    await replaceInFileRegex(
        plistPath,
        r'<key>CFBundleIdentifier</key>\s*<string>[^<]+</string>',
        '<key>CFBundleIdentifier</key>\n\t<string>$newPackageName</string>');

    print('📝 Updated Info.plist with new bundle identifier.');
  }
}
