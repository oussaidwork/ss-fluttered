/// Salary advance statuses.
enum AdvanceStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  final String value;
  const AdvanceStatus(this.value);

  static AdvanceStatus fromString(String status) {
    return AdvanceStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => AdvanceStatus.pending,
    );
  }
}