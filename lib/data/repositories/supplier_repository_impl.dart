import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl._();
  static final _instance = SupplierRepositoryImpl._();
  factory SupplierRepositoryImpl() => _instance;

  @override
  Stream<List<Supplier>> watchSuppliers() {
    return firestore
        .collection(FirestorePaths.fuelSuppliers)
        .where('isDeleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Supplier.fromMap(d.data()))
              .toList(),
        );
  }

  @override
  Future<void> createSupplier(Supplier supplier) async {
    await firestore
        .collection(FirestorePaths.fuelSuppliers)
        .doc(supplier.id)
        .set(supplier.toMap());
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    await firestore
        .collection(FirestorePaths.fuelSuppliers)
        .doc(supplier.id)
        .update(supplier.toMap());
  }
}

final supplierRepository = SupplierRepositoryImpl();
