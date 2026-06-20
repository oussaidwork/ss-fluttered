import '../entities/sale.dart';
import '../entities/sale_item.dart';

abstract class SaleRepository {
  Future<void> recordSale({
    required Sale sale,
    required List<SaleItem> items,
  });

  Stream<List<Sale>> watchTodaySales();
  Stream<List<Sale>> watchAllSales();
}
