#!/usr/bin/env dart
// bin/rename.dart

import 'package:flutter_package_renamer/src/change_app_package_name.dart';

Future<void> main(List<String> arguments) async {
  await ChangeAppPackageName.start(arguments);
}
