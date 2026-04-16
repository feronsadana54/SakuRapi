/// Stub — should never be imported directly at runtime.
/// The conditional import in [csv_file_helper.dart] selects the correct
/// platform implementation ([csv_file_native.dart] or [csv_file_web.dart]).
Future<void> saveAndShareCsv(String csv, String fileName) async {
  throw UnsupportedError(
      'saveAndShareCsv is not supported on this platform.');
}

Future<String?> pickCsvContent() async {
  throw UnsupportedError('pickCsvContent is not supported on this platform.');
}
