import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/hutang_dao.dart';
import '../../data/database/daos/piutang_dao.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/hutang_repository_impl.dart';
import '../../data/repositories/piutang_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_hutang_repository.dart';
import '../../domain/repositories/i_piutang_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';

// ── Graf ketergantungan provider ──────────────────────────────────────────────
//
//  sharedPreferencesProvider  ← di-override di main() via ProviderScope
//       │
//       └─► settingsRepositoryProvider
//           authServiceProvider  (di auth_provider.dart)
//
//  appDatabaseProvider  ← satu instance AppDatabase per masa hidup ProviderScope
//       │
//       ├─► categoryDaoProvider
//       │       └─► categoryRepositoryProvider
//       ├─► transactionDaoProvider
//       │       └─► transactionRepositoryProvider
//       ├─► hutangDaoProvider
//       │       └─► hutangRepositoryProvider
//       └─► piutangDaoProvider
//               └─► piutangRepositoryProvider
//
// Semua provider fitur (transaction_provider, hutang_provider, …) mengawasi
// provider repository di atas — tidak pernah langsung ke DAO atau DB provider.

// ── SharedPreferences ────────────────────────────────────────────────────────

/// Wajib di-override di [ProviderScope] dengan instance yang sudah dimuat.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

// ── Database ─────────────────────────────────────────────────────────────────

/// Satu-satunya instance Drift [AppDatabase] sepanjang masa hidup aplikasi.
///
/// [ref.onDispose] memastikan koneksi SQLite ditutup saat [ProviderScope]
/// di-dispose (shutdown aplikasi atau teardown test).
/// Dalam widget test, override provider ini dengan [AppDatabase(NativeDatabase.memory())]
/// agar tidak menyentuh file on-disk sungguhan.
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

final hutangDaoProvider = Provider<HutangDao>(
  (ref) => ref.watch(appDatabaseProvider).hutangDao,
);

final piutangDaoProvider = Provider<PiutangDao>(
  (ref) => ref.watch(appDatabaseProvider).piutangDao,
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

final hutangRepositoryProvider = Provider<IHutangRepository>(
  (ref) => HutangRepositoryImpl(ref.watch(hutangDaoProvider)),
);

final piutangRepositoryProvider = Provider<IPiutangRepository>(
  (ref) => PiutangRepositoryImpl(ref.watch(piutangDaoProvider)),
);

// ── Sync Service ──────────────────────────────────────────────────────────────

/// Menyediakan [SyncService] untuk sinkronisasi cloud (Firestore).
///
/// Membaca userId dari [AuthService] yang sudah ada di SharedPreferences.
/// Jika pengguna mode tamu atau Firebase belum dikonfigurasi, SyncService
/// tetap dibuat tetapi semua operasinya langsung mengembalikan tanpa aksi.
final syncServiceProvider = Provider<SyncService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authService = AuthService(prefs);
  final userId = authService.getCurrentUserId();
  return SyncService(userId: userId);
});
