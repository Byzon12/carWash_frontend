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
    await removePrintStatementsOnly(file);
  }
}

Future<void> removePrintStatementsOnly(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;

    // Only remove print statements that are clearly for debugging
    // Be very conservative to avoid breaking code structure

    // Remove lines that are only print statements (with optional whitespace)
    content = content.replaceAllMapped(
      RegExp(r'^\s*print\([^)]*\);\s*$', multiLine: true),
      (match) => '',
    );

    if (content != originalContent) {
      await file.writeAsString(content);
    }
  } catch (e) {
  }
}
