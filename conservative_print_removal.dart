import 'dart:io';

void main() async {
  print('Removing print statements conservatively...');

  // Only target specific files that we know are safe to edit
  final targetFiles = [
    'lib/services/booking_service.dart',
    'lib/api/api_connect.dart',
    'lib/profile.dart',
  ];

  for (final filePath in targetFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      await removeDebugPrints(file);
    }
  }

  print('Finished!');
}

Future<void> removeDebugPrints(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;

    // Remove print statements that are clearly for debugging
    // Look for lines that contain only print statements
    final lines = content.split('\n');
    final cleanedLines = <String>[];

    for (String line in lines) {
      // Skip lines that are purely print statements for debugging
      if (line.trim().startsWith('print(') &&
          (line.contains('[DEBUG]') ||
              line.contains('[ERROR]') ||
              line.contains('[INFO]') ||
              line.contains('[WARNING]') ||
              line.contains('===') ||
              line.trim() == 'print("");' ||
              line.trim() == "print('');")) {
        // Skip this line (remove the print statement)
        continue;
      }
      cleanedLines.add(line);
    }

    content = cleanedLines.join('\n');

    if (content != originalContent) {
      await file.writeAsString(content);
      print('Cleaned: ${file.path}');
    }
  } catch (e) {
    print('Error processing ${file.path}: $e');
  }
}
