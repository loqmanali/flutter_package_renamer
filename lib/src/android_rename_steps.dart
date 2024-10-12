// lib/src/android_rename_steps.dart

import 'dart:async';
import 'dart:io';

import 'file_utils.dart';

class AndroidRenameSteps {
  final String newPackageName;
  String? oldPackageName;

  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_MANIFEST =
      'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG =
      'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE =
      'android/app/src/profile/AndroidManifest.xml';
  static const String PATH_STRINGS_XML =
      'android/app/src/main/res/values/strings.xml';

  static const String PATH_ACTIVITY = 'android/app/src/main/';

  AndroidRenameSteps(this.newPackageName);

  Future<void> process() async {
    print("🚀 Running for Android");
    if (!await File(PATH_BUILD_GRADLE).exists()) {
      print(
          '❌ ERROR:: build.gradle file not found. Check if you have the correct android directory in your project.\n\nRun "flutter create ." to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_BUILD_GRADLE);

    var reg = RegExp(r'applicationId\s*=\s*"([^"]+)"', caseSensitive: true);
    var match = reg.firstMatch(contents!);
    if (match == null) {
      print(
          'ERROR:: applicationId not found in build.gradle file. Please check the file or file an issue on GitHub.');
      return;
    }
    var name = match.group(1);
    oldPackageName = name;

    print("📦 Old Package Name: $oldPackageName");

    print('🔄 Updating build.gradle File');
    await _replace(PATH_BUILD_GRADLE);

    // Update AndroidManifest.xml files
    await _updateAndroidManifest(PATH_MANIFEST);
    await _updateAndroidManifest(PATH_MANIFEST_DEBUG);
    await _updateAndroidManifest(PATH_MANIFEST_PROFILE);

    // Update strings.xml with app name and description
    await _updateStringsXml();

    await updateMainActivity();
    print('✅ Finished updating Android package name');
  }

  Future<void> _updateAndroidManifest(String path) async {
    var mText = 'package="$newPackageName">';
    var mRegex = r'package="[^"]+">';

    print('📝 Updating Manifest file at $path');
    await replaceInFileRegex(path, mRegex, mText);
  }

  Future<void> _updateStringsXml() async {
    print('📝 Updating strings.xml with app details');
    if (await File(PATH_STRINGS_XML).exists()) {
      // Update app_name
      var appNameRegex = RegExp(r'<string name="app_name">[^<]+</string>');
      var appNameReplacement =
          '<string name="app_name">$newPackageName</string>'; // Assuming you want to set it to newPackageName

      await replaceInFileRegex(
          PATH_STRINGS_XML, appNameRegex.pattern, appNameReplacement);

      // You can add more string updates here (e.g., app_description)

      print('✅ strings.xml updated.');
    } else {
      print('⚠️ Warning: $PATH_STRINGS_XML not found.');
    }
  }

  Future<void> updateMainActivity() async {
    var path = await findMainActivity(type: 'java');
    if (path != null) {
      await processMainActivity(path, 'java');
    }

    path = await findMainActivity(type: 'kotlin');
    if (path != null) {
      await processMainActivity(path, 'kotlin');
    }
  }

  Future<void> processMainActivity(File path, String type) async {
    var extension = type == 'java' ? 'java' : 'kt';
    print('Project is using $type');
    print('🔄 Updating MainActivity.$extension');
    await replaceInFileRegex(
        path.path, r'^(package\s+[\w.]+)', "package $newPackageName");

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newPath = '$PATH_ACTIVITY$type/$newPackagePath';

    print('🔨Creating New Directory Structure at $newPath');
    await Directory(newPath).create(recursive: true);
    await path.rename('$newPath/MainActivity.$extension');

    print('🗑️ Deleting old directories');
    await deleteEmptyDirs(type);
  }

  Future<void> _replace(String path) async {
    await replaceInFile(path, oldPackageName!, newPackageName);
  }

  Future<void> deleteEmptyDirs(String type) async {
    var dirs = await dirContents(Directory('$PATH_ACTIVITY$type'));
    dirs = dirs.reversed.toList();
    for (var dir in dirs) {
      if (dir is Directory) {
        if (dir.listSync().isEmpty) {
          await dir.delete();
          print('🗑️ Deleted empty directory: ${dir.path}');
        }
      }
    }
  }

  Future<File?> findMainActivity({String type = 'java'}) async {
    var files = await dirContents(Directory('$PATH_ACTIVITY$type'));
    String extension = type == 'java' ? 'java' : 'kt';
    for (var item in files) {
      if (item is File) {
        if (item.path.endsWith('MainActivity.$extension')) {
          return item;
        }
      }
    }
    return null;
  }
}
