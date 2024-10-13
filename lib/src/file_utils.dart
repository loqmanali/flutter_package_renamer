// lib/src/file_utils.dart

import 'dart:io';

/// Reads the content of a file as a string.
Future<String?> readFileAsString(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      print('File not found: $path');
      return null;
    }
  } catch (e) {
    print('Error reading file $path: $e');
    return null;
  }
}

/// Writes a string to a file.
Future<void> writeFileAsString(String path, String content) async {
  try {
    final file = File(path);
    await file.writeAsString(content);
    print('Successfully wrote to $path');
  } catch (e) {
    print('Error writing to file $path: $e');
  }
}

/// Replaces a pattern in a file using regular expressions.
Future<void> replaceInFileRegex(
    String path, RegExp pattern, String replacement) async {
  try {
    String? contents = await readFileAsString(path);
    if (contents == null) return;

    String updatedContents = contents.replaceAll(pattern, replacement);
    await writeFileAsString(path, updatedContents);
    print('Replaced pattern in $path');
  } catch (e) {
    print('Error replacing pattern in $path: $e');
  }
}

/// Replaces a specific string in a file.
Future<void> replaceInFile(
    String path, String oldValue, String newValue) async {
  try {
    String? contents = await readFileAsString(path);
    if (contents == null) return;

    String updatedContents = contents.replaceAll(oldValue, newValue);
    await writeFileAsString(path, updatedContents);
    print('Replaced "$oldValue" with "$newValue" in $path');
  } catch (e) {
    print('Error replacing "$oldValue" with "$newValue" in $path: $e');
  }
}
