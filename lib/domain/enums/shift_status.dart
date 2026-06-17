/// Work shift statuses.
enum ShiftStatus {
  open('OPEN'),
  closed('CLOSED');

  final String value;
  const ShiftStatus(this.value);

  static ShiftStatus fromString(String status) {
    return ShiftStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => ShiftStatus.closed,
    );
  }
}