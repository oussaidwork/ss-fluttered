/// Revenue calculation utilities for reports and dashboard metrics.
class RevenueUtils {
  RevenueUtils._();

  /// Sums a field across a list of objects.
  static double sumField<T>(List<T> items, double Function(T) field) {
    return items.fold<double>(0.0, (sum, item) => sum + (field(item) ?? 0.0));
  }

  /// Filters fuel sales from a list and returns total volume and revenue.
  static ({double volume, double revenue}) fuelSales(
    List<dynamic> sales, {
    required String saleTypeField,
    required String volumeField,
    required String totalPriceField,
  }) {
    double volume = 0;
    double revenue = 0;
    for (final sale in sales) {
      if (sale[saleTypeField] == 'FUEL') {
        volume += (sale[volumeField] as num?)?.toDouble() ?? 0.0;
        revenue += (sale[totalPriceField] as num?)?.toDouble() ?? 0.0;
      }
    }
    return (volume: volume, revenue: revenue);
  }

  /// Filters product sales and returns total count and revenue.
  static ({int count, double revenue}) productSales(
    List<dynamic> sales, {
    required String saleTypeField,
    required String totalPriceField,
  }) {
    int count = 0;
    double revenue = 0;
    for (final sale in sales) {
      if (sale[saleTypeField] == 'PRODUCT') {
        count++;
        revenue += (sale[totalPriceField] as num?)?.toDouble() ?? 0.0;
      }
    }
    return (count: count, revenue: revenue);
  }
}