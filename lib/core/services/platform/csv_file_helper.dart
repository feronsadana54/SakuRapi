// Platform-aware CSV file helper.
//
// Exports a single top-level API:
//   • saveAndShareCsv — write CSV and share/download
//   • pickCsvContent  — open file picker, return raw text content
//
// The correct implementation is selected at compile-time via conditional
// imports so that dart:io (native) or web interop code is never
// included in an incompatible build.
export 'csv_file_stub.dart'
    if (dart.library.io) 'csv_file_native.dart'
    if (dart.library.js_interop) 'csv_file_web.dart';
