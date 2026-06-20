import '../entities/payment.dart';

abstract class PaymentRepository {
  Stream<List<Payment>> watchPendingPayments();
  Future<void> clearCheck(String paymentId);
  Future<void> rejectCheck(String paymentId);
}
