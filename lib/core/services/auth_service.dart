import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/enums/auth_mode.dart';

/// Mengelola autentikasi pengguna.
///
/// Mendukung tiga mode:
///   - guest     : identitas lokal UUID, tidak ada akun cloud.
///   - google    : Firebase Auth via popup (web) atau google_sign_in (native).
///   - emailLink : Firebase Auth passwordless — tautan masuk dikirim ke email.
///
/// Kunci SharedPreferences:
///   saku_auth_id       — UUID atau Firebase UID
///   saku_auth_name     — nama tampilan
///   saku_auth_email    — email (google / emailLink saja)
///   saku_auth_mode     — 'guest' | 'google' | 'emailLink'
///   saku_pending_email — email sementara saat menunggu verifikasi link masuk
class AuthService {
  static const _keyAuthId = 'saku_auth_id';
  static const _keyAuthName = 'saku_auth_name';
  static const _keyAuthEmail = 'saku_auth_email';
  static const _keyAuthMode = 'saku_auth_mode';
  static const _keyPendingEmail = 'saku_pending_email';

  /// Web OAuth 2.0 Client ID — hanya dipakai untuk alur native (Android/iOS).
  /// Nilai override via --dart-define=GOOGLE_WEB_CLIENT_ID=...
  static const _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com',
  );

  final SharedPreferences _prefs;

  // Lazy — tidak pernah diakses di web sehingga tidak diinstansiasi di browser.
  late final GoogleSignIn _googleSignIn =
      GoogleSignIn(serverClientId: _webClientId);

  AuthService(this._prefs);

  // ── Mode Tamu ─────────────────────────────────────────────────────────────

  Future<UserEntity> signInAsGuest() async {
    const uuid = Uuid();
    final id = _prefs.getString(_keyAuthId) ?? uuid.v4();

    await _prefs.setString(_keyAuthId, id);
    await _prefs.setString(_keyAuthName, 'Tamu');
    await _prefs.setString(_keyAuthMode, 'guest');

    return UserEntity(id: id, displayName: 'Tamu', authMode: AuthMode.guest);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<UserEntity?> signInWithGoogle() async {
    const tag = 'AuthService.signInWithGoogle';
    final sw = Stopwatch()..start();
    dev.log(
      '▶ [${DateTime.now().toIso8601String()}] Memulai Google Sign-In '
      '(platform: ${kIsWeb ? "web" : "native"})',
      name: tag,
    );

    try {
      final result =
          kIsWeb ? await _signInGoogleWeb(tag) : await _signInGoogleNative(tag);
      sw.stop();
      dev.log('[auth] Total signInWithGoogle: ${sw.elapsedMilliseconds}ms',
          name: tag);
      return result;
    } on fb.FirebaseAuthException catch (e, st) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        dev.log('↩ Login dibatalkan (${e.code})', name: tag);
        return null;
      }
      dev.log('✗ FirebaseAuthException: code=${e.code}',
          name: tag, level: 1000, error: e, stackTrace: st);
      throw Exception('[firebase:${e.code}] ${e.message ?? e.code}');
    } catch (e, st) {
      dev.log('✗ Exception tidak terduga: $e',
          name: tag, level: 1000, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<UserEntity?> _signInGoogleWeb(String tag) async {
    dev.log('→ [web] signInWithPopup(GoogleAuthProvider)...', name: tag);
    final cred = await fb.FirebaseAuth.instance
        .signInWithPopup(fb.GoogleAuthProvider());
    final fbUser = cred.user;
    if (fbUser == null) {
      dev.log('✗ [web] user null setelah signInWithPopup',
          name: tag, level: 1000);
      return null;
    }
    dev.log('✓ [web] uid=${fbUser.uid} email=${fbUser.email}', name: tag);
    return _persistGoogle(fbUser, tag);
  }

  Future<UserEntity?> _signInGoogleNative(String tag) async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      dev.log('⚠ GoogleSignIn.signOut() gagal (diabaikan): $e', name: tag);
    }

    final pickSw = Stopwatch()..start();
    dev.log(
        '→ [native] [${DateTime.now().toIso8601String()}] GoogleSignIn.signIn()...',
        name: tag);
    final googleAccount = await _googleSignIn.signIn();
    pickSw.stop();
    if (googleAccount == null) {
      dev.log(
          '↩ [native] signIn() null — dibatalkan (${pickSw.elapsedMilliseconds}ms)',
          name: tag);
      return null;
    }
    dev.log(
        '✓ [native] ${googleAccount.email} (${pickSw.elapsedMilliseconds}ms)',
        name: tag);

    final tokenSw = Stopwatch()..start();
    final googleAuth = await googleAccount.authentication;
    tokenSw.stop();
    dev.log('✓ [native] authentication(): ${tokenSw.elapsedMilliseconds}ms',
        name: tag);
    if (googleAuth.idToken == null) {
      const msg = 'idToken kosong — pastikan SHA-1 terdaftar di Firebase Console '
          'dan Google Sign-In diaktifkan di Authentication > Sign-in providers.';
      dev.log('✗ $msg', name: tag, level: 1000);
      throw Exception(msg);
    }

    final credSw = Stopwatch()..start();
    dev.log(
        '→ [native] [${DateTime.now().toIso8601String()}] signInWithCredential()...',
        name: tag);
    final fbCred = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred =
        await fb.FirebaseAuth.instance.signInWithCredential(fbCred);
    credSw.stop();
    final fbUser = userCred.user;
    if (fbUser == null) {
      dev.log('✗ [native] user null setelah signInWithCredential',
          name: tag, level: 1000);
      return null;
    }
    dev.log(
        '✓ [native] signInWithCredential: ${credSw.elapsedMilliseconds}ms uid=${fbUser.uid}',
        name: tag);

    final name =
        fbUser.displayName ?? googleAccount.displayName ?? 'Pengguna';
    final email = fbUser.email ?? googleAccount.email;
    return _persistGoogle(fbUser, tag,
        overrideName: name, overrideEmail: email);
  }

  // ── Email Link Sign-In ────────────────────────────────────────────────────

  /// Mengirim tautan masuk ke [email] menggunakan Firebase Email Link auth.
  ///
  /// Email disimpan sementara di SharedPreferences agar dapat digunakan saat
  /// pengguna membuka tautan dan aplikasi perlu menyelesaikan proses sign-in.
  ///
  /// Konfigurasi ActionCodeSettings:
  ///   - [url] harus cocok dengan intent filter di AndroidManifest.xml
  ///     (host: sakurapi-aa6ac.firebaseapp.com) sehingga Android mengarahkan
  ///     tautan langsung ke aplikasi tanpa melewati browser.
  ///   - [handleCodeInApp] = true: tautan ditangani in-app, bukan browser.
  ///   - [androidPackageName]: diperlukan agar Firebase menyertakan
  ///     parameter android_package_name dalam tautan dan membuka aplikasi.
  Future<void> sendEmailSignInLink(String email) async {
    const tag = 'AuthService.sendEmailSignInLink';
    dev.log('→ Mengirim email link ke $email', name: tag);

    final settings = fb.ActionCodeSettings(
      url: 'https://sakurapi-aa6ac.firebaseapp.com/finishSignIn',
      handleCodeInApp: true,
      androidPackageName: 'com.financetracker.finance_tracker',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.financetracker.financeTracker',
    );

    await fb.FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: settings,
    );

    await _prefs.setString(_keyPendingEmail, email);
    dev.log('✓ Email link terkirim, email disimpan di pending', name: tag);
  }

  /// Memeriksa apakah [link] adalah URI tautan masuk email yang valid dari Firebase.
  bool isSignInWithEmailLink(String link) =>
      fb.FirebaseAuth.instance.isSignInWithEmailLink(link);

  /// Menyelesaikan proses sign-in menggunakan [email] dan [link] yang diterima.
  ///
  /// Dipanggil oleh [AuthNotifier.handleEmailLink] setelah URI deep link diterima.
  Future<UserEntity?> signInWithEmailLink(String email, String link) async {
    const tag = 'AuthService.signInWithEmailLink';
    dev.log('→ Menyelesaikan email link sign-in untuk $email', name: tag);

    try {
      final fbCred = fb.EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: link,
      );
      final userCred =
          await fb.FirebaseAuth.instance.signInWithCredential(fbCred);
      final fbUser = userCred.user;
      if (fbUser == null) {
        dev.log('✗ user null setelah signInWithCredential (email link)',
            name: tag, level: 1000);
        return null;
      }

      await _clearPendingEmail();
      dev.log('✓ Email link sign-in berhasil: uid=${fbUser.uid}', name: tag);
      return _persistEmailLink(fbUser, email, tag);
    } on fb.FirebaseAuthException catch (e, st) {
      dev.log('✗ FirebaseAuthException: code=${e.code}',
          name: tag, level: 1000, error: e, stackTrace: st);
      throw Exception('[firebase:${e.code}] ${e.message ?? e.code}');
    }
  }

  /// Email yang sedang menunggu verifikasi tautan masuk, atau null.
  String? getPendingEmail() => _prefs.getString(_keyPendingEmail);

  Future<void> _clearPendingEmail() => _prefs.remove(_keyPendingEmail);

  // ── Perbarui Profil ───────────────────────────────────────────────────────

  /// Memperbarui nama tampilan di Firebase Auth dan SharedPreferences.
  Future<UserEntity?> updateDisplayName(String name) async {
    const tag = 'AuthService.updateDisplayName';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    try {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await fbUser.updateDisplayName(trimmed);
        dev.log('✓ Firebase displayName diperbarui: $trimmed', name: tag);
      }
    } catch (e) {
      dev.log('⚠ Gagal update Firebase displayName (diabaikan): $e',
          name: tag);
    }

    await _prefs.setString(_keyAuthName, trimmed);
    return getCurrentUser();
  }

  // ── Sesi Aktif ────────────────────────────────────────────────────────────

  Future<UserEntity?> getCurrentUser() async {
    final id = _prefs.getString(_keyAuthId);
    final name = _prefs.getString(_keyAuthName);
    final modeStr = _prefs.getString(_keyAuthMode);

    if (id == null || name == null || modeStr == null) return null;

    final mode = switch (modeStr) {
      'google' => AuthMode.google,
      'emailLink' => AuthMode.emailLink,
      _ => AuthMode.guest,
    };

    final email =
        (mode != AuthMode.guest) ? _prefs.getString(_keyAuthEmail) : null;

    return UserEntity(
      id: id,
      displayName: name,
      email: email,
      authMode: mode,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final mode = _prefs.getString(_keyAuthMode);

    if (mode == 'google' || mode == 'emailLink') {
      try {
        await fb.FirebaseAuth.instance.signOut();
        if (!kIsWeb && mode == 'google') {
          await _googleSignIn.signOut();
        }
      } catch (_) {}
    }

    await _prefs.remove(_keyAuthId);
    await _prefs.remove(_keyAuthName);
    await _prefs.remove(_keyAuthEmail);
    await _prefs.remove(_keyAuthMode);
  }

  // ── Helpers (publik) ──────────────────────────────────────────────────────

  String? getCurrentUserId() => _prefs.getString(_keyAuthId);
  bool get isGoogleUser => _prefs.getString(_keyAuthMode) == 'google';
  bool get isEmailLinkUser => _prefs.getString(_keyAuthMode) == 'emailLink';
  bool get isGuestUser => _prefs.getString(_keyAuthMode) == 'guest';

  // ── Private builders ──────────────────────────────────────────────────────

  Future<UserEntity> _persistGoogle(
    fb.User fbUser,
    String tag, {
    String? overrideName,
    String? overrideEmail,
  }) async {
    final id = fbUser.uid;
    final name = overrideName ?? fbUser.displayName ?? 'Pengguna';
    final email = overrideEmail ?? fbUser.email ?? '';
    final photoUrl = fbUser.photoURL;

    await _prefs.setString(_keyAuthId, id);
    await _prefs.setString(_keyAuthName, name);
    await _prefs.setString(_keyAuthEmail, email);
    await _prefs.setString(_keyAuthMode, 'google');
    dev.log('✓ Sesi Google tersimpan (uid=$id)', name: tag);

    return UserEntity(
      id: id,
      displayName: name,
      email: email,
      photoUrl: photoUrl,
      authMode: AuthMode.google,
    );
  }

  Future<UserEntity> _persistEmailLink(
    fb.User fbUser,
    String email,
    String tag,
  ) async {
    final id = fbUser.uid;
    // Gunakan displayName Firebase jika ada; fallback ke bagian lokal email.
    final name = (fbUser.displayName?.isNotEmpty == true)
        ? fbUser.displayName!
        : email.split('@').first;

    await _prefs.setString(_keyAuthId, id);
    await _prefs.setString(_keyAuthName, name);
    await _prefs.setString(_keyAuthEmail, email);
    await _prefs.setString(_keyAuthMode, 'emailLink');
    dev.log('✅ Email Link Sign-In berhasil: $email (uid=$id, nama=$name)',
        name: tag);

    return UserEntity(
      id: id,
      displayName: name,
      email: email,
      authMode: AuthMode.emailLink,
    );
  }
}
