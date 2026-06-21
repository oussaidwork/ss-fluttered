import '../entities/sale.dart';

/// Aggregated dashboard metrics from real data.
class DashboardMetrics {
  final double totalFuelVolume;
  final double totalFuelRevenue;
  final int totalProductCount;
  final double totalProductRevenue;
  final int pendingPaymentsCount;
  final double pendingPaymentsAmount;
  final List<Sale> recentSales;
  final List<DailySalePoint> dailyTrend;
  final List<FuelSaleBreakdown> fuelBreakdown;
  final List<PaymentMethodBreakdown> paymentBreakdown;
  final double totalExpenses;
  final int activeShifts;
  final int totalClients;
  final List<ExpenseCategoryBreakdown> expenseBreakdown;
  final List<ShiftPerformancePoint> shiftPerformance;

  const DashboardMetrics({
    this.totalFuelVolume = 0,
    this.totalFuelRevenue = 0,
    this.totalProductCount = 0,
    this.totalProductRevenue = 0,
    this.pendingPaymentsCount = 0,
    this.pendingPaymentsAmount = 0,
    this.recentSales = const [],
    this.dailyTrend = const [],
    this.fuelBreakdown = const [],
    this.paymentBreakdown = const [],
    this.totalExpenses = 0,
    this.activeShifts = 0,
    this.totalClients = 0,
    this.expenseBreakdown = const [],
    this.shiftPerformance = const [],
  });
}

class DailySalePoint {
  final DateTime date;
  final double total;
  const DailySalePoint({required this.date, required this.total});
}

class FuelSaleBreakdown {
  final String label;
  final double volume;
  final double revenue;
  const FuelSaleBreakdown({
    required this.label,
    required this.volume,
    required this.revenue,
  });
}

class PaymentMethodBreakdown {
  final String method;
  final double amount;
  const PaymentMethodBreakdown({required this.method, required this.amount});
}

class ExpenseCategoryBreakdown {
  final String category;
  final double amount;
  const ExpenseCategoryBreakdown({required this.category, required this.amount});
}

class ShiftPerformancePoint {
  final DateTime date;
  final double expectedCash;
  final double actualCash;
  final String shiftId;
  const ShiftPerformancePoint({
    required this.date,
    required this.expectedCash,
    required this.actualCash,
    required this.shiftId,
  });
}

abstract class DashboardRepository {
  Future<DashboardMetrics> getDashboardMetrics();
}
