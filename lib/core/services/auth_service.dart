import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/enums/auth_mode.dart';
import '../../firebase_options.dart';

/// Mengelola autentikasi pengguna.
///
/// Mendukung dua mode:
///   - Mode tamu (guest): data tersimpan lokal menggunakan UUID acak.
///   - Login Google: menggunakan Firebase Authentication + Google Sign-In.
///     Memerlukan [kFirebaseConfigured] == true.
///
/// Kunci SharedPreferences yang digunakan:
///   saku_auth_id    — UUID atau Firebase UID pengguna
///   saku_auth_name  — DisplayName pengguna
///   saku_auth_email — Email (Google mode saja)
///   saku_auth_mode  — 'guest' atau 'google'
class AuthService {
  static const _keyAuthId = 'saku_auth_id';
  static const _keyAuthName = 'saku_auth_name';
  static const _keyAuthEmail = 'saku_auth_email';
  static const _keyAuthMode = 'saku_auth_mode';

  final SharedPreferences _prefs;

  AuthService(this._prefs);

  // ── Mode Tamu ─────────────────────────────────────────────────────────────

  /// Login sebagai pengguna tamu.
  ///
  /// Membuat identitas lokal berbasis UUID dan menyimpannya ke SharedPreferences.
  /// Jika ID sudah ada dari sesi sebelumnya, ID yang sama digunakan kembali.
  Future<UserEntity> signInAsGuest() async {
    const uuid = Uuid();
    final id = _prefs.getString(_keyAuthId) ?? uuid.v4();
    const name = 'Tamu';
    const mode = 'guest';

    await _prefs.setString(_keyAuthId, id);
    await _prefs.setString(_keyAuthName, name);
    await _prefs.setString(_keyAuthMode, mode);

    return UserEntity(
      id: id,
      displayName: name,
      authMode: AuthMode.guest,
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Login dengan akun Google menggunakan Firebase Authentication.
  ///
  /// Memerlukan:
  ///   1. [kFirebaseConfigured] == true (jalankan `flutterfire configure`)
  ///   2. SHA-1 debug key terdaftar di Firebase Console
  ///   3. google_sign_in dikonfigurasi di Info.plist (iOS) / AndroidManifest
  ///
  /// Mengembalikan:
  ///   - [UserEntity] jika berhasil
  ///   - null jika Firebase belum dikonfigurasi
  ///   - melempar Exception jika login gagal (ditangkap AuthNotifier)
  Future<UserEntity?> signInWithGoogle() async {
    // Firebase belum dikonfigurasi — kembalikan null dengan pesan informatif.
    if (!kFirebaseConfigured) {
      return null;
    }

    try {
      // Inisiasi alur Google Sign-In
      final googleSignIn = GoogleSignIn();
      final googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        // Pengguna membatalkan dialog pemilihan akun Google
        return null;
      }

      final googleAuth = await googleAccount.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autentikasi ke Firebase dengan kredensial Google
      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      final id = fbUser.uid;
      final name = fbUser.displayName ?? googleAccount.displayName ?? 'Pengguna';
      final email = fbUser.email ?? googleAccount.email;

      // Simpan sesi ke SharedPreferences agar tetap ada setelah restart
      await _prefs.setString(_keyAuthId, id);
      await _prefs.setString(_keyAuthName, name);
      await _prefs.setString(_keyAuthEmail, email);
      await _prefs.setString(_keyAuthMode, 'google');

      return UserEntity(
        id: id,
        displayName: name,
        email: email,
        authMode: AuthMode.google,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception('Login Google gagal: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Login Google gagal: $e');
    }
  }

  // ── Sesi Aktif ────────────────────────────────────────────────────────────

  /// Mengembalikan pengguna yang sedang login, atau null jika belum login.
  ///
  /// Dipanggil oleh [SplashScreen] untuk menentukan rute awal aplikasi.
  /// Memeriksa SharedPreferences lokal (cepat, tidak butuh jaringan).
  Future<UserEntity?> getCurrentUser() async {
    final id = _prefs.getString(_keyAuthId);
    final name = _prefs.getString(_keyAuthName);
    final modeStr = _prefs.getString(_keyAuthMode);

    if (id == null || name == null || modeStr == null) return null;

    final mode = modeStr == 'google' ? AuthMode.google : AuthMode.guest;
    final email =
        mode == AuthMode.google ? _prefs.getString(_keyAuthEmail) : null;

    return UserEntity(
      id: id,
      displayName: name,
      email: email,
      authMode: mode,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Logout pengguna saat ini dan menghapus semua kredensial tersimpan.
  ///
  /// Juga melakukan sign-out dari Firebase + Google Sign-In jika mode Google.
  Future<void> signOut() async {
    final mode = _prefs.getString(_keyAuthMode);

    if (mode == 'google' && kFirebaseConfigured) {
      try {
        await GoogleSignIn().signOut();
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {
        // Non-fatal: clear lokal data tetap dilanjutkan
      }
    }

    await _prefs.remove(_keyAuthId);
    await _prefs.remove(_keyAuthName);
    await _prefs.remove(_keyAuthEmail);
    await _prefs.remove(_keyAuthMode);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Mengembalikan ID pengguna yang sedang login, atau null.
  /// Berguna untuk [SyncService] tanpa perlu mengambil entitas lengkap.
  String? getCurrentUserId() => _prefs.getString(_keyAuthId);

  /// Apakah pengguna saat ini login dengan Google (bukan tamu).
  bool get isGoogleUser =>
      _prefs.getString(_keyAuthMode) == 'google';
}
