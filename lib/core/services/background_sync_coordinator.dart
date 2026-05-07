import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';

/// Mengoordinasi sinkronisasi data ketika aplikasi berada di **foreground**.
///
/// **Strategi (jujur, sesuai batasan platform):**
///   1. **Sync saat resume**: ketika aplikasi kembali ke foreground dari
///      background, jalankan satu siklus sync.
///   2. **Sync periodik 30 menit**: Timer.periodic memicu sync selama
///      aplikasi terbuka.
///   3. **Sync terjadwal harian (default 22:00)**: Timer one-shot dijadwalkan
///      ke jam target berikutnya. Hanya berfungsi bila aplikasi dalam keadaan
///      *terbuka atau di background-nya masih hidup* pada jam tersebut.
///
/// **Yang TIDAK dijamin dan kenapa:**
///   - **Aplikasi force-stop / swipe-away dari recent apps**: OS Android
///     mematikan timer di proses tersebut. Tidak ada cara untuk membangkitkan
///     proses kembali tanpa `WorkManager` (plugin tambahan) atau notifikasi
///     yang ditekan pengguna.
///   - **Pembatasan baterai OEM** (Xiaomi MIUI, Samsung One UI, Huawei,
///     Oppo/Realme, Vivo): vendor sering menonaktifkan job background secara
///     agresif. Bahkan dengan WorkManager pun bisa gagal.
///   - **Reboot perangkat**: timer hilang bersama proses. Hanya BootReceiver
///     `flutter_local_notifications` yang otomatis menjadwalkan ulang
///     notifikasi (bukan sync). Sync akan dipulihkan saat aplikasi dibuka lagi.
///   - **Uninstall**: tidak ada hook "before uninstall" di Android. Strategi
///     terbaik adalah **sync setiap kali ada perubahan** (sudah dilakukan oleh
///     repository) + sync sebelum logout — sehingga risiko kehilangan
///     data minimal.
///
/// **Mitigasi:** [AuthNotifier.runFullSync] dipanggil di banyak titik — login,
/// startup dengan sesi, resume, periodik, terjadwal — sehingga data hampir
/// selalu konsisten antara perangkat saat pengguna aktif.
class BackgroundSyncCoordinator with WidgetsBindingObserver {
  final Future<void> Function(String trigger) _onSync;

  Timer? _periodicTimer;
  Timer? _dailyTimer;
  DateTime _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _started = false;

  /// Interval minimum antar sync agar tidak boros jaringan.
  static const _minSyncSpacing = Duration(seconds: 30);

  /// Interval Timer.periodic.
  static const _periodicInterval = Duration(minutes: 30);

  /// Jam target untuk sync harian terjadwal (Asia/Jakarta).
  static const int dailyHour = 22;
  static const int dailyMinute = 0;

  static const _tag = 'BackgroundSyncCoordinator';

  BackgroundSyncCoordinator(this._onSync);

  /// Mulai mendengarkan lifecycle + memulai timer periodik dan harian.
  /// Idempoten — aman dipanggil berkali-kali.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _periodicTimer?.cancel();
    _periodicTimer =
        Timer.periodic(_periodicInterval, (_) => _trySync('periodic-30m'));
    _scheduleNextDaily();
    dev.log(
      'Coordinator aktif — periodic ${_periodicInterval.inMinutes}m, '
      'jadwal harian $dailyHour:$dailyMinute',
      name: _tag,
    );
  }

  /// Hentikan semua timer dan listener lifecycle.
  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    _dailyTimer?.cancel();
    _periodicTimer = null;
    _dailyTimer = null;
    dev.log('Coordinator dihentikan', name: _tag);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trySync('resume');
    }
  }

  void _scheduleNextDaily() {
    _dailyTimer?.cancel();
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, dailyHour, dailyMinute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    final delay = next.difference(now);
    _dailyTimer = Timer(delay, () {
      _trySync('scheduled-$dailyHour:${dailyMinute.toString().padLeft(2, '0')}');
      _scheduleNextDaily();
    });
    dev.log(
      'Sync terjadwal berikutnya: $next (selisih ${delay.inMinutes}m)',
      name: _tag,
    );
  }

  Future<void> _trySync(String trigger) async {
    final now = DateTime.now();
    if (now.difference(_lastSyncAt) < _minSyncSpacing) {
      dev.log(
        '[$trigger] dilewati — terakhir sync ${now.difference(_lastSyncAt).inSeconds}s lalu',
        name: _tag,
      );
      return;
    }
    _lastSyncAt = now;
    try {
      await _onSync(trigger);
    } catch (e) {
      dev.log('[$trigger] error (non-fatal): $e', name: _tag, level: 900);
    }
  }
}
