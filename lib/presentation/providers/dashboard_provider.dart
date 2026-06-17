import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/sale.dart';

class DashboardMetrics {
  final double totalFuelVolume;
  final double totalFuelRevenue;
  final int totalProductCount;
  final double totalProductRevenue;
  final int pendingPaymentsCount;
  final double pendingPaymentsAmount;
  final List<Sale> recentSales;

  const DashboardMetrics({
    this.totalFuelVolume = 0,
    this.totalFuelRevenue = 0,
    this.totalProductCount = 0,
    this.totalProductRevenue = 0,
    this.pendingPaymentsCount = 0,
    this.pendingPaymentsAmount = 0,
    this.recentSales = const [],
  });
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  return const DashboardMetrics(
    totalFuelVolume: 1250.5,
    totalFuelRevenue: 13405.36,
    totalProductCount: 87,
    totalProductRevenue: 4350.00,
    pendingPaymentsCount: 5,
    pendingPaymentsAmount: 2100.00,
    recentSales: [],
  );
});
