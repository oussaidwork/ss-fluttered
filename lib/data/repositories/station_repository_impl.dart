import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/gas_type.dart';
import '../../domain/entities/pump.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/pit.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/payment_type.dart';
import '../../domain/repositories/station_repository.dart';

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl._();
  static final _instance = StationRepositoryImpl._();
  factory StationRepositoryImpl() => _instance;

  // ── Gas Types ──────────────────────────────────────────

  @override
  Stream<List<GasType>> watchGasTypes() {
    return firestore
        .collection(FirestorePaths.gasTypes)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => GasType.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> createGasType(GasType gasType) async {
    await firestore
        .collection(FirestorePaths.gasTypes)
        .doc(gasType.id)
        .set(gasType.toMap());
  }

  @override
  Future<void> updateGasType(GasType gasType) async {
    await firestore
        .collection(FirestorePaths.gasTypes)
        .doc(gasType.id)
        .update(gasType.toMap());
  }

  @override
  Future<void> deleteGasType(String id) async {
    await firestore.collection(FirestorePaths.gasTypes).doc(id).update({
      'isDeleted': true,
    });
  }

  // ── Pits ───────────────────────────────────────────────

  @override
  Stream<List<Pit>> watchPits() {
    return firestore
        .collection(FirestorePaths.pits)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Pit.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> createPit(Pit pit) async {
    await firestore
        .collection(FirestorePaths.pits)
        .doc(pit.id)
        .set(pit.toMap());
  }

  @override
  Future<void> updatePit(Pit pit) async {
    await firestore
        .collection(FirestorePaths.pits)
        .doc(pit.id)
        .update(pit.toMap());
  }

  @override
  Future<void> deletePit(String id) async {
    await firestore.collection(FirestorePaths.pits).doc(id).update({
      'isDeleted': true,
    });
  }

  // ── Pumps ──────────────────────────────────────────────

  @override
  Stream<List<Pump>> watchPumps() {
    return firestore
        .collection(FirestorePaths.pumps)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Pump.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> createPump(Pump pump) async {
    await firestore
        .collection(FirestorePaths.pumps)
        .doc(pump.id)
        .set(pump.toMap());
  }

  @override
  Future<void> updatePump(Pump pump) async {
    await firestore
        .collection(FirestorePaths.pumps)
        .doc(pump.id)
        .update(pump.toMap());
  }

  @override
  Future<void> deletePump(String id) async {
    await firestore.collection(FirestorePaths.pumps).doc(id).update({
      'isDeleted': true,
    });
  }

  // ── Products ───────────────────────────────────────────

  @override
  Stream<List<Product>> watchProducts() {
    return firestore
        .collection(FirestorePaths.products)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> createProduct(Product product) async {
    await firestore
        .collection(FirestorePaths.products)
        .doc(product.id)
        .set(product.toMap());
  }

  @override
  Future<void> updateProduct(Product product) async {
    await firestore
        .collection(FirestorePaths.products)
        .doc(product.id)
        .update(product.toMap());
  }

  @override
  Future<void> deleteProduct(String id) async {
    await firestore.collection(FirestorePaths.products).doc(id).update({
      'isDeleted': true,
    });
  }

  // ── Services ───────────────────────────────────────────

  @override
  Stream<List<StationService>> watchServices() {
    return firestore
        .collection(FirestorePaths.services)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => StationService.fromMap(d.data()))
              .toList(),
        );
  }

  @override
  Future<void> createService(StationService service) async {
    await firestore
        .collection(FirestorePaths.services)
        .doc(service.id)
        .set(service.toMap());
  }

  @override
  Future<void> updateService(StationService service) async {
    await firestore
        .collection(FirestorePaths.services)
        .doc(service.id)
        .update(service.toMap());
  }

  @override
  Future<void> deleteService(String id) async {
    await firestore.collection(FirestorePaths.services).doc(id).update({
      'isDeleted': true,
    });
  }

  // ── Payment Types ──────────────────────────────────────

  @override
  Stream<List<PaymentType>> watchPaymentTypes() {
    return firestore
        .collection(FirestorePaths.paymentTypes)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PaymentType.fromMap(d.data()))
              .toList(),
        );
  }

  @override
  Future<void> createPaymentType(PaymentType paymentType) async {
    await firestore
        .collection(FirestorePaths.paymentTypes)
        .doc(paymentType.id)
        .set(paymentType.toMap());
  }

  @override
  Future<void> updatePaymentType(PaymentType paymentType) async {
    await firestore
        .collection(FirestorePaths.paymentTypes)
        .doc(paymentType.id)
        .update(paymentType.toMap());
  }

  @override
  Future<void> deletePaymentType(String id) async {
    await firestore
        .collection(FirestorePaths.paymentTypes)
        .doc(id)
        .delete();
  }
}

final stationRepository = StationRepositoryImpl();
