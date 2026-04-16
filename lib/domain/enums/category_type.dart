enum CategoryType {
  income('income'),
  expense('expense'),
  both('both');

  final String value;
  const CategoryType(this.value);

  static CategoryType fromValue(String value) =>
      values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError('Unknown CategoryType: $value'));
}
