import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/dashboard_repository.dart';
import 'repository_providers.dart';

// Re-export domain types for convenience
export '../../domain/repositories/dashboard_repository.dart'
    show
        DashboardMetrics,
        DailySalePoint,
        FuelSaleBreakdown,
        PaymentMethodBreakdown,
        ExpenseCategoryBreakdown,
        ShiftPerformancePoint;

final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboardMetrics();
});
