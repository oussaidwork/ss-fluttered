import '../entities/pit_refill.dart';
import '../entities/refill_payment.dart';

abstract class RefillRepository {
  Future<void> recordRefill({
    required PitRefill refill,
    RefillPayment? payment,
  });

  Stream<List<PitRefill>> watchRefills();
}
