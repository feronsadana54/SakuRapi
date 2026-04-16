import 'dart:convert';
import 'dart:js_interop';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

/// Triggers a browser download of [csv] content as a `.csv` file.
/// Used on web — no system share sheet is available in a browser context.
Future<void> saveAndShareCsv(String csv, String fileName) async {
  final bytes = utf8.encode(csv);

  // Build a Blob from the UTF-8 bytes and create a temporary object URL.
  final uint8 = bytes.toJS;
  final blob = web.Blob(
    [uint8].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);

  // Create an invisible anchor, trigger a click to start the download, then
  // revoke the object URL to free memory.
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..setAttribute('download', fileName)
        ..click();
  // ignore: unused_local_variable
  final _ = anchor; // anchor reference kept to avoid GC before click fires
  web.URL.revokeObjectURL(url);
}

/// Opens a browser file picker for CSV files and returns the file's text
/// content, or null if the user cancelled.
///
/// On web, [FilePicker] returns raw bytes because there is no file-system
/// path — we decode the bytes in Dart instead of reading via [dart:io].
Future<String?> pickCsvContent() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true, // web must receive bytes — there is no file path
  );

  if (result == null || result.files.isEmpty) return null;

  final bytes = result.files.single.bytes;
  if (bytes == null) return null;

  return utf8.decode(bytes);
}
