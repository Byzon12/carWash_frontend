import 'dart:io';

void main() async {
  // Files that commonly have BuildContext async issues
  final filesToFix = [
    'lib/screens/main/login screens/loginform.dart',
    'lib/screens/main/signupscreens/form.dart',
    'lib/screens/main/welcome/splash.dart',
    'lib/services/location_helper.dart',
    'lib/widgets/login_status_widget.dart',
    'lib/screens/simple_login_test.dart',
  ];

  for (final filePath in filesToFix) {
    final file = File(filePath);
    if (await file.exists()) {
      await fixBuildContextAsyncIssues(file);
    }
  }
}

Future<void> fixBuildContextAsyncIssues(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;

    // Add mounted check before BuildContext usage in async functions
    // Pattern: Navigator.of(context) or similar context usage after await
    content = content.replaceAllMapped(
      RegExp(r'(\s+)(Navigator\.of\(context\)[^;]*;)'),
      (match) {
        final indent = match.group(1)!;
        final navCall = match.group(2)!;
        return '${indent}if (mounted) {\n${indent}  $navCall\n${indent}}';
      },
    );

    // Pattern: ScaffoldMessenger.of(context) after await
    content = content.replaceAllMapped(
      RegExp(r'(\s+)(ScaffoldMessenger\.of\(context\)[^;]*;)'),
      (match) {
        final indent = match.group(1)!;
        final scaffoldCall = match.group(2)!;
        return '${indent}if (mounted) {\n${indent}  $scaffoldCall\n${indent}}';
      },
    );

    // Pattern: showDialog calls after await
    content = content.replaceAllMapped(
      RegExp(r'(\s+)(showDialog\([^)]*context:[^)]*\)[^;]*;)'),
      (match) {
        final indent = match.group(1)!;
        final dialogCall = match.group(2)!;
        return '${indent}if (mounted) {\n${indent}  $dialogCall\n${indent}}';
      },
    );

    if (content != originalContent) {
      await file.writeAsString(content);
    }
  } catch (e) {
  }
}
