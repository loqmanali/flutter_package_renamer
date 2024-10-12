// #!/usr/bin/env dart
// // bin/run_update_config.dart

// import 'package:process_run/process_run.dart';
// import 'package:process_run/stdio.dart';

// Future<void> main(List<String> arguments) async {
//   // Determine the script path relative to this Dart script
//   final scriptPath = 'scripts/update_config.sh';

//   // Check if the shell script exists
//   if (!await File(scriptPath).exists()) {
//     print('❌ ERROR: Shell script not found at $scriptPath');
//     exit(1);
//   }

//   // Make sure the script is executable
//   await Process.run('chmod', ['+x', scriptPath]);

//   // Execute the shell script
//   final result = await run(
//     'bash',
//     workingDirectory: scriptPath,
//     runInShell: true,
//     stdout: stdout,
//     stderr: stderr,
//   );

//   if (result.any((r) => r.exitCode != 0)) {
//     print(
//         '❌ ERROR: Shell script exited with code ${result.map((r) => r.exitCode).join(', ')}');
//     exit(result.firstWhere((r) => r.exitCode != 0).exitCode);
//   }

//   print('✅ update_config.sh executed successfully.');
// }
