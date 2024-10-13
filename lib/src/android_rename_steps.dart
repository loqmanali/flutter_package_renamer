// lib/src/android_rename_steps.dart

import 'dart:async';
import 'dart:io';

import 'file_utils.dart';

class AndroidRenameSteps {
  final String newPackageName;
  final String projectRoot;
  String? oldPackageName;

  AndroidRenameSteps(this.newPackageName, this.projectRoot);

  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_MANIFEST_MAIN =
      'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG =
      'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE =
      'android/app/src/profile/AndroidManifest.xml';
  static const String PATH_STRINGS_XML =
      'android/app/src/main/res/values/strings.xml';

  static const String PATH_ACTIVITY = 'android/app/src/main/';

  Future<void> process() async {
    print("Running for Android");
    final buildGradlePath = '$projectRoot/$PATH_BUILD_GRADLE';
    if (!await File(buildGradlePath).exists()) {
      print(
          'ERROR:: build.gradle file not found at $buildGradlePath. Ensure you are in the correct project directory.');
      return;
    }
    String? contents = await readFileAsString(buildGradlePath);

    var reg = RegExp(r'applicationId\s*=\s*"([^"]+)"', caseSensitive: true);
    var match = reg.firstMatch(contents!);
    if (match == null) {
      print(
          'ERROR:: applicationId not found in build.gradle file. Please check the file or file an issue on GitHub.');
      return;
    }
    var name = match.group(1);
    oldPackageName = name;

    print("Old Package Name: $oldPackageName");

    print('Updating build.gradle File');
    await _replace(buildGradlePath);

    // Update AndroidManifest.xml files
    await _updateAndroidManifest('$projectRoot/$PATH_MANIFEST_MAIN');
    await _updateAndroidManifest('$projectRoot/$PATH_MANIFEST_DEBUG');
    await _updateAndroidManifest('$projectRoot/$PATH_MANIFEST_PROFILE');

    // Update strings.xml with app description
    await _updateStringsXml();

    // Update MainActivity
    await _updateMainActivity();

    print('Finished updating Android package name');
  }

  Future<void> _updateAndroidManifest(String path) async {
    var newPackageDeclaration = 'package="$newPackageName">';
    var packageRegex = RegExp(r'package="[^"]+">', caseSensitive: true);

    print('Updating Manifest file at $path');
    await replaceInFileRegex(path, packageRegex, newPackageDeclaration);
  }

  Future<void> _updateStringsXml() async {
    print('Updating strings.xml with app details');
    final stringsXmlPath = '$projectRoot/$PATH_STRINGS_XML';
    if (await File(stringsXmlPath).exists()) {
      // Update app_description
      var appDescriptionRegex =
          RegExp(r'<string name="app_description">.*?</string>');
      var appDescriptionReplacement =
          '<string name="app_description">New App Description</string>'; // Replace accordingly

      // Here, you should pass appDescription if needed. For now, assuming it's handled elsewhere.

      // Update app_name
      var appNameRegex = RegExp(r'<string name="app_name">.*?</string>');
      var appNameReplacement =
          '<string name="app_name">${_extractAppName()}</string>'; // Replace accordingly

      // Similarly, you can update other strings as needed

      String contents = await readFileAsString(stringsXmlPath) ?? '';
      contents = contents.replaceAllMapped(
          appNameRegex, (match) => appNameReplacement);
      // Similarly, replace app_description if necessary

      await writeFileAsString(stringsXmlPath, contents);
      print('strings.xml updated.');
    } else {
      print('Warning: $stringsXmlPath not found.');
    }
  }

  String _extractAppName() {
    // Implement logic to extract the new app name from config or another source
    // For simplicity, returning the new package name as app name
    return newPackageName.split('.').last;
  }

  Future<void> _replace(String path) async {
    await replaceInFile(path, oldPackageName!, newPackageName);
  }

  Future<void> _updateMainActivity() async {
    final javaPath = '$projectRoot/$PATH_ACTIVITY/java/';
    final kotlinPath = '$projectRoot/$PATH_ACTIVITY/kotlin/';

    // Update Java MainActivity
    await _updateMainActivityInDirectory(javaPath, 'java');

    // Update Kotlin MainActivity
    await _updateMainActivityInDirectory(kotlinPath, 'kt');
  }

  Future<void> _updateMainActivityInDirectory(
      String dirPath, String extension) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      print('Warning: $dirPath does not exist.');
      return;
    }

    final mainActivityFile = await _findMainActivity(directory, extension);
    if (mainActivityFile == null) {
      print('Warning: MainActivity.$extension not found in $dirPath.');
      return;
    }

    // Update package declaration
    String contents = await mainActivityFile.readAsString();
    contents = contents.replaceAll(
        RegExp(r'^package\s+[\w.]+', multiLine: true),
        'package $newPackageName');
    await mainActivityFile.writeAsString(contents);
    print('Updated package declaration in ${mainActivityFile.path}');

    // Move MainActivity to new package directory
    final newPackagePath = newPackageName.replaceAll('.', '/');
    final newDirPath = '$projectRoot/$PATH_ACTIVITY$extension/$newPackagePath';
    await Directory(newDirPath).create(recursive: true);

    final newFilePath = '$newDirPath/MainActivity.$extension';
    await mainActivityFile.rename(newFilePath);
    print('Moved MainActivity to $newFilePath');

    // Delete old directories if empty
    await _deleteEmptyDirectories(directory);
  }

  Future<File?> _findMainActivity(Directory dir, String extension) async {
    try {
      final files = await dir.list(recursive: true).toList();
      for (var file in files) {
        if (file is File && file.path.endsWith('MainActivity.$extension')) {
          return file;
        }
      }
    } catch (e) {
      print('Error searching for MainActivity.$extension: $e');
    }
    return null;
  }

  Future<void> _deleteEmptyDirectories(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      if (entities.isEmpty) {
        await dir.delete();
        print('Deleted empty directory: ${dir.path}');
      }
    } catch (e) {
      print('Error deleting directory ${dir.path}: $e');
    }
  }
}
