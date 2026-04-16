enum TransactionType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  final String value;
  final String label;
  const TransactionType(this.value, this.label);

  static TransactionType fromValue(String value) =>
      values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError('Unknown TransactionType: $value'));
}
