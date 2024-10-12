import 'package:flutter_package_renamer/src/update_config.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final updateConfig = UpdateConfig('test/config.json');

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(updateConfig, isNotNull);
    });
  });
}
