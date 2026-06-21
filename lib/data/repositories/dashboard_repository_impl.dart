import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DatabaseDataSource _ds;

  DashboardRepositoryImpl(this._ds);

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final todayStart = DateTime(now.year, now.month, now.day);

    // Parallel queries for performance
    final results = await Future.wait([
      // All sales (for aggregates)
      _ds.query(
        FirestorePaths.sales,
        filters: [QueryFilter(field: 'isDeleted', value: false)],
      ),
      // Recent 7 days sales (for trend)
      _ds.query(
        FirestorePaths.sales,
        filters: [
          QueryFilter(field: 'isDeleted', value: false),
          QueryFilter(
            field: 'timestamp',
            value: sevenDaysAgo.toIso8601String(),
            operator: FilterOperator.isGreaterThanOrEqualTo,
          ),
        ],
        orderByField: 'timestamp',
      ),
      // Sale items for fuel breakdown
      _ds.query(
        FirestorePaths.saleItems,
        filters: [
          QueryFilter(field: 'saleType', value: 'FUEL'),
          QueryFilter(
            field: 'timestamp',
            value: todayStart.toIso8601String(),
            operator: FilterOperator.isGreaterThanOrEqualTo,
          ),
        ],
      ),
      // Pending payments
      _ds.query(
        FirestorePaths.payments,
        filters: [
          QueryFilter(field: 'isDeleted', value: false),
          QueryFilter(field: 'status', value: 'PENDING'),
        ],
      ),
      // All completed payments for method breakdown
      _ds.query(
        FirestorePaths.payments,
        filters: [
          QueryFilter(field: 'isDeleted', value: false),
          QueryFilter(field: 'status', value: 'COMPLETED'),
        ],
      ),
      // Recent 10 sales for activity list
      _ds.query(
        FirestorePaths.sales,
        filters: [QueryFilter(field: 'isDeleted', value: false)],
        orderByField: 'timestamp',
        orderByDescending: true,
        limit: 10,
      ),
      // Expenses total
      _ds.query(FirestorePaths.expenses),
      // Active shifts
      _ds.query(
        FirestorePaths.workShifts,
        filters: [QueryFilter(field: 'status', value: 'OPEN')],
      ),
      // Clients count
      _ds.query(
        FirestorePaths.clients,
        filters: [QueryFilter(field: 'isDeleted', value: false)],
      ),
      // Fuel types for labels
      _ds.query(FirestorePaths.gasTypes),
      // Closed shifts in last 7 days (for shift performance)
      _ds.query(
        FirestorePaths.workShifts,
        filters: [
          QueryFilter(field: 'status', value: 'CLOSED'),
          QueryFilter(
            field: 'startTime',
            value: sevenDaysAgo.toIso8601String(),
            operator: FilterOperator.isGreaterThanOrEqualTo,
          ),
        ],
      ),
    ]);

    final allSalesSnap = results[0];
    final trendSalesSnap = results[1];
    final fuelItemsSnap = results[2];
    final pendingPaymentsSnap = results[3];
    final completedPaymentsSnap = results[4];
    final recentSalesSnap = results[5];
    final expensesSnap = results[6];
    final activeShiftsSnap = results[7];
    final clientsSnap = results[8];
    final fuelTypesSnap = results[9];
    final closedShiftsSnap = results[10];

    // Build fuel type name lookup
    final fuelNames = <String, String>{};
    for (final doc in fuelTypesSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      fuelNames[doc.id] = data['name'] as String? ?? doc.id;
    }

    // === Aggregate totals ===
    double totalFuelVolume = 0;
    double totalFuelRevenue = 0;
    int totalProductCount = 0;
    double totalProductRevenue = 0;

    for (final doc in allSalesSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
      totalFuelRevenue += totalAmount * 0.8;
      totalProductRevenue += totalAmount * 0.2;
    }

    // === Daily trend (last 7 days) ===
    final dailyMap = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dailyMap[key] = 0;
    }
    for (final doc in trendSalesSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = DateTime.tryParse(data['timestamp'] as String? ?? '');
      if (ts == null) continue;
      final key =
          '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      if (dailyMap.containsKey(key)) {
        dailyMap[key] =
            (dailyMap[key] ?? 0) + ((data['totalAmount'] as num?)?.toDouble() ?? 0);
      }
    }
    final dailyTrend = dailyMap.entries.map((e) {
      final parts = e.key.split('-');
      final date =
          DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return DailySalePoint(date: date, total: e.value);
    }).toList();

    // === Fuel breakdown ===
    final fuelMap = <String, double>{};
    for (final doc in fuelItemsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final gasTypeId = data['gasTypeId'] as String? ?? 'unknown';
      final volume = (data['volume'] as num?)?.toDouble() ?? 0;
      fuelMap[gasTypeId] = (fuelMap[gasTypeId] ?? 0) + volume;
      totalFuelVolume += volume;
      totalFuelRevenue += (data['lineTotal'] as num?)?.toDouble() ?? 0;
    }
    final fuelBreakdown = fuelMap.entries
        .map((e) => FuelSaleBreakdown(
              label: fuelNames[e.key] ?? e.key,
              volume: e.value,
              revenue: 0,
            ))
        .toList();

    // === Payment method breakdown ===
    final paymentMap = <String, double>{};
    for (final doc in completedPaymentsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final method = data['paymentTypeId'] as String? ?? 'CASH';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      paymentMap[method] = (paymentMap[method] ?? 0) + amount;
    }
    final paymentBreakdown = paymentMap.entries
        .map((e) => PaymentMethodBreakdown(method: e.key, amount: e.value))
        .toList();

    // === Pending payments ===
    double pendingAmount = 0;
    for (final doc in pendingPaymentsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      pendingAmount += (data['amount'] as num?)?.toDouble() ?? 0;
    }

    // === Recent sales ===
    final recentSales = recentSalesSnap.docs
        .map((d) => Sale.fromMap(d.data() as Map<String, dynamic>))
        .toList();

    // === Expenses ===
    double totalExpenses = 0;
    final expenseCategoryMap = <String, double>{};
    for (final doc in expensesSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      totalExpenses += amount;
      final category = data['category'] as String? ?? 'Other';
      expenseCategoryMap[category] =
          (expenseCategoryMap[category] ?? 0) + amount;
    }
    final expenseBreakdown = expenseCategoryMap.entries
        .map((e) => ExpenseCategoryBreakdown(category: e.key, amount: e.value))
        .toList();

    // === Shift performance (last 7 days) ===
    final shiftPerformance = closedShiftsSnap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final startTime = DateTime.tryParse(data['startTime'] as String? ?? '') ?? now;
      return ShiftPerformancePoint(
        date: startTime,
        expectedCash: (data['expectedCash'] as num?)?.toDouble() ?? 0,
        actualCash: (data['actualCash'] as num?)?.toDouble() ?? 0,
        shiftId: doc.id,
      );
    }).toList();

    return DashboardMetrics(
      totalFuelVolume: totalFuelVolume,
      totalFuelRevenue: totalFuelRevenue,
      totalProductCount: totalProductCount,
      totalProductRevenue: totalProductRevenue,
      pendingPaymentsCount: pendingPaymentsSnap.docs.length,
      pendingPaymentsAmount: pendingAmount,
      recentSales: recentSales,
      dailyTrend: dailyTrend,
      fuelBreakdown: fuelBreakdown,
      paymentBreakdown: paymentBreakdown,
      totalExpenses: totalExpenses,
      activeShifts: activeShiftsSnap.docs.length,
      totalClients: clientsSnap.docs.length,
      expenseBreakdown: expenseBreakdown,
      shiftPerformance: shiftPerformance,
    );
  }
}
