import 'package:flutter_package_renamer/flutter_package_renamer.dart';

void main() async {
  final updateConfig = UpdateConfig('example/config.json');
  await updateConfig.run();
}
