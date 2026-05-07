// test/unit/sync/background_sync_coordinator_test.dart
//
// Unit tests untuk BackgroundSyncCoordinator.
//
// Covers:
//   - start() memulai timer dan listener (idempoten).
//   - stop() membersihkan semua resource.
//   - didChangeAppLifecycleState(resumed) memicu sync.
//   - sync ditolak jika dipanggil < 30 detik dari sync sebelumnya.
//
// Run: flutter test test/unit/sync/background_sync_coordinator_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/services/background_sync_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundSyncCoordinator', () {
    test('start() lalu stop() — idempoten', () async {
      var calls = 0;
      final c = BackgroundSyncCoordinator((_) async => calls++);
      c.start();
      c.start(); // panggilan kedua tidak boleh duplikasi observer
      c.stop();
      c.stop(); // tidak crash
      // Tidak ada sync sintetis — calls tetap 0
      expect(calls, 0);
    });

    test('didChangeAppLifecycleState(resumed) memicu sync', () async {
      var triggered = <String>[];
      final c = BackgroundSyncCoordinator((trigger) async {
        triggered.add(trigger);
      });
      c.start();
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // Sync dijalankan secara fire-and-forget — beri 1 microtask + 1 frame
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(triggered, ['resume']);
      c.stop();
    });

    test('sync di-spam < 30 detik diabaikan', () async {
      var triggered = <String>[];
      final c = BackgroundSyncCoordinator((trigger) async {
        triggered.add(trigger);
      });
      c.start();

      // Panggilan pertama → sync
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(triggered.length, 1);

      // Panggilan kedua langsung sesudah → harusnya skip (rate-limit 30s)
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(triggered.length, 1, reason: 'sync kedua dalam 30s harus diabaikan');

      c.stop();
    });

    test('lifecycle non-resumed tidak memicu sync', () async {
      var triggered = <String>[];
      final c = BackgroundSyncCoordinator((trigger) async {
        triggered.add(trigger);
      });
      c.start();

      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      c.didChangeAppLifecycleState(AppLifecycleState.inactive);
      c.didChangeAppLifecycleState(AppLifecycleState.detached);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(triggered, isEmpty);

      c.stop();
    });
  });
}
