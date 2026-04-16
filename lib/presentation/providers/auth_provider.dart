import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../firebase_options.dart';
import 'database_provider.dart';

// ── Service provider ──────────────────────────────────────────────────────────

/// Menyediakan [AuthService] yang terhubung ke instance [SharedPreferences] aplikasi.
///
/// [AuthService] menyimpan id, nama, email, dan mode autentikasi (guest / google)
/// ke SharedPreferences agar sesi tetap ada setelah aplikasi restart.
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

// ── Auth notifier ─────────────────────────────────────────────────────────────

/// Mengelola state pengguna yang sedang login sepanjang masa hidup aplikasi.
///
/// State berupa [AsyncValue<UserEntity?>]:
/// - [AsyncLoading]    — memuat sesi tersimpan saat startup.
/// - [AsyncData(user)] — pengguna sudah login (tamu atau Google).
/// - [AsyncData(null)] — tidak ada sesi; pengguna harus login.
/// - [AsyncError]      — kegagalan storage yang tidak terduga.
///
/// Diakses oleh [LoginScreen], [SettingsScreen], dan [SplashScreen]
/// (secara tidak langsung melalui [authServiceProvider]).
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncLoading()) {
    _loadCurrentUser();
  }

  /// Membaca sesi tersimpan dari SharedPreferences saat startup.
  /// Dipanggil sekali dari constructor — hasilnya menentukan navigasi awal.
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _service.getCurrentUser();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Login tanpa akun: membuat identitas lokal berbasis UUID.
  ///
  /// Data tersimpan hanya di perangkat ini (SQLite + SharedPreferences).
  /// Dipanggil saat pengguna mengetuk "Masuk sebagai Tamu" di [LoginScreen].
  Future<void> signInAsGuest() async {
    state = const AsyncLoading();
    try {
      final user = await _service.signInAsGuest();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Login dengan Google menggunakan Firebase Authentication.
  ///
  /// Mengembalikan:
  ///   - true  jika berhasil
  ///   - false jika Firebase belum dikonfigurasi ([kFirebaseConfigured] == false)
  ///   - melempar Exception yang harus ditangkap oleh UI
  ///
  /// Saat berhasil, state diperbarui dengan UserEntity Google dan SyncService
  /// aktif untuk sinkronisasi cloud.
  Future<bool> signInWithGoogle() async {
    if (!kFirebaseConfigured) {
      // Tidak melempar — kembalikan false agar UI menampilkan pesan informatif
      return false;
    }

    state = const AsyncLoading();
    try {
      final user = await _service.signInWithGoogle();
      if (user == null) {
        // Pengguna membatalkan atau Firebase tidak tersedia
        final current = await _service.getCurrentUser();
        state = AsyncData(current);
        return false;
      }
      state = AsyncData(user);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // Biarkan UI menangkap dan menampilkan pesan error
    }
  }

  /// Logout: hapus sesi lokal dan Firebase jika mode Google.
  ///
  /// Setelah logout, state diset ke [AsyncData(null)] — UI akan
  /// menavigasi ke layar login.
  Future<void> signOut() async {
    try {
      await _service.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Mengembalikan pengguna yang sedang login (dari state saat ini).
  UserEntity? get currentUser => state.valueOrNull;

  /// Apakah pengguna saat ini login dengan Google.
  bool get isGoogleUser => currentUser?.authMode.name == 'google';
}

// ── Provider ──────────────────────────────────────────────────────────────────

final currentUserProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
