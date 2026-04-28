// test/unit/sync/sync_availability_test.dart
//
// Unit tests untuk SyncService.isAvailable.
//
// Covers:
//   - Guest mode → isAvailable == false
//   - Google mode → isAvailable == true
//   - Email Link mode → isAvailable == true
//   - Tidak ada userId (belum login) → isAvailable == false meski mode != guest
//   - Tidak ada mode (key tidak ada) → isAvailable == false
//   - Perubahan prefs langsung tercermin (lazy evaluation)
//
// Run: flutter test test/unit/sync/sync_availability_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finance_tracker/core/services/sync_service.dart';

// Firestore tidak digunakan di isAvailable — mock hanya agar konstruktor
// tidak memanggil FirebaseFirestore.instance (yang butuh Firebase.initializeApp).
class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late SharedPreferences prefs;
  late FirebaseFirestore fakeFirestore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeFirestore = _MockFirestore();
  });

  SyncService makeService() =>
      SyncService(firestore: fakeFirestore, prefs: prefs);

  // ── Guest ──────────────────────────────────────────────────────────────────

  group('SyncService.isAvailable — guest', () {
    test('false saat mode guest dengan userId ada', () async {
      await prefs.setString('saku_auth_id', 'guest-uuid-123');
      await prefs.setString('saku_auth_mode', 'guest');

      expect(makeService().isAvailable, isFalse);
    });

    test('false saat mode guest tanpa userId', () async {
      await prefs.setString('saku_auth_mode', 'guest');

      expect(makeService().isAvailable, isFalse);
    });
  });

  // ── Google ─────────────────────────────────────────────────────────────────

  group('SyncService.isAvailable — google', () {
    test('true saat mode google dengan userId ada', () async {
      await prefs.setString('saku_auth_id', 'google-uid-456');
      await prefs.setString('saku_auth_mode', 'google');

      expect(makeService().isAvailable, isTrue);
    });

    test('false saat mode google tapi userId tidak ada', () async {
      await prefs.setString('saku_auth_mode', 'google');

      expect(makeService().isAvailable, isFalse);
    });
  });

  // ── Email Link ─────────────────────────────────────────────────────────────

  group('SyncService.isAvailable — emailLink', () {
    test('true saat mode emailLink dengan userId ada', () async {
      await prefs.setString('saku_auth_id', 'el-uid-789');
      await prefs.setString('saku_auth_mode', 'emailLink');

      expect(makeService().isAvailable, isTrue);
    });

    test('false saat mode emailLink tapi userId tidak ada', () async {
      await prefs.setString('saku_auth_mode', 'emailLink');

      expect(makeService().isAvailable, isFalse);
    });
  });

  // ── Tidak ada mode ─────────────────────────────────────────────────────────

  group('SyncService.isAvailable — mode tidak terdefinisi', () {
    test('false saat key saku_auth_mode tidak ada', () async {
      await prefs.setString('saku_auth_id', 'some-uid');
      // sengaja tidak set saku_auth_mode

      expect(makeService().isAvailable, isFalse);
    });

    test('false saat prefs kosong (belum login)', () {
      expect(makeService().isAvailable, isFalse);
    });
  });

  // ── Lazy evaluation ────────────────────────────────────────────────────────

  group('SyncService.isAvailable — lazy (membaca prefs setiap panggilan)', () {
    test('berubah dari false ke true saat login Google tanpa recreate service',
        () async {
      final service = makeService();

      // Sebelum login
      expect(service.isAvailable, isFalse);

      // Simulasi login Google
      await prefs.setString('saku_auth_id', 'google-uid-new');
      await prefs.setString('saku_auth_mode', 'google');

      // Setelah login — instance sama, prefs sudah berubah
      expect(service.isAvailable, isTrue);
    });

    test('berubah dari true ke false saat logout', () async {
      await prefs.setString('saku_auth_id', 'google-uid-existing');
      await prefs.setString('saku_auth_mode', 'google');

      final service = makeService();
      expect(service.isAvailable, isTrue);

      // Simulasi logout
      await prefs.remove('saku_auth_id');
      await prefs.remove('saku_auth_mode');

      expect(service.isAvailable, isFalse);
    });

    test('beralih dari google ke emailLink — tetap true', () async {
      await prefs.setString('saku_auth_id', 'uid-switch');
      await prefs.setString('saku_auth_mode', 'google');

      final service = makeService();
      expect(service.isAvailable, isTrue);

      // Ganti mode ke emailLink (misal migrasi akun)
      await prefs.setString('saku_auth_mode', 'emailLink');

      expect(service.isAvailable, isTrue);
    });
  });
}
