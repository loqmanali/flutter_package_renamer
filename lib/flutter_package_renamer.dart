/// Support for doing something awesome.
///
/// More dartdocs go here.
library flutter_package_renamer;

import 'dart:io'; // Add this import for File and exit

import 'package:args/args.dart';

import 'src/change.dart' as script;

// import 'bin/script.dart' as script;

export 'src/android_rename_steps.dart';
export 'src/change_app_package_name.dart';
export 'src/file_utils.dart';
export 'src/ios_rename_steps.dart';
export 'src/update_config.dart' show UpdateConfig;

/// Runs the rename.dart script with given arguments.

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('update-config', help: 'Path to the config file');

  final results = parser.parse(arguments);

  if (results['update-config'] != null) {
    final configPath = results['update-config'];
    if (!await File(configPath).exists()) {
      print('Error: Config file not found at $configPath');
      exit(1);
    }
    await script.main([configPath]);
  } else {
    print(
        '❌ Usage: dart run flutter_package_renamer:rename --update-config <path_to_config.json>');
    exit(1);
  }
}
