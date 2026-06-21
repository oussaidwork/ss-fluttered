import 'package:cloud_firestore/cloud_firestore.dart';

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

    final saleRef = _ds.docRef(FirestorePaths.sales, sale.id);
    batch.set(saleRef, sale.toMap());

    for (final item in items) {
      final itemRef = _ds.docRef(
        '${FirestorePaths.sales}/${sale.id}/items',
        item.id,
      );
      batch.set(itemRef, item.toMap());
    }

    if (sale.saleType == SaleType.fuel && sale.gasTypeId != null) {
      final pitSnap = await _ds.queryMulti(
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

        batch.update(pitDoc.reference, {
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

    return _ds.streamQueryMulti(
      FirestorePaths.sales,
      filters: [
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(startOfDay),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(endOfDay),
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
    return _ds.streamQueryMulti(
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
