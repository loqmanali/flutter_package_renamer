#!/usr/bin/env dart
// bin/rename.dart

import 'package:rename_flutter_app/src/change_app_package_name.dart';

Future<void> main(List<String> arguments) async {
  await ChangeAppPackageName.start(arguments);
}
