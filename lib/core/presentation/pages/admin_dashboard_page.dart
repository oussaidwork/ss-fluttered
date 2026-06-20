import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => _buildDashboard(context, metrics),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0066CC)),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Could not load dashboard',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardMetrics metrics) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

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
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === KPI Cards ===
          _buildKpiRow(metrics, currencyFormat, isWide),
          const SizedBox(height: 24),

          // === Charts Section ===
          _buildChartsSection(metrics, isWide),
          const SizedBox(height: 24),

          // === Recent Activity ===
          _SectionCard(
            title: 'Recent Activity',
            child: metrics.recentSales.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No recent sales',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  )
                : Column(
                    children: metrics.recentSales
                        .map(
                          (sale) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0066CC).withAlpha(30),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Color(0xFF0066CC),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Sale #${sale.id.isNotEmpty ? sale.id.substring(0, min(6, sale.id.length)).toUpperCase() : 'N/A'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${sale.totalPrice.toStringAsFixed(2)} MAD',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Text(
                              '${sale.timestamp.hour.toString().padLeft(2, '0')}:${sale.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white38,
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
      DashboardMetrics metrics, NumberFormat fmt, bool isWide) {
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
          title: 'Fuel Sales',
          value: '${metrics.totalFuelVolume.toStringAsFixed(1)} L',
          subtitle: '${fmt.format(metrics.totalFuelRevenue)} MAD',
          icon: Icons.local_gas_station,
          color: const Color(0xFF0066CC),
        ),
        _KpiCard(
          title: 'Product Sales',
          value: '${metrics.totalProductCount} items',
          subtitle: '${fmt.format(metrics.totalProductRevenue)} MAD',
          icon: Icons.inventory_2,
          color: const Color(0xFF84CC16),
        ),
        _KpiCard(
          title: 'Total Expenses',
          value: fmt.format(metrics.totalExpenses),
          subtitle: 'MAD',
          icon: Icons.money_off,
          color: Colors.redAccent,
        ),
        _KpiCard(
          title: 'Active Shifts',
          value: '${metrics.activeShifts}',
          subtitle: metrics.activeShifts == 1 ? 'shift open' : 'shifts open',
          icon: Icons.work_history,
          color: Colors.teal,
        ),
        _KpiCard(
          title: 'Pending Payments',
          value: '${metrics.pendingPaymentsCount}',
          subtitle: '${fmt.format(metrics.pendingPaymentsAmount)} MAD',
          icon: Icons.pending_actions,
          color: Colors.amber,
        ),
        _KpiCard(
          title: 'Total Clients',
          value: '${metrics.totalClients}',
          subtitle: 'registered',
          icon: Icons.people,
          color: Colors.purpleAccent,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
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
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
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
    if (dailyTrend.isEmpty) {
      return const _EmptyChartCard(title: 'Sales Trend (7 days)');
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
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend (7 days)',
            style: TextStyle(
              color: Colors.white,
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
                    color: Colors.white10,
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
                        style: const TextStyle(
                          color: Colors.white38,
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
                            style: const TextStyle(
                              color: Colors.white38,
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
                    color: const Color(0xFF0066CC),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF0066CC),
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF1A2332),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0066CC).withAlpha(40),
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

  static const _chartColors = [
    Color(0xFF0066CC),
    Color(0xFF84CC16),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    if (fuelBreakdown.isEmpty) {
      return const _EmptyChartCard(title: 'Fuel Mix');
    }

    final totalVol = fuelBreakdown.fold<double>(0, (s, e) => s + e.volume);
    if (totalVol <= 0) {
      return const _EmptyChartCard(title: 'Fuel Mix');
    }

    final sections = fuelBreakdown.asMap().entries.map((e) {
      final idx = e.key;
      final item = e.value;
      final pct = (item.volume / totalVol * 100);
      return PieChartSectionData(
        value: item.volume,
        title: '${pct.toStringAsFixed(0)}%',
        color: _chartColors[idx % _chartColors.length],
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuel Mix (Today)',
            style: TextStyle(
              color: Colors.white,
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
                              color: _chartColors[idx % _chartColors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.label} (${item.volume.toStringAsFixed(0)}L)',
                            style: const TextStyle(
                              color: Colors.white70,
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

  static const _barColors = [
    Color(0xFF84CC16),
    Color(0xFF0066CC),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    if (paymentBreakdown.isEmpty) {
      return const _EmptyChartCard(title: 'Payment Methods');
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
            color: _barColors[idx % _barColors.length],
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
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,##0.00').format(totalAmt)} MAD total',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                    color: Colors.white10,
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
                        style: const TextStyle(
                          color: Colors.white38,
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
                            style: const TextStyle(
                              color: Colors.white54,
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
// Empty chart placeholder
// ────────────────────────────────────────────────────────────────

class _EmptyChartCard extends StatelessWidget {
  final String title;
  const _EmptyChartCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.bar_chart, color: Colors.white24, size: 40),
          const SizedBox(height: 8),
          const Text(
            'No data available yet',
            style: TextStyle(color: Colors.white38, fontSize: 12),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
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
