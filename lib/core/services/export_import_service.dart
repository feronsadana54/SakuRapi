import 'package:csv/csv.dart';

import '../../domain/entities/transaction_entity.dart';
import '../utils/date_utils.dart';
import 'platform/csv_file_helper.dart';

/// Result of a CSV import — each row that could be parsed.
class ImportRow {
  final String date; // raw date string from CSV
  final String type; // 'income' / 'expense'
  final double amount;
  final String categoryName;
  final String? note;

  const ImportRow({
    required this.date,
    required this.type,
    required this.amount,
    required this.categoryName,
    this.note,
  });
}

/// Export/import helper.  Pure functions — no providers, no state.
///
/// Platform differences (file I/O vs browser download/upload) are handled by
/// [csv_file_helper.dart] which uses conditional imports to select the right
/// implementation at compile time.
class ExportImportService {
  // ── CSV columns ───────────────────────────────────────────────────────────
  static const List<String> _headers = [
    'Tanggal',
    'Tipe',
    'Jumlah',
    'Kategori',
    'Catatan',
  ];

  // ── Export ────────────────────────────────────────────────────────────────

  /// Generates a CSV from [transactions] and:
  ///   • on Android/iOS: saves to a temp file and triggers the share sheet.
  ///   • on web: triggers a browser download.
  Future<void> exportAndShare(List<Transaction> transactions) async {
    final rows = <List<dynamic>>[_headers];

    for (final tx in transactions) {
      rows.add([
        AppDateUtils.formatShort(tx.date),
        tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
        tx.amount.toInt().toString(),
        tx.category.name,
        tx.note ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final fileName =
        'dompetku_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    await saveAndShareCsv(csv, fileName);
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Opens a file picker for CSV files and returns parsed rows.
  /// Returns null if the user cancels the picker.
  /// Throws a [FormatException] if the file is not a valid DompetKu CSV.
  Future<List<ImportRow>?> pickAndParse() async {
    final content = await pickCsvContent();
    if (content == null) return null;

    final table = const CsvToListConverter(eol: '\n').convert(content);

    if (table.isEmpty) {
      throw const FormatException('File CSV kosong.');
    }

    // Validate header row
    final header = table.first.map((e) => e.toString().trim()).toList();
    for (var i = 0; i < _headers.length; i++) {
      if (i >= header.length || header[i] != _headers[i]) {
        throw const FormatException(
          'Format CSV tidak valid. Pastikan file diekspor dari DompetKu.',
        );
      }
    }

    final importRows = <ImportRow>[];
    for (var i = 1; i < table.length; i++) {
      final row = table[i];
      if (row.length < 4) continue;

      final amountStr = row[2].toString().replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(amountStr);
      if (amount == null || amount <= 0) continue;

      importRows.add(ImportRow(
        date: row[0].toString().trim(),
        type: row[1].toString().trim().toLowerCase() == 'pemasukan'
            ? 'income'
            : 'expense',
        amount: amount,
        categoryName: row[3].toString().trim(),
        note: row.length > 4 && row[4].toString().trim().isNotEmpty
            ? row[4].toString().trim()
            : null,
      ));
    }

    return importRows;
  }
}
