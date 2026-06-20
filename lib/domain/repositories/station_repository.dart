import '../entities/gas_type.dart';
import '../entities/pit.dart';
import '../entities/pump.dart';
import '../entities/product.dart';
import '../entities/service.dart';
import '../entities/payment_type.dart';

abstract class StationRepository {
  // ── GasTypes ──────────────────────────────────────────
  Stream<List<GasType>> watchGasTypes();
  Future<void> createGasType(GasType gasType);
  Future<void> updateGasType(GasType gasType);
  Future<void> deleteGasType(String id);

  // ── Pits ──────────────────────────────────────────────
  Stream<List<Pit>> watchPits();
  Future<void> createPit(Pit pit);
  Future<void> updatePit(Pit pit);
  Future<void> deletePit(String id);

  // ── Pumps ─────────────────────────────────────────────
  Stream<List<Pump>> watchPumps();
  Future<void> createPump(Pump pump);
  Future<void> updatePump(Pump pump);
  Future<void> deletePump(String id);

  // ── Products ──────────────────────────────────────────
  Stream<List<Product>> watchProducts();
  Future<void> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);

  // ── Services ──────────────────────────────────────────
  Stream<List<StationService>> watchServices();
  Future<void> createService(StationService service);
  Future<void> updateService(StationService service);
  Future<void> deleteService(String id);

  // ── PaymentTypes ──────────────────────────────────────
  Stream<List<PaymentType>> watchPaymentTypes();
  Future<void> createPaymentType(PaymentType paymentType);
  Future<void> updatePaymentType(PaymentType paymentType);
  Future<void> deletePaymentType(String id);
}
