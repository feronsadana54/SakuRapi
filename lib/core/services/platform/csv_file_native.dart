import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves [csv] content to a temp file and opens the system share sheet.
/// Used on Android / iOS / desktop.
Future<void> saveAndShareCsv(String csv, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString(csv);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: 'DompetKu — Ekspor Transaksi',
  );
}

/// Opens a native file picker for CSV files and returns the file's text
/// content, or null if the user cancelled.
Future<String?> pickCsvContent() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: false,
  );

  if (result == null || result.files.isEmpty) return null;

  final path = result.files.single.path;
  if (path == null) return null;

  return File(path).readAsString();
}
