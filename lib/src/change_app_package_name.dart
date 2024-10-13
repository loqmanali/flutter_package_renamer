// lib/src/change_app_package_name.dart

import 'android_rename_steps.dart';
import 'ios_rename_steps.dart';

class ChangeAppPackageName {
  static Future<void> start(List<String> arguments, String projectRoot) async {
    if (arguments.isEmpty) {
      print('New package name is missing. Please provide a package name.');
      return;
    }

    if (arguments.length == 1) {
      // Rename both platforms
      final newPackageName = arguments[0];
      await _renameBoth(newPackageName, projectRoot);
    } else if (arguments.length == 2) {
      // Rename specific platform
      final newPackageName = arguments[0];
      final platform = arguments[1].toLowerCase();
      if (platform == '--android') {
        print('Renaming package for Android only.');
        await AndroidRenameSteps(newPackageName, projectRoot).process();
      } else if (platform == '--ios') {
        print('Renaming bundle identifier for iOS only.');
        await IosRenameSteps(newPackageName, projectRoot).process();
      } else if (platform == '--both') {
        await _renameBoth(newPackageName, projectRoot);
      } else {
        print('Invalid platform flag. Use "--android", "--ios", or "--both".');
      }
    } else {
      print('Too many arguments. Use:');
      print('  rename <new_package_name> [--android|--ios|--both]');
    }
  }

  static Future<void> _renameBoth(
      String newPackageName, String projectRoot) async {
    await AndroidRenameSteps(newPackageName, projectRoot).process();
    await IosRenameSteps(newPackageName, projectRoot).process();
  }
}
