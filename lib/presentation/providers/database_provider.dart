import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';

// ── SharedPreferences ────────────────────────────────────────────────────────

/// Must be overridden in [ProviderScope] with the pre-loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

// ── Database ─────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAOs ──────────────────────────────────────────────────────────────────────

final categoryDaoProvider = Provider<CategoryDao>(
  (ref) => ref.watch(appDatabaseProvider).categoryDao,
);

final transactionDaoProvider = Provider<TransactionDao>(
  (ref) => ref.watch(appDatabaseProvider).transactionDao,
);

// ── Repositories ─────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<ISettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

final categoryRepositoryProvider = Provider<ICategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoryDaoProvider)),
);

final transactionRepositoryProvider = Provider<ITransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(transactionDaoProvider),
    ref.watch(categoryDaoProvider),
  ),
);
