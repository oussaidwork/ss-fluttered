import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Overview of station operations',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: [
                  _KpiCard(
                    title: 'Total Fuel Sales',
                    value: '${metrics.totalFuelVolume.toStringAsFixed(1)} L',
                    subtitle: '${metrics.totalFuelRevenue.toStringAsFixed(2)} MAD',
                    icon: Icons.local_gas_station,
                    color: const Color(0xFF0066CC),
                  ),
                  _KpiCard(
                    title: 'Total Product Sales',
                    value: '${metrics.totalProductCount} items',
                    subtitle: '${metrics.totalProductRevenue.toStringAsFixed(2)} MAD',
                    icon: Icons.inventory_2,
                    color: const Color(0xFF84CC16),
                  ),
                  _KpiCard(
                    title: 'Pending Payments',
                    value: '${metrics.pendingPaymentsCount}',
                    subtitle: '${metrics.pendingPaymentsAmount.toStringAsFixed(2)} MAD',
                    icon: Icons.pending_actions,
                    color: Colors.amber,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Recent Activity',
            child: metrics.recentSales.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No recent sales', style: TextStyle(color: Colors.white38)),
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
                              'Sale #${sale.id.substring(0, sale.id.length > 6 ? 6 : sale.id.length).toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${sale.totalAmount.toStringAsFixed(2)} MAD',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Text(
                              '${sale.timestamp.hour}:${sale.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
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
}

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
