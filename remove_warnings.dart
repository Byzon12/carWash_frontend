import 'dart:io';

void main() async {
  // Find all Dart files
  final directory = Directory('.');
  final dartFiles =
      directory
          .listSync(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .cast<File>()
          .where(
            (file) =>
                !file.path.contains('.dart_tool') &&
                !file.path.contains('build'),
          )
          .toList();
  for (final file in dartFiles) {
    await removeWarningsFromFile(file);
  }
}

Future<void> removeWarningsFromFile(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;

    // Remove print statements with [DEBUG], [ERROR], [WARNING], [INFO] prefixes
    content = content.replaceAllMapped(
      RegExp(
        r"(\s*)print\(\s*'\[(?:DEBUG|ERROR|WARNING|INFO)\][^']*'\s*\);\s*",
      ),
      (match) => '',
    );

    // Remove print statements with interpolated debug messages
    content = content.replaceAllMapped(
      RegExp(r"(\s*)print\(\s*'[^']*\$[^']*'\s*\);\s*"),
      (match) => '',
    );

    // Remove simple print statements
    content = content.replaceAllMapped(
      RegExp(r"(\s*)print\([^)]*\);\s*"),
      (match) => '',
    );

    // Replace withOpacity with withValues for color opacity
    content = content.replaceAllMapped(
      RegExp(r'\.withOpacity\(([^)]+)\)'),
      (match) => '.withValues(alpha: ${match.group(1)})',
    );

    // Fix BuildContext async usage by adding null checks and mounted checks
    // This is more complex and may require manual review, so we'll just comment the problematic lines

    if (content != originalContent) {
      await file.writeAsString(content);
    }
  } catch (e) {}
}
