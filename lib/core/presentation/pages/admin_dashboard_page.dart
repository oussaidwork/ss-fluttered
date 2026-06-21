import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/dashboard_provider.dart';
import '../../../l10n/app_localizations.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final cs = Theme.of(context).colorScheme;

    return metricsAsync.when(
      data: (metrics) => _buildDashboard(context, metrics),
      loading: () => Center(
        child: CircularProgressIndicator(color: cs.primary),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: cs.onSurface.withValues(alpha: 0.38), size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load dashboard',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardMetrics metrics) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Title Row ===
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboard,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === KPI Cards ===
          _buildKpiRow(cs, metrics, currencyFormat, isWide, l10n),
          const SizedBox(height: 24),

          // === Charts Section ===
          _buildChartsSection(metrics, isWide),
          const SizedBox(height: 24),

          // === Recent Activity ===
          _SectionCard(
            title: l10n.recentActivity,
            child: metrics.recentSales.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        l10n.noRecentSales,
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
                      ),
                    ),
                  )
                : Column(
                    children: metrics.recentSales
                        .map(
                          (sale) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primary.withAlpha(30),
                              child: Icon(
                                Icons.receipt_long,
                                color: cs.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Sale #${sale.id.isNotEmpty ? sale.id.substring(0, min(6, sale.id.length)).toUpperCase() : 'N/A'}',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${sale.totalPrice.toStringAsFixed(2)} MAD',
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                            ),
                            trailing: Text(
                              '${sale.timestamp.hour.toString().padLeft(2, '0')}:${sale.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.38),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
      ColorScheme cs, DashboardMetrics metrics, NumberFormat fmt, bool isWide, AppLocalizations l10n) {
    final crossCount = isWide ? 3 : 2;

    return GridView.count(
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _KpiCard(
          title: l10n.fuelSales,
          value: '${metrics.totalFuelVolume.toStringAsFixed(1)} L',
          subtitle: '${fmt.format(metrics.totalFuelRevenue)} MAD',
          icon: Icons.local_gas_station,
          color: cs.primary,
        ),
        _KpiCard(
          title: l10n.productSales,
          value: '${metrics.totalProductCount} items',
          subtitle: '${fmt.format(metrics.totalProductRevenue)} MAD',
          icon: Icons.inventory_2,
          color: cs.secondary,
        ),
        _KpiCard(
          title: l10n.totalExpenses,
          value: fmt.format(metrics.totalExpenses),
          subtitle: 'MAD',
          icon: Icons.money_off,
          color: cs.error,
        ),
        _KpiCard(
          title: l10n.activeShifts,
          value: '${metrics.activeShifts}',
          subtitle: metrics.activeShifts == 1 ? 'shift open' : 'shifts open',
          icon: Icons.work_history,
          color: cs.tertiary,
        ),
        _KpiCard(
          title: l10n.pendingPayments,
          value: '${metrics.pendingPaymentsCount}',
          subtitle: '${fmt.format(metrics.pendingPaymentsAmount)} MAD',
          icon: Icons.pending_actions,
          color: cs.tertiary,
        ),
        _KpiCard(
          title: l10n.totalClients,
          value: '${metrics.totalClients}',
          subtitle: 'registered',
          icon: Icons.people,
          color: cs.secondaryContainer,
        ),
      ],
    );
  }

  Widget _buildChartsSection(DashboardMetrics metrics, bool isWide) {
    return Column(
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SalesTrendChart(dailyTrend: metrics.dailyTrend)),
              const SizedBox(width: 16),
              Expanded(child: _FuelMixChart(fuelBreakdown: metrics.fuelBreakdown)),
            ],
          )
        else ...[
          _SalesTrendChart(dailyTrend: metrics.dailyTrend),
          const SizedBox(height: 16),
          _FuelMixChart(fuelBreakdown: metrics.fuelBreakdown),
        ],
        const SizedBox(height: 16),
        _PaymentMethodsChart(paymentBreakdown: metrics.paymentBreakdown),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _ShiftPerformanceChart(
                      shiftPerformance: metrics.shiftPerformance)),
              const SizedBox(width: 16),
              Expanded(
                  child: _ExpenseBreakdownChart(
                      expenseBreakdown: metrics.expenseBreakdown)),
            ],
          )
        else ...[
          _ShiftPerformanceChart(shiftPerformance: metrics.shiftPerformance),
          const SizedBox(height: 16),
          _ExpenseBreakdownChart(expenseBreakdown: metrics.expenseBreakdown),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// KPI Card
// ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Sales Trend (Line Chart)
// ────────────────────────────────────────────────────────────────

class _SalesTrendChart extends StatelessWidget {
  final List<DailySalePoint> dailyTrend;

  const _SalesTrendChart({required this.dailyTrend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (dailyTrend.isEmpty) {
      return _EmptyChartCard(title: AppLocalizations.of(context)!.salesTrend);
    }

    final maxVal = dailyTrend.map((p) => p.total).reduce(max).ceilToDouble();
    final safeMax = maxVal < 1 ? 100.0 : maxVal * 1.2;

    final spots = dailyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.total);
    }).toList();

    final dayLabels = dailyTrend
        .map((p) => DateFormat('MM/dd').format(p.date))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.salesTrend,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.onSurface.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dayLabels[idx],
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.38),
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: safeMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: cs.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: cs.primary,
                        strokeWidth: 2,
                        strokeColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: cs.primary.withAlpha(40),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Fuel Mix (Pie Chart)
// ────────────────────────────────────────────────────────────────

