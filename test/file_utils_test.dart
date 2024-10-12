// test/file_utils_test.dart

import 'dart:io';

import 'package:flutter_package_renamer/src/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('File Utils Tests', () {
    test('Read existing file', () async {
      // Create a temporary file
      final tempFile = File('temp_test.txt');
      await tempFile.writeAsString('Hello, World!');

      final content = await readFileAsString('temp_test.txt');
      expect(content, 'Hello, World!');

      // Clean up
      await tempFile.delete();
    });

    test('Read non-existing file', () async {
      final content = await readFileAsString('non_existing_file.txt');
      expect(content, isNull);
    });

    test('Replace in file', () async {
      final tempFile = File('temp_replace.txt');
      await tempFile.writeAsString('Hello, World!');

      await replaceInFile('temp_replace.txt', 'World', 'Dart');
      final content = await tempFile.readAsString();
      expect(content, 'Hello, Dart!');

      // Clean up
      await tempFile.delete();
    });

    test('Replace in file with regex', () async {
      final tempFile = File('temp_regex_replace.txt');
      await tempFile.writeAsString('versionCode 1');

      await replaceInFileRegex(
          'temp_regex_replace.txt', r'versionCode \d+', 'versionCode 2');
      final content = await tempFile.readAsString();
      expect(content, 'versionCode 2');

      // Clean up
      await tempFile.delete();
    });
  });
}
