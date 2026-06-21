import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sale_item.dart';
import 'repository_providers.dart';

final saleItemsBySaleProvider = StreamProvider.family<List<SaleItem>, String>((ref, saleId) {
  return ref.watch(saleItemRepositoryProvider).watchSaleItemsBySale(saleId);
});

final allSaleItemsProvider = StreamProvider<List<SaleItem>>((ref) {
  return ref.watch(saleItemRepositoryProvider).watchAllSaleItems();
});