class _FuelMixChart extends StatelessWidget {
  final List<FuelSaleBreakdown> fuelBreakdown;

  const _FuelMixChart({required this.fuelBreakdown});

  static List<Color> _chartColors(ColorScheme cs) => [
    cs.primary,
    cs.secondary,
    cs.tertiary,
    cs.error,
    cs.secondaryContainer,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fuelMixLabel = AppLocalizations.of(context)!.fuelMix;
    if (fuelBreakdown.isEmpty) {
      return _EmptyChartCard(title: fuelMixLabel);
    }

    final totalVol = fuelBreakdown.fold<double>(0, (s, e) => s + e.volume);
    if (totalVol <= 0) {
      return _EmptyChartCard(title: fuelMixLabel);
    }

    final sections = fuelBreakdown.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      final pct = (item.volume / totalVol * 100);
      return PieChartSectionData(
        value: item.volume,
        title: '${pct.toStringAsFixed(0)}%',
        color: _chartColors(cs)[idx % _chartColors(cs).length],
        radius: 60,
        titleStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.fuelMix,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fuelBreakdown.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _chartColors(cs)[idx % _chartColors(cs).length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.label} (${item.volume.toStringAsFixed(0)}L)',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Payment Methods (Bar Chart)
// ────────────────────────────────────────────────────────────────

class _PaymentMethodsChart extends StatelessWidget {
  final List<PaymentMethodBreakdown> paymentBreakdown;

  const _PaymentMethodsChart({required this.paymentBreakdown});

  static List<Color> _barColors(ColorScheme cs) => [
    cs.secondary,
    cs.primary,
    cs.tertiary,
    cs.secondaryContainer,
    cs.error,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paymentLabel = AppLocalizations.of(context)!.paymentMethods;
    if (paymentBreakdown.isEmpty) {
      return _EmptyChartCard(title: paymentLabel);
    }

    final maxVal = paymentBreakdown
        .map((e) => e.amount)
        .reduce(max)
        .ceilToDouble();
    final safeMax = maxVal < 1 ? 100.0 : maxVal * 1.3;
    final totalAmt = paymentBreakdown.fold<double>(0, (s, e) => s + e.amount);

    final groups = paymentBreakdown.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: item.amount,
            color: _barColors(cs)[idx % _barColors(cs).length],
            width: 28,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.paymentMethods,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,##0.00').format(totalAmt)} MAD total',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.onSurface.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= paymentBreakdown.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            paymentBreakdown[idx].method,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.54),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: safeMax,
                barGroups: groups,
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Shift Performance (Grouped Bar Chart)
// ────────────────────────────────────────────────────────────────

class _ShiftPerformanceChart extends StatelessWidget {
  final List<ShiftPerformancePoint> shiftPerformance;

  const _ShiftPerformanceChart({required this.shiftPerformance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shiftPerfLabel = AppLocalizations.of(context)!.shiftPerformance;
    if (shiftPerformance.isEmpty) {
      return _EmptyChartCard(title: shiftPerfLabel);
    }

    final maxVal = shiftPerformance.fold<double>(
      0,
      (s, e) => [s, e.expectedCash, e.actualCash].reduce(max),
    );
    final safeMax = maxVal < 1 ? 100.0 : maxVal * 1.3;

    // Build grouped bars (expected vs actual per shift)
    final groups = shiftPerformance.asMap().entries.map((entry) {
      final idx = entry.key;
      final sp = entry.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: sp.expectedCash,
            color: cs.primary,
            width: 10,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
          BarChartRodData(
            toY: sp.actualCash,
            color: sp.actualCash >= sp.expectedCash
                ? cs.secondary
                : cs.error,
            width: 10,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.shiftPerformance,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(cs.primary, AppLocalizations.of(context)!.expected, cs),
              const SizedBox(width: 16),
              _legendDot(cs.secondary, AppLocalizations.of(context)!.actual, cs),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.onSurface.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= shiftPerformance.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MM/dd').format(shiftPerformance[idx].date),
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.38),
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: safeMax,
                barGroups: groups,
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Expense Breakdown (Horizontal Bar Chart)
// ────────────────────────────────────────────────────────────────

class _ExpenseBreakdownChart extends StatelessWidget {
  final List<ExpenseCategoryBreakdown> expenseBreakdown;

  const _ExpenseBreakdownChart({required this.expenseBreakdown});

  static List<Color> _chartColors(ColorScheme cs) => [
    cs.error,
    cs.tertiary,
    cs.secondaryContainer,
    cs.primaryContainer,
    cs.secondary,
    const Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expenseLabel = AppLocalizations.of(context)!.expenseBreakdown;
    if (expenseBreakdown.isEmpty) {
      return _EmptyChartCard(title: expenseLabel);
    }

    final totalAmt = expenseBreakdown.fold<double>(0, (s, e) => s + e.amount);
    if (totalAmt <= 0) {
      return _EmptyChartCard(title: expenseLabel);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.expenseBreakdown,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,##0.00').format(totalAmt)} MAD total',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...expenseBreakdown.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final pct = item.amount / totalAmt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.category,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0.00').format(item.amount)} MAD',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _chartColors(cs)[idx % _chartColors(cs).length],
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Empty chart placeholder
// ────────────────────────────────────────────────────────────────

class _EmptyChartCard extends StatelessWidget {
  final String title;
  const _EmptyChartCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.bar_chart, color: cs.onSurface.withValues(alpha: 0.24), size: 40),
          const SizedBox(height: 8),
          Text(
            'No data available yet',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Section Card (shared with dashboard)
// ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
