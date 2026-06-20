import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/sale_item.dart';

final saleItemsBySaleProvider = StreamProvider.family<List<SaleItem>, String>((ref, saleId) {
  return firestore.collection('saleItems').where('saleId', isEqualTo: saleId).snapshots().map(
    (snap) => snap.docs.map((d) => SaleItem.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final allSaleItemsProvider = StreamProvider<List<SaleItem>>((ref) {
  return firestore.collection('saleItems').orderBy('timestamp', descending: true).snapshots().map(
    (snap) => snap.docs.map((d) => SaleItem.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
