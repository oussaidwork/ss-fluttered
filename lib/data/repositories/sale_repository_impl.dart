import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/enums/sale_type.dart';
import '../../domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  final DatabaseDataSource _ds;

  SaleRepositoryImpl(this._ds);

  @override
  Future<void> recordSale({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    final batch = _ds.batch();

    batch.set(FirestorePaths.sales, sale.id, sale.toMap());

    for (final item in items) {
      batch.set(
        '${FirestorePaths.sales}/${sale.id}/items',
        item.id,
        item.toMap(),
      );
    }

    if (sale.saleType == SaleType.fuel && sale.gasTypeId != null) {
      final pitSnap = await _ds.query(
        FirestorePaths.pits,
        filters: [
          QueryFilter(field: 'gasTypeId', value: sale.gasTypeId),
          QueryFilter(field: 'isDeleted', value: false),
        ],
        limit: 1,
      );

      if (pitSnap.docs.isNotEmpty) {
        final pitDoc = pitSnap.docs.first;
        final pitData = pitDoc.data() as Map<String, dynamic>;
        final currentVolume =
            (pitData['currentVolume'] as num?)?.toDouble() ?? 0;
        final volumeSold = sale.volume ?? 0;
        final newVolume = currentVolume - volumeSold;

        batch.update(FirestorePaths.pits, pitDoc.id, {
          'currentVolume': newVolume < 0 ? 0 : newVolume,
        });
      }
    }

    await batch.commit();
  }

  @override
  Stream<List<Sale>> watchTodaySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _ds.streamQuery(
      FirestorePaths.sales,
      filters: [
        QueryFilter(
          field: 'timestamp',
          value: startOfDay.toIso8601String(),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'timestamp',
          value: endOfDay.toIso8601String(),
          operator: FilterOperator.isLessThan,
        ),
        QueryFilter(field: 'isDeleted', value: false),
      ],
      orderByField: 'timestamp',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => Sale.fromMap(
              d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Stream<List<Sale>> watchAllSales() {
    return _ds.streamQuery(
      FirestorePaths.sales,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
      orderByField: 'timestamp',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => Sale.fromMap(
              d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }
}
