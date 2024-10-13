// android_rename_steps.dart

import 'dart:async';
import 'dart:io';

import './file_utils.dart';

class AndroidRenameSteps {
  final String newPackageName;
  String? oldPackageName;
  String? oldVersionName;
  String? oldVersionCode;
  String? newVersionName;
  String? newVersionCode;

  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_MANIFEST =
      'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG =
      'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE =
      'android/app/src/profile/AndroidManifest.xml';

  static const String PATH_ACTIVITY = 'android/app/src/main/';

  AndroidRenameSteps(this.newPackageName);

  Future<void> process() async {
    print("🚀 Running for Android");
    if (!await File(PATH_BUILD_GRADLE).exists()) {
      print(
          '❌ ERROR: build.gradle file not found. Check if you have the correct android directory in your project.'
          '\n\nRun "flutter create ." to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_BUILD_GRADLE);

    var reg = RegExp(r'applicationId\s*=\s*"([^"]+)"', caseSensitive: true);
    var match = reg.firstMatch(contents!);
    if (match == null) {
      print(
          '❌ ERROR:: applicationId not found in build.gradle file. Please check the file or file an issue on GitHub.');
      return;
    }
    var name = match.group(1);
    oldPackageName = name;
    oldVersionName =
        await readFileAsString('android/app/src/main/res/values/strings.xml');
    oldVersionCode = await readFileAsString('android/app/build.gradle');
    newVersionName =
        await readFileAsString('android/app/src/main/res/values/strings.xml');
    newVersionCode = await readFileAsString('android/app/build.gradle');

    print("🔍 Old Bundle Identifier: $oldPackageName");

    print("🔍 Old Version Name: $oldVersionName");
    print("🔍 Old Version Code: $oldVersionCode");

    print("📦 New Package Name: $newPackageName");
    print("📦 New Version Name: $newVersionName");
    print("📦 New Version Code: $newVersionCode");

    print('🔄 Updating build.gradle File');
    await _replace(PATH_BUILD_GRADLE);

    var mText = 'package="$newPackageName">';
    var mRegex = r'package="[^"]+">';

    print('🔄 Updating Main Manifest file');
    await replaceInFileRegex(PATH_MANIFEST, mRegex, mText);

    print('🔄 Updating Debug Manifest file');
    await replaceInFileRegex(PATH_MANIFEST_DEBUG, mRegex, mText);

    print('🔄 Updating Profile Manifest file');
    await replaceInFileRegex(PATH_MANIFEST_PROFILE, mRegex, mText);

    await updateMainActivity();
    print('✅ Finished updating Android package name');
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
    print('💻 Project is using $type');
    print('🔄 Updating MainActivity.$extension');
    await replaceInFileRegex(
        path.path, r'^(package\s+[\w.]+)', "package $newPackageName");

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newPath = '$PATH_ACTIVITY$type/$newPackagePath';

    print('🏗 Creating New Directory Structure');
    await Directory(newPath).create(recursive: true);
    await path.rename('$newPath/MainActivity.$extension');

    print('🗑 Deleting old directories');
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
          print('🗑 Deleted empty directory: ${dir.path}');
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
