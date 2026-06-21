import '../entities/payment_type.dart';

abstract class PaymentTypeRepository {
  Stream<List<PaymentType>> watchPaymentTypes();
  Future<PaymentType?> getPaymentType(String id);
  Future<void> createPaymentType(PaymentType paymentType);
  Future<void> updatePaymentType(PaymentType paymentType);
}
