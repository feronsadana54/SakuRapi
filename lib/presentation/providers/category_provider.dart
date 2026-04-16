import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/enums/category_type.dart';
import '../../domain/enums/transaction_type.dart';
import 'database_provider.dart';

// ── Reactive stream of all categories ────────────────────────────────────────

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

// ── Categories filtered for a specific transaction type ───────────────────────

/// Returns categories applicable to [TransactionType.income] or [TransactionType.expense].
/// Includes categories typed 'both'.
final categoriesForTypeProvider =
    Provider.family<AsyncValue<List<Category>>, TransactionType>(
  (ref, txType) {
    return ref.watch(categoriesProvider).whenData((cats) {
      return cats.where((c) {
        if (c.type == CategoryType.both) return true;
        if (txType == TransactionType.income) return c.type == CategoryType.income;
        return c.type == CategoryType.expense;
      }).toList();
    });
  },
);
