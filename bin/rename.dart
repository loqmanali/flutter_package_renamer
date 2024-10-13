#!/usr/bin/env dart
// bin/rename.dart

import 'dart:io';

import 'package:flutter_package_renamer/src/change_app_package_name.dart';
import 'package:flutter_package_renamer/src/update_config.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('❌ Usage: rename <new_package_name> [--android|--ios|--both]');
    print('   or: rename --update-config <path_to_config.json>');
    exit(0);
  }

  if (arguments.length == 1 && arguments[0] == '--update-config') {
    print('❌ Usage: rename --update-config <path_to_config.json>');
    exit(0);
  }

  if (arguments[0] == '--update-config') {
    final configPath = arguments.length > 1 ? arguments[1] : 'config.json';
    final updater = UpdateConfig(configPath: configPath, projectRoot: '.');
    await updater.run();
    exit(0);
  }

  if (arguments.length == 1) {
    // Rename both platforms
    final newPackageName = arguments[0];
    await ChangeAppPackageName.startBoth(newPackageName, newPackageName);
    exit(0);
  }

  if (arguments.length == 2) {
    // Rename specific platform
    final newPackageName = arguments[0];
    final platformFlag = arguments[1].toLowerCase();

    if (platformFlag == '--android') {
      await ChangeAppPackageName.startAndroid(newPackageName);
    } else if (platformFlag == '--ios') {
      await ChangeAppPackageName.startIOS(newPackageName);
    } else if (platformFlag == '--both') {
      await ChangeAppPackageName.startBoth(newPackageName, newPackageName);
    } else {
      print('❌ Invalid platform flag. Use "--android", "--ios", or "--both".');
      exit(1);
    }
    exit(0);
  }

  print('❌ Invalid arguments.');
  print(' Usage: rename <new_package_name> [--android|--ios|--both]');
  print('   or: rename --update-config <path_to_config.json>');
  exit(1);
}
