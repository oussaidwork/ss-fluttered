import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/enums/sale_type.dart';
import '../../domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  SaleRepositoryImpl._();
  static final _instance = SaleRepositoryImpl._();
  factory SaleRepositoryImpl() => _instance;

  @override
  Future<void> recordSale({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    final batch = firestore.batch();

    final saleRef =
        firestore.collection(FirestorePaths.sales).doc(sale.id);
    batch.set(saleRef, sale.toMap());

    for (final item in items) {
      final itemRef = firestore
          .collection(FirestorePaths.sales)
          .doc(sale.id)
          .collection('items')
          .doc(item.id);
      batch.set(itemRef, item.toMap());
    }

    if (sale.saleType == SaleType.fuel && sale.gasTypeId != null) {
      final pitSnap = await firestore
          .collection(FirestorePaths.pits)
          .where('gasTypeId', isEqualTo: sale.gasTypeId)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (pitSnap.docs.isNotEmpty) {
        final pitDoc = pitSnap.docs.first;
        final currentVolume =
            (pitDoc.data()['currentVolume'] as num?)?.toDouble() ?? 0;
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

    return firestore
        .collection(FirestorePaths.sales)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Sale.fromMap(d.data())).toList(),
        );
  }

  @override
  Stream<List<Sale>> watchAllSales() {
    return firestore
        .collection(FirestorePaths.sales)
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Sale.fromMap(d.data())).toList(),
        );
  }
}

final saleRepository = SaleRepositoryImpl();
