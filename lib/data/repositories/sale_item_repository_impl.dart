import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/repositories/sale_item_repository.dart';

class SaleItemRepositoryImpl implements SaleItemRepository {
  final DatabaseDataSource _ds;

  SaleItemRepositoryImpl(this._ds);

  @override
  Stream<List<SaleItem>> watchSaleItemsBySale(String saleId) {
    return _ds.streamQuery(
      FirestorePaths.saleItems,
      filters: [QueryFilter(field: 'saleId', value: saleId)],
    ).map((snap) => snap.docs.map((d) => SaleItem.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Stream<List<SaleItem>> watchAllSaleItems() {
    return _ds.streamQuery(
      FirestorePaths.saleItems,
      orderByField: 'timestamp',
      orderByDescending: true,
    ).map((snap) => snap.docs.map((d) => SaleItem.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<List<SaleItem>> getSaleItemsBySale(String saleId) async {
    final snap = await _ds.query(
      FirestorePaths.saleItems,
      filters: [QueryFilter(field: 'saleId', value: saleId)],
    );
    return snap.docs.map((d) => SaleItem.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList();
  }
}
