/// Payment lifecycle statuses.
enum PaymentStatus {
  pending('PENDING'),
  completed('COMPLETED'),
  rejected('REJECTED'),
  cancelled('CANCELLED');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String status) {
    return PaymentStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => PaymentStatus.pending,
    );
  }

  bool get isSettled => this == completed || this == rejected || this == cancelled;
  bool get isPending => this == pending;
}