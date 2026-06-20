import '../entities/supplier.dart';

abstract class SupplierRepository {
  Stream<List<Supplier>> watchSuppliers();
  Future<void> createSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
}
