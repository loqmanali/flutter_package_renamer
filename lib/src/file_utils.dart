// file_utils.dart

import 'dart:async';
import 'dart:io';

/// Reads the content of a file as a string.
Future<String?> readFileAsString(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      print('📄 File not found: $path');
      return null;
    }
  } catch (e) {
    print('❌ Error reading file $path: $e');
    return null;
  }
}

/// Replaces occurrences in a file using a regex pattern.
Future<void> replaceInFileRegex(
    String path, String pattern, String replacement) async {
  try {
    final file = File(path);
    if (!await file.exists()) {
      print('📄 File not found: $path');
      return;
    }

    String contents = await file.readAsString();
    final regExp = RegExp(pattern, multiLine: true);
    String updatedContents = contents.replaceAll(regExp, replacement);

    await file.writeAsString(updatedContents);
    print('🔄 Replaced pattern in $path');
  } catch (e) {
    print('❌ Error replacing pattern in $path: $e');
  }
}

/// Replaces oldValue with newValue in a file.
Future<void> replaceInFile(
    String path, String oldValue, String newValue) async {
  try {
    final file = File(path);
    if (!await file.exists()) {
      print('📄 File not found: $path');
      return;
    }

    String contents = await file.readAsString();
    String updatedContents = contents.replaceAll(oldValue, newValue);

    await file.writeAsString(updatedContents);
    print('🔄 Replaced "$oldValue" with "$newValue" in $path');
  } catch (e) {
    print('❌ Error replacing "$oldValue" with "$newValue" in $path: $e');
  }
}

/// Writes contents to a file from a string.
Future<void> writeFileFromString(String path, String contents) async {
  try {
    final file = File(path);
    await file.writeAsString(contents);
    print('📝 Written contents to $path');
  } catch (e) {
    print('❌ Error writing to file $path: $e');
  }
}

/// Lists contents of a directory recursively.
Future<List<FileSystemEntity>> dirContents(Directory dir) async {
  if (!await dir.exists()) return [];
  try {
    return await dir.list(recursive: true).toList();
  } catch (e) {
    print('❌ Error listing directory ${dir.path}: $e');
    return [];
  }
}
