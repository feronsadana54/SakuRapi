import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/cloud_restore_service.dart';
import '../../core/services/realtime_sync_service.dart';
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
//       ├─► settingsRepositoryProvider
//       ├─► authServiceProvider  (di auth_provider.dart)
//       └─► syncServiceProvider  ← userId dan auth mode dibaca lazy dari prefs
//
//  appDatabaseProvider  ← satu instance AppDatabase per masa hidup ProviderScope
//       │
//       ├─► categoryDaoProvider  → categoryRepositoryProvider
//       │                           └─► syncServiceProvider (write-to-cloud)
//       ├─► transactionDaoProvider → transactionRepositoryProvider (+ sync)
//       ├─► hutangDaoProvider → hutangRepositoryProvider (+ sync)
//       └─► piutangDaoProvider → piutangRepositoryProvider (+ sync)
//
//  realtimeSyncServiceProvider  ← listener Firestore → tulis langsung ke DAO
//       ├─► categoryDaoProvider
//       ├─► transactionDaoProvider
//       ├─► hutangDaoProvider
//       └─► piutangDaoProvider
//       [diaktifkan oleh _RealtimeSyncHandler di app.dart via currentUserProvider]

// ── SharedPreferences ────────────────────────────────────────────────────────

/// Wajib di-override di [ProviderScope] dengan instance yang sudah dimuat.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

// ── Database ─────────────────────────────────────────────────────────────────

/// Satu-satunya instance Drift [AppDatabase] sepanjang masa hidup aplikasi.
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

// ── Sync Service ──────────────────────────────────────────────────────────────

/// SyncService membaca userId dan auth mode secara lazy dari SharedPreferences.
///
/// Karena lazy, SyncService otomatis aktif setelah Google Sign-In —
/// tidak perlu invalidate atau recreate provider. Setiap kali [isAvailable]
/// diperiksa (saat insert/update/delete), nilai terbaru dari prefs digunakan.
final syncServiceProvider = Provider<SyncService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncService(prefs: prefs);
});

/// Layanan yang mengambil semua data pengguna dari Firestore dan memulihkannya
/// ke SQLite lokal. Dipanggil saat login (Google / Email Link) berhasil.
final cloudRestoreServiceProvider = Provider<CloudRestoreService>((ref) {
  return CloudRestoreService(
    sync: ref.watch(syncServiceProvider),
    categoryDao: ref.watch(categoryDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    hutangDao: ref.watch(hutangDaoProvider),
    piutangDao: ref.watch(piutangDaoProvider),
  );
});

/// Listener Firestore realtime untuk sinkronisasi multi-perangkat.
///
/// Provider ini menyediakan instance [RealtimeSyncService] yang siap digunakan.
/// Listener-nya diaktifkan/dinonaktifkan secara eksplisit oleh widget
/// [_RealtimeSyncHandler] di `app.dart` berdasarkan perubahan auth state.
/// Provider memanggil [stopListening] otomatis saat di-dispose.
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService(
    categoryDao: ref.watch(categoryDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    hutangDao: ref.watch(hutangDaoProvider),
    piutangDao: ref.watch(piutangDaoProvider),
  );
  ref.onDispose(service.stopListening);
  return service;
});

// ── Repositories ─────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<ISettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

final categoryRepositoryProvider = Provider<ICategoryRepository>(
  (ref) => CategoryRepositoryImpl(
    ref.watch(categoryDaoProvider),
    ref.watch(syncServiceProvider),
  ),
);

/// TransactionRepositoryImpl menerima SyncService untuk sinkronisasi cloud
/// otomatis pada setiap insert/update/delete.
final transactionRepositoryProvider = Provider<ITransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(transactionDaoProvider),
    ref.watch(categoryDaoProvider),
    ref.watch(syncServiceProvider),
  ),
);

/// HutangRepositoryImpl menerima SyncService untuk sinkronisasi cloud otomatis.
final hutangRepositoryProvider = Provider<IHutangRepository>(
  (ref) => HutangRepositoryImpl(
    ref.watch(hutangDaoProvider),
    ref.watch(syncServiceProvider),
  ),
);

/// PiutangRepositoryImpl menerima SyncService untuk sinkronisasi cloud otomatis.
final piutangRepositoryProvider = Provider<IPiutangRepository>(
  (ref) => PiutangRepositoryImpl(
    ref.watch(piutangDaoProvider),
    ref.watch(syncServiceProvider),
  ),
);
