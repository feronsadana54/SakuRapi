# Changelog

Semua perubahan signifikan pada proyek ini didokumentasikan di sini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2026-04-16

### Ditambahkan

- Pencatatan transaksi pemasukan dan pengeluaran
- 15 kategori bawaan: 10 pengeluaran + 5 pemasukan
- Laporan dalam 5 rentang waktu: Harian, Bulanan, Tahunan, Rentang Tanggal, Siklus Gajian
- Ringkasan saldo dan transaksi terbaru di layar beranda
- Pengingat harian yang dapat dikonfigurasi per hari dan jam (default: 21:00 WIB, setiap hari)
- Pemilih hari dalam seminggu untuk pengingat (chip Senin–Minggu)
- 30 kutipan keuangan motivasi yang berputar setiap hari (tanpa jaringan)
- Ekspor data ke CSV via share sheet
- Impor data dari CSV via file picker
- Kalkulasi siklus gajian (tanggal gajian 1–31, menangani batas bulan)
- UI responsif untuk ponsel dan tablet (NavigationRail di tablet)
- Onboarding 3 langkah dengan pengaturan tanggal gajian awal
- Ikon launcher kustom (DompetKu branding)
- Dukungan platform: Android, iOS, Web
- Dukungan platform web (in-memory database, notifikasi dinonaktifkan di web)
- Arsitektur Clean Architecture (Domain / Data / Presentation)
- 51 unit test, 0 kegagalan
