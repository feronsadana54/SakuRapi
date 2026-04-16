/// 30 Indonesian personal finance quotes, rotated by day-of-year.
/// No network needed — fully offline.
abstract final class FinanceQuotes {
  static const List<String> quotes = [
    '"Jangan menabung apa yang tersisa setelah pengeluaran, tapi keluarkan apa yang tersisa setelah menabung." — Warren Buffett',
    '"Orang kaya membeli aset. Orang miskin membeli liabilitas." — Robert Kiyosaki',
    '"Investasi terbaik yang bisa kamu lakukan adalah investasi pada dirimu sendiri." — Benjamin Franklin',
    '"Hargai setiap rupiah yang kamu miliki, karena rupiah-rupiah kecil membentuk jutaan."',
    '"Mengatur keuangan bukan tentang seberapa banyak yang kamu hasilkan, tapi seberapa bijak kamu mengelolanya."',
    '"Mulailah menabung hari ini. Bukan besok, bukan minggu depan."',
    '"Pengeluaran kecil yang tidak tercatat adalah bocoran besar dalam keuanganmu."',
    '"Kebebasan finansial bukan tentang menjadi kaya, tapi tentang tidak khawatir soal uang."',
    '"Setiap perjalanan seribu mil dimulai dari satu langkah. Setiap kekayaan dimulai dari satu tabungan."',
    '"Belanja untuk kebutuhan, bukan untuk keinginan."',
    '"Orang yang bijak mempersiapkan masa depan. Orang yang gegabah hanya memikirkan hari ini."',
    '"Dana darurat bukan kemewahan, melainkan kebutuhan."',
    '"Anggaran adalah bukan tentang membatasi diri, tapi tentang membuat impianmu nyata."',
    '"Waktu adalah aset paling berharga dalam investasi. Mulailah sedini mungkin."',
    '"Kebiasaan finansial yang baik hari ini adalah investasi untuk ketenangan esok hari."',
    '"Satu cangkir kopi sehari yang tidak tercatat bisa menguras ratusan ribu dalam setahun."',
    '"Kenali perbedaan antara harga dan nilai. Murah belum tentu bernilai."',
    '"Disiplin keuangan adalah otot. Semakin sering dilatih, semakin kuat."',
    '"Jangan biarkan gaya hidup mengalahkan pendapatan."',
    '"Mencatat pengeluaran adalah langkah pertama menuju kebebasan finansial."',
    '"Uang adalah alat. Gunakan dengan bijak, bukan sebagai tujuan akhir."',
    '"Hidup hemat bukan berarti pelit, melainkan cerdas dalam prioritas."',
    '"Setiap rupiah yang kamu kelola dengan baik adalah langkah menuju impian besarmu."',
    '"Kesuksesan finansial adalah hasil dari ribuan keputusan kecil yang tepat."',
    '"Catat semua. Analisis selalu. Perbaiki terus."',
    '"Impian tanpa rencana keuangan hanyalah angan-angan."',
    '"Lebih baik mengatur pengeluaran daripada mencari penghasilan tambahan."',
    '"Kunci kekayaan bukan berapa yang kamu hasilkan, tapi berapa yang kamu simpan."',
    '"Keuangan yang sehat dimulai dari kebiasaan mencatat setiap hari."',
    '"Hutang adalah perbudakan dengan persetujuan sendiri. Bebaskan dirimu."',
  ];

  /// Index of today's quote — deterministic, changes daily.
  static int get todayIndex {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return dayOfYear % quotes.length;
  }

  /// Returns today's quote — deterministic, changes daily, no network needed.
  static String getTodayQuote() => quotes[todayIndex];
}
