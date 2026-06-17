import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Reports Hub',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildReportCard(
                  context,
                  icon: Icons.speed,
                  title: 'Pump Indexes',
                  description: 'Current and historical pump readings for all nozzles',
                  color: const Color(0xFF0066CC),
                  onTap: () => _generateReport(context, 'Pump Indexes', 'pump_indexes'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.local_gas_station,
                  title: 'Sales Report',
                  description: 'Detailed breakdown of all sales by period and type',
                  color: const Color(0xFF84CC16),
                  onTap: () => _generateReport(context, 'Sales Report', 'sales'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.money_off,
                  title: 'Debts Report',
                  description: 'Outstanding debts by client with due dates',
                  color: const Color(0xFFEF4444),
                  onTap: () => _generateReport(context, 'Debts Report', 'debts'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.payments,
                  title: 'Payments Settlement',
                  description: 'Payment history and settlement status by client',
                  color: const Color(0xFF84CC16),
                  onTap: () => _generateReport(context, 'Payments Settlement', 'payments'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.local_shipping,
                  title: 'Pit Refill',
                  description: 'Fuel tank refill history and volume tracking',
                  color: const Color(0xFF06B6D4),
                  onTap: () => _generateReport(context, 'Pit Refill', 'pit_refill'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.trending_up,
                  title: 'Fuel Price History',
                  description: 'Price changes over time for all fuel types',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _generateReport(context, 'Fuel Price History', 'fuel_prices'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.security,
                  title: 'Audit Log',
                  description: 'System activity log with user actions and timestamps',
                  color: Colors.white54,
                  onTap: () => _generateReport(context, 'Audit Log', 'log_entries'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.schedule,
                  title: 'Shift Summary',
                  description: 'Per-shift performance with sales and cash reconciliation',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _generateReport(context, 'Shift Summary', 'work_shifts'),
                ),
                _buildReportCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Statistics',
                  description: 'Aggregate metrics: daily averages, trends, and comparisons',
                  color: const Color(0xFF0066CC),
                  onTap: () => _showStatisticsDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateReport(BuildContext context, String title, String collection) {
    showDialog(
      context: context,
      builder: (ctx) => _ReportPreviewDialog(title: title, collection: collection),
    );
  }

  void _showStatisticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _StatisticsDialog(),
    );
  }
}

class _ReportPreviewDialog extends StatelessWidget {
  final String title;
  final String collection;
  const _ReportPreviewDialog({required this.title, required this.collection});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.assessment, color: Color(0xFF0066CC), size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection(collection).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 48, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(
                      'No data available for $title',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            }
            final docs = snapshot.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${docs.length} records found',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download, size: 16, color: Color(0xFF0066CC)),
                        label: const Text('Export', style: TextStyle(color: Color(0xFF0066CC))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, idx) {
                      final data = docs[idx].data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.entries.map((e) => '${e.key}: ${e.value ?? "--"}').join('  |  '),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}

class _StatisticsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.analytics, color: Color(0xFF0066CC), size: 22),
          const SizedBox(width: 8),
          const Text('Statistics Overview', style: TextStyle(color: Colors.white)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('sales').where('isDeleted', isEqualTo: false).snapshots(),
                builder: (ctx, salesSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('clients').where('isDeleted', isEqualTo: false).snapshots(),
                    builder: (ctx, clientsSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: firestore.collection('work_shifts').snapshots(),
                        builder: (ctx, shiftsSnap) {
                          final salesCount = salesSnap.data?.docs.length ?? 0;
                          final clientsCount = clientsSnap.data?.docs.length ?? 0;
                          final shiftsCount = shiftsSnap.data?.docs.length ?? 0;
                          double totalRevenue = 0;
                          if (salesSnap.hasData) {
                            for (final doc in salesSnap.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0;
                            }
                          }
                          return Column(
                            children: [
                              _statTile('Total Sales', '$salesCount', const Color(0xFF0066CC)),
                              const SizedBox(height: 8),
                              _statTile('Total Revenue', '${totalRevenue.toStringAsFixed(2)} DA', const Color(0xFF84CC16)),
                              const SizedBox(height: 8),
                              _statTile('Clients', '$clientsCount', const Color(0xFFF59E0B)),
                              const SizedBox(height: 8),
                              _statTile('Shifts Completed', '$shiftsCount', const Color(0xFF8B5CF6)),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
