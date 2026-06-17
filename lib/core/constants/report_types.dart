/// Report type definitions.
enum ReportType {
  pumpIndexes('Pump Indexes Report'),
  sales('Sales Report'),
  debts('Debts Report'),
  paymentsSettlement('Payments Settlement Report'),
  pitRefill('Pit Refill Report'),
  fuelPriceHistory('Fuel Price History Report'),
  auditLog('Audit Log Report'),
  shiftSummary('Shift Summary Report');

  final String displayName;
  const ReportType(this.displayName);

  String get routeName => name;
}