import 'dart:async' show unawaited;
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/cloud_restore_service.dart';
import '../../core/services/sync_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_hutang_repository.dart';
import '../../domain/repositories/i_piutang_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import 'database_provider.dart';

// ── Background sync status ────────────────────────────────────────────────────

/// true selama cloud restore / migrasi berjalan di background setelah login
/// atau pada startup ketika sesi sudah ada.
/// Digunakan oleh [HomeScreen] untuk menampilkan banner "Sedang memulihkan...".
final isBackgroundSyncingProvider = StateProvider<bool>((ref) => false);

/// Status pengunggahan terakhir saat logout. true selama proses sync-before-logout
/// berjalan; UI menampilkannya sebagai snackbar di [SettingsScreen].
final isLogoutSyncingProvider = StateProvider<bool>((ref) => false);

// ── Pending deep link (Email Sign-In) ─────────────────────────────────────────

/// URI tautan masuk email yang diterima dari deep link.
///
/// Diisi oleh [main.dart] via ProviderContainer sesaat sebelum runApp
/// (cold start) atau via uriLinkStream saat aplikasi sudah berjalan.
/// Dikonsumsi oleh [_EmailLinkHandler] di [app.dart].
final pendingEmailLinkProvider = StateProvider<String?>((ref) => null);

// ── Service provider ──────────────────────────────────────────────────────────

/// Menyediakan [AuthService] yang terhubung ke [SharedPreferences] aplikasi.
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

// ── Auth notifier ─────────────────────────────────────────────────────────────

