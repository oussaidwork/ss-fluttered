import '../entities/sale_item.dart';

abstract class SaleItemRepository {
  Stream<List<SaleItem>> watchSaleItemsBySale(String saleId);
  Stream<List<SaleItem>> watchAllSaleItems();
  Future<List<SaleItem>> getSaleItemsBySale(String saleId);
}
