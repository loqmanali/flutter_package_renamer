// change_app_package_name.dart

import './android_rename_steps.dart';
import './ios_rename_steps.dart';

class ChangeAppPackageName {
  static Future<void> startBoth(
      String androidPackage, String iosPackage) async {
    print('🔄 Renaming package for both Android and iOS.');
    await AndroidRenameSteps(androidPackage).process();
    await IosRenameSteps(iosPackage).process();
  }

  static Future<void> startAndroid(String androidPackage) async {
    print('🔄 Renaming package for Android only.');
    await AndroidRenameSteps(androidPackage).process();
  }

  static Future<void> startIOS(String iosPackage) async {
    print('🔄 Renaming package for iOS only.');
    await IosRenameSteps(iosPackage).process();
  }
}
