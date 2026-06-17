/// Types of sales.
enum SaleType {
  fuel('FUEL'),
  product('PRODUCT'),
  service('SERVICE');

  final String value;
  const SaleType(this.value);

  static SaleType fromString(String type) {
    return SaleType.values.firstWhere(
      (s) => s.value == type,
      orElse: () => SaleType.fuel,
    );
  }
}