/// Mengelola state pengguna yang sedang login sepanjang masa hidup aplikasi.
///
/// State: [AsyncValue<UserEntity?>]
///   - AsyncLoading    — memuat sesi saat startup
///   - AsyncData(user) — pengguna sudah login (tamu / Google / Email Link)
///   - AsyncData(null) — tidak ada sesi, arahkan ke layar login
///   - AsyncError      — kegagalan storage yang tidak terduga
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final Ref _ref;
  final AuthService _service;
  final SyncService _sync;
  final CloudRestoreService _restoreService;
  final ITransactionRepository _txRepo;
  final IHutangRepository _hutangRepo;
  final IPiutangRepository _piutangRepo;
  final ICategoryRepository _categoryRepo;

  AuthNotifier(
    this._ref,
    this._service,
    this._sync,
    this._restoreService,
    this._txRepo,
    this._hutangRepo,
    this._piutangRepo,
    this._categoryRepo,
  ) : super(const AsyncLoading()) {
    _loadCurrentUser();
  }

  /// Memuat user dari prefs saat aplikasi pertama kali dibuka. Jika user sudah
  /// terautentikasi (Google / Email Link), restore latar belakang dipicu agar
  /// SQLite lokal selaras dengan data terbaru di Firestore.
  ///
  /// **Kenapa wajib restore di startup**: tanpa ini, perangkat baru atau
  /// pemasangan ulang yang masih punya sesi tersimpan akan menampilkan UI
  /// kosong meskipun data utuh ada di cloud, karena listener realtime sendiri
  /// tidak menjamin kategori tiba sebelum transaksi (race condition).
  Future<void> _loadCurrentUser() async {
    const tag = 'AuthNotifier._loadCurrentUser';
    try {
      final user = await _service.getCurrentUser();
      state = AsyncData(user);

      if (user != null && user.isAuthenticated) {
        dev.log(
          '[startup] Sesi tersimpan ditemukan — '
          'uid=${user.id}, mode=${user.authMode.name} '
          '→ memulai restore latar belakang',
          name: tag,
        );
        _ref.read(isBackgroundSyncingProvider.notifier).state = true;
        unawaited(_restoreBackground(tag, Stopwatch()..start()));
      } else if (user != null) {
        dev.log(
          '[startup] Sesi tamu (uid=${user.id}) — restore dilewati',
          name: tag,
        );
      } else {
        dev.log('[startup] Tidak ada sesi tersimpan', name: tag);
      }
    } catch (e, st) {
      dev.log('[startup] Error memuat sesi: $e',
          name: tag, level: 1000, error: e, stackTrace: st);
      state = AsyncError(e, st);
    }
  }

  // ── Login sebagai Tamu ────────────────────────────────────────────────────

  Future<void> signInAsGuest() async {
    state = const AsyncLoading();
    try {
      final user = await _service.signInAsGuest();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Login Google (dari layar login — belum ada sesi) ──────────────────────

  /// Login dengan Google untuk pengguna yang belum punya sesi.
  ///
  /// **Alur cepat**: state diperbarui segera setelah Firebase auth selesai,
  /// cloud restore berjalan di background via [unawaited].
  Future<bool> signInWithGoogle() async {
    const tag = 'AuthNotifier.signInWithGoogle';
    final sw = Stopwatch()..start();
    state = const AsyncLoading();
    try {
      dev.log(
          '[login] [${DateTime.now().toIso8601String()}] Tombol Google ditekan',
          name: tag);

      final user = await _service.signInWithGoogle();
      if (user == null) {
        state = AsyncData(await _service.getCurrentUser());
        return false;
      }

      dev.log(
          '[login] Auth selesai (${sw.elapsedMilliseconds}ms) — navigasi segera',
          name: tag);
      state = AsyncData(user);
      _ref.read(isBackgroundSyncingProvider.notifier).state = true;
      unawaited(_restoreBackground(tag, sw));
      return true;
    } catch (e, st) {
      dev.log('[login] Error: $e', name: tag, level: 1000, error: e, stackTrace: st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ── Upgrade Tamu ke Google (dari Settings) ────────────────────────────────

  /// Upgrade akun tamu ke Google + migrasi data lokal ke cloud di background.
  Future<bool> upgradeGuestToGoogle() async {
    const tag = 'AuthNotifier.upgradeGuestToGoogle';
    final sw = Stopwatch()..start();
    state = const AsyncLoading();
    try {
      dev.log('[upgrade] [${DateTime.now().toIso8601String()}] Upgrade tamu → Google',
          name: tag);

      final user = await _service.signInWithGoogle();
      if (user == null) {
        state = AsyncData(await _service.getCurrentUser());
        return false;
      }

      dev.log('[upgrade] Auth selesai (${sw.elapsedMilliseconds}ms)', name: tag);
      state = AsyncData(user);
      _ref.read(isBackgroundSyncingProvider.notifier).state = true;
      unawaited(_upgradeBackground(tag, sw));
      return true;
    } catch (e, st) {
      dev.log('[upgrade] Error: $e', name: tag, level: 1000, error: e, stackTrace: st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ── Email Link Sign-In ────────────────────────────────────────────────────

  /// Mengirim tautan masuk ke [email].
  ///
  /// Melempar Exception jika gagal (jaringan, email tidak valid, dll.).
  /// UI bertanggung jawab menangkap dan menampilkan error.
  Future<void> sendEmailSignInLink(String email) async {
    await _service.sendEmailSignInLink(email);
  }

  /// Memproses URI deep link yang diterima saat pengguna mengklik tautan email.
  ///
  /// Dipanggil oleh [_EmailLinkHandler] di [app.dart].
  /// Mengembalikan true jika sign-in berhasil.
  Future<bool> handleEmailLink(String link) async {
    const tag = 'AuthNotifier.handleEmailLink';

    if (!_service.isSignInWithEmailLink(link)) {
      dev.log('[emailLink] URI bukan tautan sign-in yang valid', name: tag);
      return false;
    }

    final email = _service.getPendingEmail();
    if (email == null) {
      dev.log(
          '[emailLink] Pending email tidak ditemukan — tidak dapat menyelesaikan sign-in',
          name: tag);
      return false;
    }

    final wasGuest = _service.isGuestUser;
    final sw = Stopwatch()..start();
    state = const AsyncLoading();

    try {
      dev.log('[emailLink] Menyelesaikan sign-in untuk $email', name: tag);
      final user = await _service.signInWithEmailLink(email, link);
      if (user == null) {
        state = AsyncData(await _service.getCurrentUser());
        return false;
      }

      dev.log(
          '[emailLink] Auth selesai (${sw.elapsedMilliseconds}ms) — update state segera',
          name: tag);
      state = AsyncData(user);

      _ref.read(isBackgroundSyncingProvider.notifier).state = true;
      if (wasGuest) {
        unawaited(_upgradeBackground(tag, sw));
      } else {
        unawaited(_restoreBackground(tag, sw));
      }
      return true;
    } catch (e, st) {
      dev.log('[emailLink] Error: $e', name: tag, level: 1000, error: e, stackTrace: st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ── Perbarui Profil ───────────────────────────────────────────────────────

  /// Memperbarui nama tampilan di Firebase Auth + SharedPreferences + state.
  Future<void> updateDisplayName(String name) async {
    try {
      final updated = await _service.updateDisplayName(name);
      if (updated != null) state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Sinkronisasi manual (resume / periodic / manual button) ──────────────

  /// Menjalankan satu siklus restore dari Firestore → SQLite untuk pengguna
  /// yang sedang login (Google / Email Link).
  ///
  /// **Kapan dipanggil:**
  ///   - Aplikasi resume dari background ([BackgroundSyncCoordinator])
  ///   - Timer periodik 30 menit selama aplikasi terbuka
  ///   - Jadwal harian (22:00) selama aplikasi terbuka
  ///   - Tombol "Sinkronkan Sekarang" (jika ditambahkan ke UI)
  ///
  /// **Bukan tindakan blocking** — gagal di-swallow, data lokal tetap aman.
  Future<void> runFullSync({String trigger = 'manual'}) async {
    const tag = 'AuthNotifier.runFullSync';
    final user = state.valueOrNull;
    if (user == null || !user.isAuthenticated) {
      dev.log('[sync:$trigger] Tidak ada sesi terautentikasi — sync dilewati',
          name: tag);
      return;
    }
    if (!_sync.isAvailable) return;

    final sw = Stopwatch()..start();
    dev.log('[sync:$trigger] Memulai full sync (uid=${user.id})', name: tag);
    try {
      final result = await _restoreService
          .restoreFromCloud()
          .timeout(const Duration(seconds: 30));
      sw.stop();
      dev.log(
        '[sync:$trigger] Selesai (${sw.elapsedMilliseconds}ms) — '
        '${result.categoriesRestored} kategori, '
        '${result.transactionsRestored} tx, '
        '${result.hutangRestored} hutang, '
        '${result.piutangRestored} piutang, '
        '${result.paymentsRestored} pembayaran',
        name: tag,
      );
    } catch (e) {
      dev.log('[sync:$trigger] Gagal (non-fatal): $e', name: tag, level: 900);
    }
  }

  // ── Logout (sederhana, tanpa flush) ───────────────────────────────────────

  /// Keluar dari akun tanpa menunggu flush data lokal.
  ///
  /// Pakai [signOutSafely] untuk pengalaman yang aman: ia akan mencoba
  /// menyelesaikan upload Firestore yang masih dalam antrean lokal sebelum
  /// menghapus sesi. Metode ini tetap ada sebagai fallback.
  Future<void> signOut() async {
    try {
      await _service.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Logout aman: menunggu Firestore menyelesaikan tulisan lokal yang masih
  /// tertahan di antrean offline (`waitForPendingWrites`), lalu sign-out.
  ///
  /// **Strategi timeout**: bila device offline atau Firestore lambat,
  /// menunggu maksimal [flushTimeout] kemudian tetap melanjutkan logout.
  /// Data yang belum sempat ter-flush akan tetap terkirim oleh Firestore SDK
  /// pada login berikutnya berkat persistensi offline yang aktif.
  ///
  /// Mengembalikan true jika flush berhasil dalam timeout, false jika
  /// timeout/offline (dalam kedua kasus, sign-out tetap dilakukan).
  Future<bool> signOutSafely({
    Duration flushTimeout = const Duration(seconds: 6),
  }) async {
    const tag = 'AuthNotifier.signOutSafely';
    final sw = Stopwatch()..start();
    var flushed = false;

    _ref.read(isLogoutSyncingProvider.notifier).state = true;
    try {
      if (_sync.isAvailable) {
        try {
          dev.log('[logout] Menunggu Firestore flush antrean lokal...', name: tag);
          await FirebaseFirestore.instance
              .waitForPendingWrites()
              .timeout(flushTimeout);
          flushed = true;
          dev.log(
            '[logout] Flush selesai dalam ${sw.elapsedMilliseconds}ms',
            name: tag,
          );
        } catch (e) {
          dev.log(
            '[logout] Flush gagal/timeout (${sw.elapsedMilliseconds}ms): $e — '
            'lanjut sign-out, data akan terkirim saat login berikutnya',
            name: tag,
            level: 900,
          );
        }
      } else {
        dev.log('[logout] Sync tidak aktif — langsung sign-out', name: tag);
      }

      await _service.signOut();
      state = const AsyncData(null);
      return flushed;
    } catch (e, st) {
      dev.log('[logout] Error: $e', name: tag, level: 1000, error: e, stackTrace: st);
      state = AsyncError(e, st);
      return false;
    } finally {
      _ref.read(isLogoutSyncingProvider.notifier).state = false;
    }
  }

  // ── Background tasks ──────────────────────────────────────────────────────

  /// Cloud restore + bootstrap categories collection (login Google / Email Link baru).
  ///
  /// Urutan (penting — jangan dibalik):
  ///   1. syncAllLocalCategories() — upload kategori lokal → Firestore
  ///      (memastikan Firestore punya kategori sebelum transaksi di-restore)
  ///   2. restoreFromCloud() — pass pertama: unduh data cloud → SQLite lokal
  ///   3. Jika ada transaksi yang dilewati (kategori belum ada saat pass 1),
  ///      lakukan retry pass kedua.
  ///
  /// Retry pass diperlukan pada skenario "first login after bootstrap": pass
  /// pertama berjalan saat Firestore categories masih kosong, sehingga transaksi
  /// terlewati. Setelah syncAllLocalCategories() (langkah 1), kategori sudah ada
  /// di Firestore, dan pass kedua dapat memulihkan transaksi yang tertinggal.
  Future<void> _restoreBackground(String tag, Stopwatch sw) async {
    try {
      // Langkah 1: bootstrap kategori lokal ke Firestore
      final allCats = await _categoryRepo.getAll();
      dev.log(
        '[bg] Sinkronisasi ${allCats.length} kategori lokal ke Firestore...',
        name: tag,
      );
      await _sync.syncAllLocalCategories(allCats);
      dev.log('[bg] Sinkronisasi kategori selesai', name: tag);

      // Langkah 2: restore pass pertama
      dev.log('[bg] Restore pass 1 dimulai...', name: tag);
      final result = await _restoreService.restoreFromCloud();
      dev.log(
        '[bg] Restore pass 1 selesai — '
        '${result.categoriesRestored} kategori, '
        '${result.transactionsRestored} tx dipulihkan, '
        '${result.transactionsSkipped} tx dilewati',
        name: tag,
      );

      // Langkah 3: retry jika ada transaksi yang dilewati
      if (result.transactionsSkipped > 0) {
        dev.log(
          '[bg] ${result.transactionsSkipped} tx dilewati — memulai retry pass 2...',
          name: tag,
        );
        final retry = await _restoreService.restoreFromCloud();
        sw.stop();
        dev.log(
          '[bg] Retry pass 2 selesai — '
          '${retry.transactionsRestored} tx dipulihkan tambahan, '
          '${retry.transactionsSkipped} tx masih dilewati. '
          'Total waktu: ${sw.elapsedMilliseconds}ms',
          name: tag,
        );
      } else {
        sw.stop();
        dev.log(
          '[bg] Selesai tanpa retry. Total waktu: ${sw.elapsedMilliseconds}ms',
          name: tag,
        );
      }
    } catch (e) {
      dev.log('[bg] Restore gagal (non-fatal): $e', name: tag, level: 900);
    } finally {
      if (mounted) {
        _ref.read(isBackgroundSyncingProvider.notifier).state = false;
      }
    }
  }

  /// Upload data lokal → cloud, lalu restore cloud → lokal (upgrade dari tamu).
  ///
  /// migrateGuestData() sudah meng-upload semua kategori (termasuk default),
  /// sehingga Firestore pasti punya kategori sebelum restore — tidak perlu
  /// syncAllLocalCategories() terpisah. Retry pass tetap diperlukan untuk
  /// menangani kondisi race jika ada transaksi yang terlewati.
  Future<void> _upgradeBackground(String tag, Stopwatch sw) async {
    try {
      // Langkah 1: upload semua data lokal (transaksi + kategori) ke Firestore
      dev.log('[bg] Memulai migrasi data lokal ke cloud...', name: tag);
      await _migrateLocalDataToCloud();
      dev.log(
        '[bg] Migrasi selesai (${sw.elapsedMilliseconds}ms), memulai restore pass 1...',
        name: tag,
      );

      // Langkah 2: restore pass pertama
      final result = await _restoreService.restoreFromCloud();
      dev.log(
        '[bg] Restore pass 1 selesai — '
        '${result.categoriesRestored} kategori, '
        '${result.transactionsRestored} tx dipulihkan, '
        '${result.transactionsSkipped} tx dilewati',
        name: tag,
      );

      // Langkah 3: retry jika ada transaksi yang dilewati
      if (result.transactionsSkipped > 0) {
        dev.log(
          '[bg] ${result.transactionsSkipped} tx dilewati — retry pass 2...',
          name: tag,
        );
        final retry = await _restoreService.restoreFromCloud();
        sw.stop();
        dev.log(
          '[bg] Upgrade selesai (retry) — ${retry.transactionsRestored} tx '
          'dipulihkan tambahan. Total: ${sw.elapsedMilliseconds}ms',
          name: tag,
        );
      } else {
        sw.stop();
        dev.log('[bg] Upgrade selesai total: ${sw.elapsedMilliseconds}ms', name: tag);
      }
    } catch (e) {
      dev.log('[bg] Upgrade background gagal (non-fatal): $e',
          name: tag, level: 900);
    } finally {
      if (mounted) {
        _ref.read(isBackgroundSyncingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _migrateLocalDataToCloud() async {
    const tag = 'AuthNotifier._migrateLocalDataToCloud';
    try {
      final transactions =
          await _txRepo.getByDateRange(DateTime(2000), DateTime(2100));
      final hutangList = await _hutangRepo.getAll();
      final piutangList = await _piutangRepo.getAll();
      final categories = await _categoryRepo.getAll();

      await _sync.migrateGuestData(
        transactions: transactions,
        hutangList: hutangList,
        piutangList: piutangList,
        categories: categories,
      );

      dev.log(
        '[migrate] ${transactions.length} tx, ${hutangList.length} hutang, '
        '${piutangList.length} piutang, '
        '${categories.length} kategori (${categories.where((c) => !c.isDefault).length} kustom) diunggah',
        name: tag,
      );
    } catch (e) {
      dev.log('Migrasi data tamu gagal (non-fatal): $e', name: tag, level: 900);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  UserEntity? get currentUser => state.valueOrNull;
  bool get isGoogleUser => currentUser?.authMode.name == 'google';
  bool get isEmailLinkUser => currentUser?.authMode.name == 'emailLink';
  bool get isGuestUser => currentUser?.authMode.name == 'guest';
}

// ── Provider ──────────────────────────────────────────────────────────────────

final currentUserProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(
  (ref) => AuthNotifier(
    ref,
    ref.watch(authServiceProvider),
    ref.watch(syncServiceProvider),
    ref.watch(cloudRestoreServiceProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(hutangRepositoryProvider),
    ref.watch(piutangRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);
