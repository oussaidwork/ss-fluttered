/// Expense categories.
enum ExpenseCategory {
  supplies('SUPPLIES'),
  maintenance('MAINTENANCE'),
  salary('SALARY'),
  utilities('UTILITIES'),
  rent('RENT'),
  transport('TRANSPORT'),
  other('OTHER');

  final String value;
  const ExpenseCategory(this.value);

  static ExpenseCategory fromString(String category) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.value == category,
      orElse: () => ExpenseCategory.other,
    );
  }
}